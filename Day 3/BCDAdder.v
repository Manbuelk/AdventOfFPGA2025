`timescale 1ns / 1ps

module BCDFullAdder(
        input carryIn,
        input[3:0] inA,
        input[3:0] inB,
        output[3:0] out,
        output carryOut
    );
    
    wire[4:0] sum = inA + inB + carryIn;
    wire[4:0] corrected = sum > 9 ? sum + 6 : sum;
    assign out = corrected[3:0];
    assign carryOut = corrected[4];
endmodule

module BCDAdder#(
    parameter DIGITS_A = 1,
    parameter DIGITS_B = 1
    )(
    input carryIn,
    input[DIGITS_A * 4 - 1:0] inA,
    input[DIGITS_B * 4 - 1:0] inB,
    output[(DIGITS_A > DIGITS_B ? DIGITS_A : DIGITS_B) * 4 - 1:0] out,
    output carryOut
    );
    
    genvar i;
    
    wire[(DIGITS_A > DIGITS_B ? DIGITS_A : DIGITS_B):0] carryInVec;
    assign carryInVec[0] = carryIn;
    assign carryOut = carryInVec[(DIGITS_A > DIGITS_B ? DIGITS_A : DIGITS_B)];
    
    generate
        for(i = 0; i < (DIGITS_A > DIGITS_B ? DIGITS_A : DIGITS_B); i = i + 1) begin
            BCDFullAdder fa(
                .carryIn(carryInVec[i]),
                .inA(i < DIGITS_A ? inA[(i + 1) * 4 - 1-:4] : 4'b0),
                .inB(i < DIGITS_B ? inB[(i + 1) * 4 - 1-:4] : 4'b0),
                .out(out[(i + 1) * 4 - 1-:4]),
                .carryOut(carryInVec[i + 1])
            );              
        end
    endgenerate
endmodule
