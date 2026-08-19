module data_memory (
    input         clk,
    input         rst,
    input         mem_write,   // 1 = write this cycle (SW), 0 = read-only
    input  [31:0] addr,        // comes from ALU result (rs1 + imm)
    input  [31:0] write_data,  // value to store
    output [31:0] read_data    // value loaded (for LW)
);
    reg [31:0] mem [0:15];
    always @(posedge clk) begin
        if (mem_write)
            mem[addr[31:2]] <= write_data;
    end

    assign read_data = mem[addr[31:2]];
endmodule
