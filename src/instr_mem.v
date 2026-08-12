module instr_mem(
    input [31:0] addr,      // pc addr
    output [31:0] instr     // instruction at that addr
);
    reg [31:0] mem [0:255];
    
    assign instr = mem[addr[31:2]];
endmodule