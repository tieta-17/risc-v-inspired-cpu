/*
  * Opcode	Mnemonic	Type	Meaning
  * 0000	ADD	R	rd = rs1 + rs2
  * 0001	SUB	R	rd = rs1 - rs2
  * 0010	AND	R	rd = rs1 & rs2
  * 0011	OR	R	rd = rs1 | rs2
  * 0100	ADDI	I	rd = rs1 + imm
  * 0101	LW	I	rd = MEM[rs1 + imm]
  * 0110	SW	I	MEM[rs1 + imm] = rd
  * 0111	BEQ	I	if (rs1 == rd) PC += imm
* */

module control_unit (
    input      [3:0] opcode,     // instr[31:28]

    output reg [2:0] alu_op,
    output reg       alu_src,       // 0 = rs2_data, 1 = immediate
    output reg       reg_write,     // 1 = write ALU result back to regfile
    output reg       mem_write,     // 1 = SW writes to data_memory this cycle
    output reg       mem_to_reg,    // 0 = write-back ALU result, 1 = write-back data_memory read_data
    output reg use_rd_as_rs2,       // 1 = read register file 2nd port
    output reg branch               // 1 --> redirects pc
);

    always @(*) begin
        case (opcode)
            4'b0000: begin // ADD
                alu_op = 3'b000; 
                alu_src = 1'b0; 
                reg_write = 1'b1; 
                mem_write = 1'b0; 
                mem_to_reg = 1'b0;
                use_rd_as_rs2 = 1'b0;
                branch = 1'b0;
            end

            4'b0001: begin // SUB
                alu_op = 3'b001;
                alu_src = 1'b0;
                reg_write = 1'b1;
                mem_write = 1'b0; 
                mem_to_reg = 1'b0;
                use_rd_as_rs2 = 1'b0;
                branch = 1'b0;
            end

            4'b0010: begin // AND
                alu_op = 3'b010;
                alu_src = 1'b0;
                reg_write = 1'b1;
                mem_write = 1'b0; 
                mem_to_reg = 1'b0;
                use_rd_as_rs2 = 1'b0;
                branch = 1'b0;
            end

            4'b0011: begin // OR
                alu_op = 3'b011;
                alu_src = 1'b0;
                reg_write = 1'b1;
                mem_write = 1'b0; 
                mem_to_reg = 1'b0;
                use_rd_as_rs2 = 1'b0;
                branch = 1'b0;
            end

            4'b0100: begin // ADDI
                alu_op = 3'b000;
                alu_src = 1'b1;
                reg_write = 1'b1;
                mem_write = 1'b0; 
                mem_to_reg = 1'b0;
                use_rd_as_rs2 = 1'b0;
                branch = 1'b0;
            end

            4'b0101: begin // LW
                alu_op = 3'b000;
                alu_src = 1'b1;
                reg_write = 1'b1;
                mem_write = 1'b0;
                mem_to_reg = 1'b1;
                use_rd_as_rs2 = 1'b0;
                branch = 1'b0;
            end

            4'b0110: begin // SW
                alu_op = 3'b000;
                alu_src = 1'b1;
                reg_write = 1'b0;
                mem_write = 1'b1;
                mem_to_reg = 1'b0;
                use_rd_as_rs2 = 1'b1;   // store-data comes from the rd-position field
                branch = 1'b0;
            end

            4'b0111: begin // BEQ
                alu_op = 3'b001;
                alu_src = 1'b0;
                reg_write = 1'b0;
                mem_write = 1'b0;
                mem_to_reg = 1'b0;
                use_rd_as_rs2 = 1'b1;   // comparand comes from the rd-position field
                branch = 1'b1;
            
            end

            default: begin
                alu_op = 3'b000; 
                alu_src = 1'b0; 
                reg_write = 1'b0; 
                mem_write = 1'b0; 
                mem_to_reg = 1'b0;
                branch = 1'b0;
            end
        endcase
    end

endmodule