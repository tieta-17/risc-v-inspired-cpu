module instr_mem(
    input [31:0] addr,      // pc addr
    output [31:0] instr     // instruction at that addr
);
    reg [31:0] mem [0:15];
    
    assign instr = mem[addr[31:2]];

    initial begin
        mem[0] = { 4'b0100, 4'd1, 4'd0, 20'd17 };        // ADDI x1, x0, 4      (a=4)
        mem[1] = { 4'b0100, 4'd2, 4'd0, 20'd3 };        // ADDI x2, x0, 3      (b=3)
        mem[2] = { 4'b0100, 4'd3, 4'd0, 20'd0 };        // ADDI x3, x0, 0      (result=0)
        mem[3] = { 4'b0111, 4'd0, 4'd2, 20'd16 };       // BEQ  x2, x0, +16    (loop: exit if counter==0)
        mem[4] = { 4'b0000, 4'd3, 4'd3, 4'd1, 16'b0 };  // ADD  x3, x3, x1     (result += a)
        mem[5] = { 4'b0100, 4'd2, 4'd2, 20'hFFFFF };    // ADDI x2, x2, -1     (counter -= 1)
        mem[6] = { 4'b0111, 4'd0, 4'd0, 20'hFFFF4 };    // BEQ  x0, x0, -12    (jump back to loop)
        mem[7] = { 4'b0111, 4'd0, 4'd0, 20'd0 };        // BEQ  x0, x0, 0      (halt: infinite self-loop)
    end
endmodule
