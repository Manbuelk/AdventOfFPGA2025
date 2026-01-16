# Advent of FPGA 2025
This repository contains verilog implementations of Advent of Code 2025 days 1, 3 and 7.\
Each subfolder for a day contains the module that solves the puzzle, as well as a testbench for the module, another module that reads an input from a file and prints the solution and a README file explaining my approach.

## Module I/O
Each of the days has the same inputs and outputs:\
Whenever "charInValid" is 1 on a positive edge of "clk", an ASCII character is read into the module through the 8 bit input "charIn". Once the full input has been submitted, "stop" should be set to 1.\
Once the output is ready, a null terminated string is output one ASCII character at a time. Part one and part two each have a separate "charOut", a "charOutValid" and a "done" output that work just like the input does.\
To start a new computation for a new input the module should be reset using the "rst" input.

## Running the testbenches and solving inputs
For my actual local testbenches I have used my personal Advent of Code inputs and solutions. As I am not supposed to upload those I have instead replaced them with the (much smaller) test inputs from the problem descriptions.\
Even though I have only tested using Vivado's inbuilt simulator, any simulator capable of simulating SystemVerilog should be able to run the testbenches and input parsing modules.\
When running those in a simulator make sure that the working directory of the simulator is the folder containing the modules and input/testinput as the testbench and input parsing module use relative paths.\
To solve inputs replace the input.txt file in the folder of the day with your input, then run SolveInput.sv using a simulator of your choice. The solution should be printed in the output of your simulator.

## Final notes
Even though I am quite happy with my approaches, I am not too happy with my actual implementations as I am still quite inexperienced with both Verilog and FPGAs in general.


