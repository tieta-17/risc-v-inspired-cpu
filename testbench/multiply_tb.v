module mult_loop_tb;
    reg clk;
    reg rst;

    pipelined_datapath dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    task check_reg(input [3:0] reg_num, input [31:0] expected, input [255:0] label);
        if (dut.reg_file_inst.regs[reg_num] !== expected)
            $display("FAIL [%0s]: x%0d expected %d, got %d",
                       label, reg_num, expected, dut.reg_file_inst.regs[reg_num]);
        else
            $display("PASS [%0s]: x%0d = %d", label, reg_num, dut.reg_file_inst.regs[reg_num]);
    endtask

    initial begin
        clk = 0;
        $dumpfile("build/mult_loop.vcd");
        $dumpvars(0, mult_loop_tb);

        rst = 1;
        @(negedge clk);
        rst = 0;

        // a = 4, b = 3  -->  expect x3 = 12
        dut.reg_file_inst.regs[1] = 32'd4;   // x1 = a
        dut.reg_file_inst.regs[2] = 32'd3;   // x2 = b (counter)

        // addr 0:  ADDI x3, x0, 0
        dut.imem_inst.mem[0] = { 4'b0100, 4'd3, 4'd0, 20'd0 };
        // addr 4:  BEQ x2, x0, +16   (target = 4+16 = 20 = "end")
        dut.imem_inst.mem[1] = { 4'b0111, 4'd0, 4'd2, 20'd16 };
        // addr 8:  ADD x3, x3, x1
        dut.imem_inst.mem[2] = { 4'b0000, 4'd3, 4'd3, 4'd1, 16'b0 };
        // addr 12: ADDI x2, x2, -1
        dut.imem_inst.mem[3] = { 4'b0100, 4'd2, 4'd2, 20'hFFFFF };
        // addr 16: BEQ x0, x0, -12   (target = 16-12 = 4 = "loop")
        dut.imem_inst.mem[4] = { 4'b0111, 4'd0, 4'd0, 20'hFFFF4 };
        // addr 20: (end) ADDI x5, x0, 1   -- marker instruction, confirms we actually exited
        dut.imem_inst.mem[5] = { 4'b0100, 4'd5, 4'd0, 20'd1 };

        // enough cycles for 3 full loop iterations plus pipeline drain
        repeat (60) @(posedge clk);
        #1;

        check_reg(4'd3, 32'd12, "x3 = a*b = 4*3");
        check_reg(4'd2, 32'd0,  "x2 = 0 (loop counter exhausted)");
        check_reg(4'd5, 32'd1,  "x5 = 1 (confirms loop actually exited, not stuck)");

        $finish;
    end
endmodule