// Reference 1: Computer Organization and Design RISC-V Edition
// Reference 2: RISC_V CARD RV32I Base Integer Instructions - https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf 
// Figure 4.12 --> design parameters for alu

module alu_control_unit(
    input [1:0] alu_op_category, // derived from reference, 0b00 = force ADD, 0b01 = force SUB, 0b10 requires decode from funct3 & 7
    input funct7_bit5,           // instruction[30] only meaningful when alu_op_category is 0b10
    input [2:0] funct3,
    output reg [3:0] alu_op
); 
    always @(*) begin
        case (alu_op_category)
            2'b00 : alu_op = 4'b0000; // forced ADD (loads/stores)
            2'b01 : alu_op = 4'b1000; // forced SUB (branches)
            2'b10 : begin 
                case ({funct7_bit5, funct3})
                    4'b0000 : alu_op = 4'b0000; // add
                    4'b1000 : alu_op = 4'b1000; // subtract
                    4'b0100 : alu_op = 4'b0100; // XOR
                    4'b0110 : alu_op = 4'b0110; // OR             
                    4'b0111 : alu_op = 4'b0111; // AND
                    4'b0001 : alu_op = 4'b0001; // SLL (shift left logical)
                    4'b0101 : alu_op = 4'b0101; // SRL (shift right logical)
                    4'b1101 : alu_op = 4'b1101; // SRA (shift right arithmetic)
                    4'b0010 : alu_op = 4'b0010; // SLT (set less than)
                    4'b0011 : alu_op = 4'b0011; // SLTU (set less than unsigned) 
                    default : alu_op = 4'b0000;
                endcase
            end
            default : alu_op = 4'b0000;
        endcase
    end 
endmodule       
