module imm_gen(
    input [31:0] instruction,
    input [2:0] immediate_type, // I-type, S-type, B-type, U-type, J-type
    output reg [31:0] imm_out
);
    always @(*) begin
        case (immediate_type)
            3'b001 : imm_out = { {20{instruction[31]}}, instruction[31:20] }; // I-type opcode
            3'b010 : imm_out = { {20{instruction[31]}}, instruction[31:25], instruction[11:7] }; // S-type opcode
            3'b011 : imm_out = { {19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0 }; // B-type opcode
            3'b100 : imm_out = { instruction[31:12], 12'b0 }; // U-type opcode
            3'b101 : imm_out = { {11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type opcode
            default : imm_out = 32'b0;
        endcase
     end
endmodule
