`timescale 1ns / 1ps

module AoC2025Day3#(
    parameter MAX_DECIMAL_SUMMED_PART_ONE = 5,
    parameter MAX_DECIMAL_SUMMED_PART_TWO = 15
)(
    input [7:0] charIn,
    input charInValid,
    input stop,
    input rst,
    input clk,
    
    output[7:0] partOneCharOut,
    output partOneCharOutValid,
    output partOneDone,
    output[7:0] partTwoCharOut,
    output partTwoCharOutValid,
    output partTwoDone
);
    
    //assuming only '0' to '9', '\r' and '\n' are sent to make these checks depend on fewer bits
    wire charIsNum = charIn[5] == 1'b1;//'0' to '9', upper four bits are 4'b0011
    wire[3:0] charNum = charIn[3:0];//the lower four bits are just the digit
    wire charNewline = charIn[6:5] == 2'b00; //'\n' 8'b00001010 or '\r' 8'b00001101
    
    reg[2 * 4 - 1:0] partOneShift = 0;
    reg[12 * 4 - 1:0] partTwoShift = 0;
    wire[2 * 4 - 1:0] partOneCompare = {partOneShift[1 * 4 - 1:0], charNum};
    wire[12 * 4 - 1:0] partTwoCompare = {partTwoShift[11 * 4 - 1:0], charNum};
    
    reg[2 * 4 - 1:0] partOneStored = 0;
    reg[12 * 4 - 1:0] partTwoStored = 0;
    
    reg[MAX_DECIMAL_SUMMED_PART_ONE * 4 - 1:0] partOneSummed = 0;
    reg[MAX_DECIMAL_SUMMED_PART_TWO * 4 - 1:0] partTwoSummed = 0;
    
    reg[1:0] multiCyclePathTimer = 0;
    
    reg inputCompleted = 0;
    
    integer i;
    integer j;
    always @(posedge clk) begin
        if(rst) begin
            partOneShift <= 0;
            partTwoShift <= 0;
            partOneStored <= 0;
            partTwoStored <= 0;
            
            partOneSummed <= 0;
            partTwoSummed <= 0;
            
            multiCyclePathTimer <= 0;
            
            inputCompleted <= 0;
        end
        else begin
            if(charInValid && !inputCompleted) begin
                if(charIsNum) begin
                    for(i = 0; i < 2; i = i + 1) begin
                        /*if(partOneShift[i * 4 - 1-:4] < partOneCompare[i * 4 - 1-:4]) begin
                            partOneShift[i * 4 - 1-:0] <= partOneCompare[i * 4 - 1-:0];
                        end*/
                        for(j = i; j < 2; j = j + 1) begin
                            if(partOneShift[(j + 1) * 4 - 1-:4] < partOneCompare[(j + 1) * 4 - 1-:4]) begin
                                partOneShift[(i + 1) * 4 - 1-:4] <= partOneCompare[(i + 1) * 4 - 1-:4];
                            end
                        end
                    end
                    for(i = 0; i < 12; i = i + 1) begin
                        /*if(partTwoShift[i * 4 - 1-:4] < partTwoCompare[i * 4 - 1-:4]) begin
                            partTwoShift[i * 4 - 1-:0] <= partTwoCompare[i * 4 - 1-:0];
                        end*/
                        for(j = i; j < 12; j = j + 1) begin
                            if(partTwoShift[(j + 1) * 4 - 1-:4] < partTwoCompare[(j + 1) * 4 - 1-:4]) begin
                                partTwoShift[(i + 1) * 4 - 1-:4] <= partTwoCompare[(i + 1) * 4 - 1-:4];
                            end
                        end
                    end
                end
                if(charNewline) begin
                    partOneShift <= 0;
                    partTwoShift <= 0;
                    partOneStored <= partOneShift;
                    partTwoStored <= partTwoShift;
                    multiCyclePathTimer <= 2;
                end
            end
            if(stop) begin
                inputCompleted <= 1;
            end
        end
    end
    
    wire[MAX_DECIMAL_SUMMED_PART_ONE * 4 - 1:0] partOneAdderOut;
    BCDAdder#(.DIGITS_A(2), .DIGITS_B(5)) partOneAdder(
        .carryIn(1'b0),
        .inA(partOneStored),
        .inB(partOneSummed),
        .out(partOneAdderOut),
        .carryOut()
    );
    
    wire[MAX_DECIMAL_SUMMED_PART_TWO * 4 - 1:0] partTwoAdderOut;
    BCDAdder#(.DIGITS_A(12), .DIGITS_B(15)) partTwoAdder(
        .carryIn(1'b0),
        .inA(partTwoStored),
        .inB(partTwoSummed),
        .out(partTwoAdderOut),
        .carryOut()
    );
    
    always @ (posedge clk) begin
        if(!rst) begin
            if(!(charInValid && charNewline)) begin
                if(multiCyclePathTimer != 0) begin
                    multiCyclePathTimer <= multiCyclePathTimer - 1;
                end
            end
            if(multiCyclePathTimer == 1) begin
                partOneSummed <= partOneAdderOut;//constrain as multi cycle path of length 2
                partTwoSummed <= partTwoAdderOut;//constrain as multi cycle path of length 2
            end
        end
    end
    
    reg shiftingOut = 0;
    wire readyToShift = inputCompleted && multiCyclePathTimer == 0;
    
    always @ (posedge clk) begin
        if(rst) begin
            shiftingOut <= 0;
        end
        else begin
            shiftingOut <= readyToShift;
        end
    end
    
    wire partOneShifterDone;
    NumberShifter#(.DIGITS(MAX_DECIMAL_SUMMED_PART_ONE)) partOneShifter(
        .bcdIn(partOneSummed),
        .start(!shiftingOut && readyToShift),
        .clk(clk),
        .rst(rst),
        .charOut(partOneCharOut),
        .charOutValid(partOneCharOutValid),
        .done(partOneShifterDone)
    );
    
    wire partTwoShifterDone;
    NumberShifter#(.DIGITS(MAX_DECIMAL_SUMMED_PART_TWO)) partTwoShifter(
        .bcdIn(partTwoSummed),
        .start(!shiftingOut && readyToShift),
        .clk(clk),
        .rst(rst),
        .charOut(partTwoCharOut),
        .charOutValid(partTwoCharOutValid),
        .done(partTwoShifterDone)
    );
    
    assign partOneDone = partOneShifterDone && shiftingOut;
    assign partTwoDone = partTwoShifterDone && shiftingOut;
    
endmodule
