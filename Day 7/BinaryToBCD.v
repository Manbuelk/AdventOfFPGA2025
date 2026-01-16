`timescale 1ns / 1ps

module BinaryToBCD#(
    parameter BITS = 64,
    parameter BCDDIGITS = BITS / 3 + 1
)(
    input[BITS - 1:0] binaryIn,
    output[BCDDIGITS * 4 - 1:0] bcdOut
);
    
    reg[BITS + 4 * BCDDIGITS - 1:0] workingReg;
    
    integer iterations;
    integer bcdPos;
    
    always @ (*) begin
        workingReg = {{4 * BCDDIGITS{1'b0}}, binaryIn};
        for(iterations = 0; iterations < BITS; iterations = iterations + 1) begin
            for(bcdPos = 0; bcdPos < BCDDIGITS; bcdPos = bcdPos + 1) begin
                if(workingReg[BITS + 4 * (bcdPos + 1) - 1-:4] >= 5) begin
                    workingReg[BITS + 4 * (bcdPos + 1) - 1-:4] = workingReg[BITS + 4 * (bcdPos + 1) - 1-:4] + 3;
                end
            end
            workingReg = workingReg << 1;
        end
    end

    assign bcdOut = workingReg[BITS + 4 * BCDDIGITS - 1-:BCDDIGITS * 4];

endmodule
