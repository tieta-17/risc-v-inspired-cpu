module branch_flush_tb;
    reg clk;
    reg rst;

    pipelined_datapath dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    task check_reg(input [3:0] reg_num, input [31:0] expected, input [255:0] label);
        if (dut.reg_file_inst.regs[reg_num] !== expected)
            $display("FAIL [%0s]: x%0d expected %d, got %d",
                       label, reg_num, expected, dut.reg_file_inst.regs[reg_num]);
        else
            $display("PASS [%0s]: x%0d = %d", label, reg_num, dut.reg_file_inst.regs[reg_num]);
    endtask

    task dump_regs;
        integer j;
        begin
            $display("---- register file ----");
            for (j = 0; j < 16; j = j + 1)
                $display("x%0d = %d", j, dut.reg_file_inst.regs[j]);
        end
    endtask

    task dump_mem(input integer count);
        integer j;
        begin
            $display("---- data memory (first %0d words) ----", count);
            for (j = 0; j < count; j = j + 1)
                $display("mem[%0d] = %d", j, dut.data_memory_inst.mem[j]);
        end
    endtask

    initial begin
        clk = 0;
        $dumpfile("dumpfiles/branch_flush.vcd");
        $dumpvars(0, branch_flush_tb);
        
        rst = 1;
        @(negedge clk);
        rst = 0;
        dump_regs;
        
        // --- branch flush test program ---
        dut.imem_inst.mem[0] = { 4'b0100, 4'd1, 4'd0, 20'd0 };            // ADDI x1, x0, 0
        dut.imem_inst.mem[1] = { 4'b0111, 4'd1, 4'd1, 20'd12 };            // BEQ x1, x1, +12
        dut.imem_inst.mem[2] = { 4'b0100, 4'd9, 4'd0, 20'd99 };            // ADDI x9, x0, 99  (wrong-path)
        dut.imem_inst.mem[3] = { 4'b0100, 4'd9, 4'd0, 20'd88 };            // ADDI x9, x0, 88  (wrong-path)
        dut.imem_inst.mem[4] = { 4'b0100, 4'd2, 4'd0, 20'd5  };         // ADDI x2, x0, 5   (real target)
        
        repeat (20) @(posedge clk);
        #1;

        check_reg(4'd9, 32'd0, "x9 must stay 0 -- wrong-path instructions must be flushed");
        check_reg(4'd2, 32'd5, "x2 = 5 -- branch target instruction must execute");

        dump_mem(8);   // first 8 words is usually plenty for a small test program
        dump_regs;
        $display("Final PC: %d", dut.pc_current);
        $finish;
    end
endmodule

