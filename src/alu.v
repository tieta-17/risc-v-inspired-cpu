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

module alu(
    input [31:0] rs1,
    input [31:0] rs2,
    input [2:0] alu_op,
    output [31:0] rd,
    output zero
);
    reg [31:0] ALU_result;
    assign rd = ALU_result;
    assign zero = (ALU_result == 32'b0);

    always @(*)
    begin
        case (alu_op)
            3'b000:
                ALU_result = rs1 + rs2;
            3'b001:
                ALU_result = rs1 - rs2;
            3'b010:
                ALU_result = rs1 & rs2;
            3'b011:
                ALU_result = rs1 | rs2;
            default: ALU_result = 32'b0;
            // 3'b100, 101, 110, 111 — reserved, not yet used by any instruction
        endcase
    end
endmodule