module reg_file(
    input clk,
    input we,
    input [4:0] rd_addr, rs1_addr, rs2_addr,
    input [31:0] rd_data,
    output [31:0] rs1_data, rs2_data
);
    reg [31:0] regs[0:31];
    
    // synchronous write
    always @(posedge clk) begin
        if (we && rd_addr != 5'b0)
            regs[rd_addr] <= rd_data;
    end
    
    // combinational read coupled with bypass
    // if we write into source register, just pass the value immediately rather than wait for WB stage
    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : (we && rd_addr == rs1_addr) ?  rd_data : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : (we && rd_addr == rs2_addr) ? rd_data : regs[rs2_addr];               
endmodule
