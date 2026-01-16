`timescale 1ns / 1ps

module AoC2025Day1#(
    parameter MAX_DECIMAL_IN = 4,
    parameter MAX_DECIMAL_SUMMED = 5
)(
    input[7:0] charIn,
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
    
    //assuming only 'R', 'L', '0' to '9', '\r' and '\n' are sent to make these checks depend on fewer bits
    wire charLetter = charIn[6];//only 'R' or 'L' matter here
    wire charR = charIn[6] == 1'b1 && charIn[4] == 1'b1;//'R' 8'b01010010
    wire charL = charIn[6] == 1'b1 && charIn[3] == 1'b1;//'L' 8'b01001100
    wire charIsNum = charIn[5] == 1'b1;//'0' to '9', upper four bits are 4'b0011
    wire[3:0] charNum = charIn[3:0];//the lower four bits are just the digit
    wire charNewline = charIn[6:5] == 2'b00; //'\n' 8'b00001010 or '\r' 8'b00001101
    
    reg[MAX_DECIMAL_IN * 4 - 1:0] bcdShiftIn = 0;
    reg[MAX_DECIMAL_IN * 4 - 1:0] bcdFullStored = 0;
    reg takeTensComplement = 0;
    reg takeTensComplementStored = 0;
    
    reg[1:0] multiCyclePathTimer = 0;
    
    reg[2 * 4 - 1:0] bcdPos = 8'h50;
    
    reg[MAX_DECIMAL_SUMMED * 4 - 1:0] landedOnZero = 0;
    reg[MAX_DECIMAL_SUMMED * 4 - 1:0] passedZero = 0;
    
    reg inputCompleted = 0;
    
    always @ (posedge clk) begin
        if(rst) begin
            bcdShiftIn <= 0;
            bcdFullStored <= 0;
            takeTensComplement <= 0;
            takeTensComplementStored <= 0;
            
            multiCyclePathTimer <= 0;
            
            bcdPos <= 8'h50;
            
            landedOnZero <= 0;
            passedZero <= 0;
            
            inputCompleted <= 0;
        end
        else begin
            if(charInValid && !inputCompleted) begin
                if(charLetter) begin
                    bcdShiftIn <= 0;
                    takeTensComplement <= charL;
                end
                if(charIsNum) begin
                    bcdShiftIn <= {bcdShiftIn[(MAX_DECIMAL_IN - 1) * 4 - 1:0], charNum};
                end
                if(charNewline) begin
                    bcdFullStored[MAX_DECIMAL_IN * 4 - 1:8] <= bcdShiftIn[MAX_DECIMAL_IN * 4 - 1:8];
                    bcdFullStored[7:4] <= takeTensComplement ? 4'd9 - bcdShiftIn[7:4] : bcdShiftIn[7:4];//only take nine's complement here,
                    bcdFullStored[3:0] <= takeTensComplement ? 4'd9 - bcdShiftIn[3:0] : bcdShiftIn[3:0];//add one later to get to the ten's complement
                    takeTensComplementStored <= takeTensComplement;
                    multiCyclePathTimer <= 3;
                end
            end
            if(stop) begin
                inputCompleted <= 1;
            end
        end
    end
    
    wire[7:0] lowerAdderOut;
    wire lowerCarryOut;
    BCDAdder#(.DIGITS_A(2), .DIGITS_B(2)) lowerAdder(
        .carryIn(takeTensComplementStored),//add one to get from the nine's complement to the ten's complement when turning left
        .inA(bcdPos),
        .inB(bcdFullStored[7:0]),
        .out(lowerAdderOut),
        .carryOut(lowerCarryOut)
    );
    
    wire lowerPrevNotZero = (bcdPos != 8'b0);
    wire lowerIsZero = (lowerAdderOut[7:0] == 8'b0);
    wire lowerChangedHundreths = lowerCarryOut ^ takeTensComplementStored;//subtract 100 when turning left after adding the ten's complement
    wire lowerPassedOrLanded = lowerPrevNotZero && (lowerIsZero || lowerChangedHundreths);
    
    wire[MAX_DECIMAL_SUMMED * 4 - 1:0] landedOnZeroAdderOut;
    BCDAdder#(.DIGITS_A(MAX_DECIMAL_SUMMED), .DIGITS_B(1)) landedOnZeroAdder(
        .carryIn(1'b0),
        .inA(landedOnZero),
        .inB({3'b0, lowerIsZero}),
        .out(landedOnZeroAdderOut),
        .carryOut()
    );
    
    wire[MAX_DECIMAL_SUMMED * 4 - 1:0] passedZeroAdderOut;
    BCDAdder#(.DIGITS_A(MAX_DECIMAL_SUMMED), .DIGITS_B(MAX_DECIMAL_IN - 2)) passedZeroAdder(
        .carryIn(lowerPassedOrLanded),
        .inA(passedZero),
        .inB(bcdFullStored[MAX_DECIMAL_IN * 4 - 1:8]),
        .out(passedZeroAdderOut),
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
                bcdPos <= lowerAdderOut;//constrain as multi cycle path of length 3
                landedOnZero <= landedOnZeroAdderOut;//constrain as multi cycle path of length 3
                passedZero <= passedZeroAdderOut;//constrain as multi cycle path of length 3
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
    NumberShifter#(.DIGITS(MAX_DECIMAL_SUMMED)) landedOnZeroShifterOut(
        .bcdIn(landedOnZero),
        .start(!shiftingOut && readyToShift),
        .clk(clk),
        .rst(rst),
        .charOut(partOneCharOut),
        .charOutValid(partOneCharOutValid),
        .done(partOneShifterDone)
    );
    
    wire partTwoShifterDone;
    NumberShifter#(.DIGITS(MAX_DECIMAL_SUMMED)) passedZeroShifterOut(
        .bcdIn(passedZero),
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
