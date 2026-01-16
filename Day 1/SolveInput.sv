`timescale 1ns / 1ps

module SolveInput();
    reg[7:0] charIn;
    reg charInValid;
    reg done;
    reg clk;
    reg rst;
    
    wire[7:0] partOneCharOut;
    wire partOneCharOutValid;
    wire partOneDone;
    
    wire[7:0] partTwoCharOut;
    wire partTwoCharOutValid;
    wire partTwoDone;
    
    string partOne = "";
    string partTwo = "";
    
    integer inputFile;
    
    task tick;
        #1;
        clk = 1;
        #1;
        clk = 0;
    endtask
    
    task reset;
        rst = 1;
        done = 0;
        partOne = "";
        partTwo = "";
        tick();
        rst = 0;
    endtask
    
    task solveInput;
        reset();
        while(!$feof(inputFile)) begin
            if($fgets(charIn, inputFile)) begin
                charInValid = 1;
                tick();
            end
        end
        charInValid = 0;
        done = 1;
        while(!(partOneDone && partTwoDone)) begin
            if(partOneCharOutValid) begin
                partOne = {partOne, partOneCharOut};
            end
            if(partTwoCharOutValid) begin
                partTwo = {partTwo, partTwoCharOut};
            end
            tick();
        end
    endtask;
    
    initial begin
        inputFile = $fopen("./input.txt", "r");
        assert(inputFile) else $fatal(0, "Could not open input file, please make sure the \"input.txt\" file is in the working directory of the simulator.");
        solveInput();
        $display("Part 1 = %s \nPart 2 = %s", partOne, partTwo);
        $finish();
    end

    AoC2025Day1 test(
        .charIn(charIn),
        .charInValid(charInValid),
        .stop(done),
        .clk(clk),
        .rst(rst),
        
        .partOneCharOut(partOneCharOut),
        .partOneCharOutValid(partOneCharOutValid),
        .partOneDone(partOneDone),
        .partTwoCharOut(partTwoCharOut),
        .partTwoCharOutValid(partTwoCharOutValid),
        .partTwoDone(partTwoDone)
    );
endmodule