`timescale 1ns / 1ps

module NumberShifter#(
    parameter DIGITS = 4
    )(
    input[DIGITS * 4 - 1:0] bcdIn,
    input start,
    output[7:0] charOut,
    output charOutValid,
    output done,
    input clk,
    input rst
    );
    
    reg shifting = 0;
    reg sendZeroes = 0;//needed to strip leading zeroes
    reg[DIGITS * 4 - 1:0] shiftOut = 0;
    reg[DIGITS:0] digitLast = 0;//one larger than the amount of digits to keep track of the position of a null character at the end
    
    wire[3:0] shiftedBCD = shiftOut[DIGITS * 4 - 1-:4];
    
    always @ (posedge clk) begin
        if(rst) begin
            shifting <= 0;
            sendZeroes <= 0;
            shiftOut <= 0;
            digitLast <= 0;
        end
        else begin
            if(start) begin
                shifting <= 1;
                shiftOut <= bcdIn;
                sendZeroes <= 0;
                digitLast <= 1;
            end
            else begin
                shiftOut <= {shiftOut[(DIGITS - 1) * 4 - 1:0], 4'b0};
                digitLast <= {digitLast[DIGITS - 1:0], 1'b0};
                if(digitLast[DIGITS]) begin //done shifting
                    shifting <= 0;
                end
                if(digitLast[DIGITS - 2] || shiftedBCD != 4'b0000) begin //start sending zeroes after first non zero or on last character
                    sendZeroes <= 1;
                end
            end
        end
    end
    
    wire[7:0] asciiNumOut = {4'b0011, shiftedBCD};
    wire asciiNumOutValid = shiftedBCD != 4'b0000 || sendZeroes;
    assign charOut = digitLast[DIGITS] ? 8'b0 : asciiNumOut;
    assign charOutValid = shifting && (digitLast[DIGITS] ? 1 : asciiNumOutValid);
    assign done = !shifting;
    
endmodule
