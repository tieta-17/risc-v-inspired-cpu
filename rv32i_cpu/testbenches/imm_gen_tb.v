module imm_gen_tb;
    reg [31:0] instruction;
    reg [2:0] immediate_type;
    wire [31:0] imm_out;

    imm_gen dut(
        .instruction(instruction),
        .immediate_type(immediate_type),
        .imm_out(imm_out)
    );

    task check(input [31:0] expected, input [255:0] label);
        begin
            #1;
            if (imm_out != expected)
                $display("FAIL [%0s]: expected %h, got %h", label, expected, imm_out);
            else
                $display("PASS [%0s]: imm_out = %h", label, imm_out);
        end
    endtask

    initial begin
        // I-type, imm = 8 --> imm[11:0] =  0000 0000 1000
        instruction = 32'h00800000;
        immediate_type = 3'b001;
        check(32'd8, "I-Type, imm = 8");
    
        // I-Type instruction (sign extension) 0xFFF; expected 0xFFFFFFFF
        instruction = 32'hFFF00000;
        immediate_type = 3'b001;
        check(32'hFFFFFFFF, "I-type, imm = -1");

        // S-Type instruction, imm = 8 --> imm[11:5]=0000000, imm[4:0]=01000
        // instruction --> 0b0000000 00000 00000 000 01000 0000000 --> 0x00000400
        instruction = 32'h00000400;
        immediate_type = 3'b010;
        check(32'd8, "S-Type, imm = 8");

        // B-Type instruction, imm = 8 --> imm[12] = 0, imm[11] = 0, imm[10:5} = 000000, imm[4:1] = 0100, (bit 0 implied 0);
        // instruction --> 0b0 000000 00000 00000 000 0100 0 0000000 --> 0x000000400
        instruction = 32'h00000400;
        immediate_type = 3'b011;
        check(32'd8, "B-Type, imm = 8");

        // U-Type instruction, imm = 0x12345
        instruction = 32'h12345000;
        immediate_type = 3'b100;
        check(32'h12345000, "U-Type, imm = 0x12345000");

        // J-Type instruction, imm = 8 --> imm[20] = 0, imm[19:12] = 00000000 imm[11] = 0, imm[10:1] = 0000000100 (bit 0 implied 0);
        // instruction -> 0b0 0000000100 0 00000000 00000 0000000
        instruction = 32'h00800000;
        immediate_type = 3'b101;
        check(32'd8, "J-Type, imm = 8");

    $finish;
    end
endmodule
    
