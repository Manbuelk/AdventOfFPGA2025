#Advent of FPGA 2025 Day 1

I decided to do the entirety of this day in BCD as this means that both division by 100 and modulo 100 are free operations.
For every rotation, the number is split into two parts, the lower two digits(referred to as the lower part) and all others(referred to as the upper part). The upper part can instantly be added to both the part one sum and the part two sum as moving the dial by a multiple of 100 always means that you pass 0 that many times and land on 0 that many times.
For the lower part, when going right I just add it to the previous dial position, when going left I first take the nine's complement(99 - the number), then later add one to get to the ten's complement(100 - the number) after which I xor the carry out bit with 1 to subtract 100 again(which leaves us with just (- the number)).
For part one I then check whether the lower two digits are 0, if so I add 1 to the sum.
For part two I add one to the sum if the previous dial location was not 0 and the new dial position is either 0 or has under-/overflowed, depending on  whether it is a right or left rotation.
Since there are at least 3 cycles between one newline character and the next(\n, R or L and at least one digit), the BCD adders have been designed to be constrained as multi cycle paths with a cycle length of 3.
The module has two parameters, MAX_DECIMAL_IN, which is the maximum amount of digits in line after the L or R, and MAX_DECIMAL_SUMMED, which is the maximum amount of digits of the results.
