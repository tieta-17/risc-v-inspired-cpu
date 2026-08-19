// execute - memory pipeline register
module ex_mem_reg (
    input clk, rst, stall, flush,

    input [31:0] alu_result_in,
    input [31:0] rs2_data_in, 
    input [3:0] rd_addr_in,
    input reg_write_in, mem_write_in, mem_to_reg_in,

    output reg [31:0] alu_result_out,
    output reg [31:0] rs2_data_out,
    output reg [3:0] rd_addr_out,
    output reg reg_write_out, mem_write_out, mem_to_reg_out
);
    always @(posedge clk) begin
        if (rst || flush) begin
            alu_result_out <= 32'b0; rs2_data_out <= 32'b0;
            rd_addr_out <= 4'b0;
            reg_write_out <= 1'b0; mem_write_out <= 1'b0; mem_to_reg_out <= 1'b0;
        end else if (!stall) begin
            alu_result_out <= alu_result_in; rs2_data_out <= rs2_data_in;
            rd_addr_out <= rd_addr_in;
            reg_write_out <= reg_write_in; mem_write_out <= mem_write_in; mem_to_reg_out <= mem_to_reg_in;
        end
    end
endmodule