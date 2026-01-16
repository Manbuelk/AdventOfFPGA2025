`timescale 1ns / 1ps

module AoC2025Day7#(
    parameter MAX_WIDTH = 512,
    parameter MAX_OUTPUT = 64,
    parameter BCD_CONVERSION_MULTICYCLE_LENGTH = 7
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
    
    //assuming only '.', 'S', '^', '\r' and '\n' are sent to make these checks depend on fewer bits
    wire charEmpty = charIn[5] == 1'b1; //'.' 8'b00101110
    wire charStart = charIn[3] == 1'b0; //'S' 8'b01010011
    wire charSplit = charIn[4:3] == 2'b11; //'^' 8'b01011110
    wire charNewline = charIn[6:5] == 2'b00; //'\n' 8'b00001010 or '\r' 8'b00001101
    
    reg[MAX_OUTPUT - 1:0] columnPaths[MAX_WIDTH - 1:0];
    reg[$clog2(MAX_WIDTH) - 1:0] rightAddr = 0;
    reg[$clog2(MAX_WIDTH) - 1:0] middleAddr = 0;
    reg[$clog2(MAX_WIDTH) - 1:0] leftAddr = 0;
    reg rightAddrValid = 0;
    reg middleAddrValid = 0;
    reg leftAddrValid = 0;
    reg addValid = 0;
    
    reg firstLine = 1;//used to initialize the ram instead of reading from it
    reg[MAX_OUTPUT - 1:0] leftVal = 0;
    reg[MAX_OUTPUT - 1:0] middleVal = 0;
    reg[MAX_OUTPUT - 1:0] rightVal = 0;
    reg[MAX_OUTPUT - 1:0] prevMiddleVal = 0;
    
    reg[MAX_OUTPUT - 1:0] splits = 0;
    reg[MAX_OUTPUT - 1:0] lineAdded = 0;
    reg resetAdder = 1;
    
    reg[7:0] rightChar = ".";
    wire rightCharStart = rightChar[3] == 1'b0; //'S' 8'b01010011, more explanation above, at charStart
    reg[7:0] middleChar = ".";
    wire middleCharSplit = middleChar[4:3] == 2'b11; //'^' 8'b01011110, more explanation above, at charSplit
    
    reg newLine = 1;
    
    reg inputCompleted = 0;
    reg[2:0] pipelineFlushCounter = 0;
    
    always @ (posedge clk) begin
        if(rst) begin
            rightAddr <= 0;
            middleAddr <= 0;
            leftAddr <= 0;
            rightAddrValid <= 0;
            middleAddrValid <= 0;
            leftAddrValid <= 0;
            addValid <= 0;
            
            firstLine <= 1;
            leftVal <= 0;
            middleVal <= 0;
            rightVal <= 0;
            prevMiddleVal <= 0;
            
            splits <= 0;
            lineAdded <= 0;
            resetAdder <= 1;
            
            rightChar <= ".";
            middleChar <= ".";
            
            newLine <= 1;
            
            inputCompleted <= 0;
            pipelineFlushCounter <= 0;
        end
        else begin
            if((!inputCompleted && charInValid) || (inputCompleted && pipelineFlushCounter != 0)) begin
                prevMiddleVal <= rightAddrValid ? (firstLine ? (rightCharStart ? 1 : 0) : columnPaths[rightAddr]) : 0;
                
                rightChar <= inputCompleted ? "\n" : charIn; //flush the pipeline with newlines once the input is done
                middleChar <= rightChar;
                
                if(charNewline || inputCompleted) begin
                    firstLine <= 0;
                    newLine <= 1;
                    rightAddrValid <= 0;
                end
                else begin
                    rightAddrValid <= 1;
                    if(newLine) begin
                        newLine <= 0;
                    end
                end
                if(newLine) begin
                    rightAddr <= 0;
                end
                else begin
                    rightAddr <= rightAddr + 1;
                end
                
                middleAddr <= rightAddr;
                middleAddrValid <= rightAddrValid;
                leftAddr <= middleAddr;
                leftAddrValid <= middleAddrValid;
                addValid <= leftAddrValid;
                
                if(middleCharSplit) begin
                    rightVal <= prevMiddleVal;
                    middleVal <= rightVal;
                    leftVal <= middleVal + prevMiddleVal;
                    if(leftAddrValid) begin
                        columnPaths[leftAddr] <= middleVal + prevMiddleVal;
                    end
                    if(prevMiddleVal != 0) begin
                        splits <= splits + 1;
                    end
                end
                else begin
                    rightVal <= 0;
                    middleVal <= rightVal + prevMiddleVal;
                    leftVal <= middleVal;
                    if(leftAddrValid) begin
                        columnPaths[leftAddr] <= middleVal;
                    end
                end
                if(!addValid) begin
                    resetAdder <= 1;
                end
                else begin
                    if(resetAdder) begin
                        lineAdded <= leftVal;
                        resetAdder <= 0;
                    end
                    else begin
                        lineAdded <= lineAdded + leftVal;
                    end
                end
            end
            if(stop && !inputCompleted) begin
                inputCompleted <= 1;
                pipelineFlushCounter <= 4;
            end
            if(inputCompleted && pipelineFlushCounter != 0) begin
                pipelineFlushCounter <= pipelineFlushCounter - 1;
            end
        end
    end
    
    reg bcdConversionStarted = 0;
    reg[$clog2(BCD_CONVERSION_MULTICYCLE_LENGTH) - 1:0] bcdConversionCycles = 0;
    
    always @ (posedge clk) begin
        if(rst) begin
            bcdConversionStarted <= 0;
            bcdConversionCycles <= 0;
        end
        else begin
            if(!bcdConversionStarted && inputCompleted && pipelineFlushCounter == 0) begin
                bcdConversionStarted <= 1;
                bcdConversionCycles <= BCD_CONVERSION_MULTICYCLE_LENGTH;
            end
            if(bcdConversionStarted && bcdConversionCycles != 0) begin
                bcdConversionCycles <= bcdConversionCycles - 1;
            end
        end
    end
    
    wire[(MAX_OUTPUT / 3 + 1) * 4 - 1:0] partOneBCD;
    BinaryToBCD#(.BITS(MAX_OUTPUT)) partOneBCDConverter(.binaryIn(splits), .bcdOut(partOneBCD));
    
    wire[(MAX_OUTPUT / 3 + 1) * 4 - 1:0] partTwoBCD;
    BinaryToBCD#(.BITS(MAX_OUTPUT)) partTwoBCDConverter(.binaryIn(lineAdded), .bcdOut(partTwoBCD));
    
    reg shiftingOut = 0;
    wire readyToShift = bcdConversionStarted && bcdConversionCycles == 0;
    
    always @ (posedge clk) begin
        if(rst) begin
            shiftingOut <= 0;
        end
        else begin
            shiftingOut <= readyToShift;
        end
    end
    
    wire partOneShifterDone;
    NumberShifter#(.DIGITS(MAX_OUTPUT / 3 + 1)) partOneShifter(
        .bcdIn(partOneBCD),//constrain as multi cycle path of length BCD_CONVERSION_MULTICYCLE_LENGTH
        .start(!shiftingOut && readyToShift),
        .clk(clk),
        .rst(rst),
        .charOut(partOneCharOut),
        .charOutValid(partOneCharOutValid),
        .done(partOneShifterDone)
    );
    
    wire partTwoShifterDone;
    NumberShifter#(.DIGITS(MAX_OUTPUT / 3 + 1)) partTwoShifter(
        .bcdIn(partTwoBCD),
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
