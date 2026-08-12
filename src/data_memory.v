module data_memory (
    input         clk,
    input         rst,
    input         mem_write,   // 1 = write this cycle (SW), 0 = read-only
    input  [31:0] addr,        // comes from ALU result (rs1 + imm)
    input  [31:0] write_data,  // value to store
    output [31:0] read_data    // value loaded (for LW)
);
    reg [31:0] mem [0:255];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 32'b0;
        end else if (mem_write) begin
            mem[addr[31:2]] <= write_data;
        end
    end

    assign read_data = mem[addr[31:2]];
endmodule