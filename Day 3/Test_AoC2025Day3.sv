`timescale 1ns / 1ps

module Test_AoC2025Day3();
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
    
    string partOneExpected = "357";
    string partTwoExpected = "3121910778619";
    
    initial begin
        inputFile = $fopen("./day3Test.txt", "r");
        assert(inputFile) else $fatal(0, "Could not open input file, please make sure the \"day3Test.txt\" file is in the working directory of the simulator.");
        solveInput();
        assert(partOne.compare(partOneExpected) == 0) $display("Part 1 passed, result = %s", partOne);
            else $error("Part 1 failed, result = %s, expected %s", partOne, partOneExpected);
        assert(partTwo.compare(partTwoExpected) == 0) $display("Part 2 passed, result = %s", partTwo);
            else $error("Part 2 failed, result = %s, expected %s", partTwo, partTwoExpected);
        $finish();
    end

    AoC2025Day3 test(
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
