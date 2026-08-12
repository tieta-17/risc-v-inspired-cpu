// instruction decode / execute pipelined register
module id_ex_reg (
    input clk, rst, stall, flush,
    
    // from control_unit
    input [2:0] alu_op_in,
    input alu_src_in, reg_write_in, mem_write_in, mem_to_reg_in, branch_in,

    // data input
    input [31:0] rs1_data_in, rs2_data_in, imm_extended_in, pc_in,
    input [3:0] rd_addr_in, rs1_addr_in, rs2_addr_in,

    // output registers
    output reg [2:0] alu_op_out,
    output reg alu_src_out, reg_write_out, mem_write_out, mem_to_reg_out, branch_out,
    output reg [31:0] rs1_data_out, rs2_data_out, imm_extended_out, pc_out,
    output reg [3:0] rd_addr_out, rs1_addr_out, rs2_addr_out
);
    always @(posedge clk) begin
        if (rst || flush) begin
            reg_write_out <= 1'b0; mem_write_out <= 1'b0; branch_out <= 1'b0;
            alu_op_out <= 3'b0; alu_src_out <= 1'b0; mem_to_reg_out <= 1'b0;
        end else if (!stall) begin
            alu_op_out <= alu_op_in;

            alu_src_out <= alu_src_in; reg_write_out <= reg_write_in; mem_write_out <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in; branch_out <= branch_in;

            //data stream
            rs1_data_out <= rs1_data_in; rs2_data_out <= rs2_data_in; imm_extended_out <= imm_extended_in;
            pc_out <= pc_in;

            rd_addr_out <= rd_addr_in; rs1_addr_out <= rs1_addr_in; rs2_addr_out <= rs2_addr_in;
        end
    end
endmodule