module alu_tb;
    reg  [31:0] rs1, rs2;
    reg  [2:0]  alu_op;
    wire [31:0] rd;
    wire        zero;

    alu dut (
        .rs1(rs1),
        .rs2(rs2),
        .alu_op(alu_op),
        .rd(rd),
        .zero(zero)
    );

    task check(input [31:0] expected_rd, input expected_zero, input [255:0] label);
        if (rd !== expected_rd)
            $display("FAIL [%0s]: rd expected %d, got %d", label, expected_rd, rd);
        else if (zero !== expected_zero)
            $display("FAIL [%0s]: zero expected %b, got %b", label, expected_zero, zero);
        else
            $display("PASS [%0s]: rd=%d zero=%b", label, rd, zero);
    endtask

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
        $monitor("t=%0t alu_op=%b rs1=%d rs2=%d | rd=%d zero=%b",
                  $time, alu_op, rs1, rs2, rd, zero);

        // ADD
        rs1 = 32'd100; rs2 = 32'd101; alu_op = 3'b000; #10;
        check(32'd201, 1'b0, "ADD 100 + 101");

        // SUB — rs1 != rs2, zero should stay LOW
        rs1 = 32'd100; rs2 = 32'd99; alu_op = 3'b001; #10;
        check(32'd1, 1'b0, "SUB 100 - 99, zero low");

        // SUB — rs1 == rs2, zero should FIRE
        rs1 = 32'd1; rs2 = 32'd1; alu_op = 3'b001; #10;
        check(32'd0, 1'b1, "SUB 1 - 1, zero high");

        // AND
        rs1 = 32'b111; rs2 = 32'b101; alu_op = 3'b010; #10;
        check(32'b101, 1'b0, "AND 0b111, 0b101");

        // OR
        rs1 = 32'b100; rs2 = 32'b011; alu_op = 3'b011; #10;
        check(32'b111, 1'b0, "OR 0b100, 0b011");

        // Default case — unused alu_op
        rs1 = 32'd10; rs2 = 32'd10; alu_op = 3'b111; #10;
        check(32'd0, 1'b1, "UNUSED opcode -> default 0");

        $finish;
    end
endmodule