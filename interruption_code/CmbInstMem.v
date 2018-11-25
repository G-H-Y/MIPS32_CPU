`timescale 1ns / 1ps

// Brief: Instruction Memory, combinatorial
// Description: Fetch instruction from memory
// Author: azure-crab
module CmbInstMem(addr, inst);
    parameter ProgPath = "E:/lab/test/interrupt_benchmark.hex";
    input [31:0] addr;
    output [31:0] inst;
    
    reg [31:0] prog[0:1023];
    initial $readmemh(ProgPath, prog);
    assign inst = prog[addr[11:2]];
endmodule
