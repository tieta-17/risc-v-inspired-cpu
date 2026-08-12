module hazard_edge_cases_tb;
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
        $dumpfile("build/hazard_edge_cases.vcd");
        $dumpvars(0, hazard_edge_cases_tb);
        
        // ===================================================================
        // TEST 1: branch NOT taken — fall-through must execute, nothing flushed
        // ===================================================================
        rst = 1;
        @(negedge clk);
        rst = 0;

        // addr 0: ADDI x1, x0, 5     -- x1 = 5
        // addr 4: BEQ x1, x0, +100   -- 5 != 0, must NOT branch
        // addr 8: ADDI x9, x0, 42    -- must execute (fall-through)
        dut.imem_inst.mem[0] = { 4'b0100, 4'd1, 4'd0, 20'd5 };
        dut.imem_inst.mem[1] = { 4'b0111, 4'd0, 4'd1, 20'd100 };
        dut.imem_inst.mem[2] = { 4'b0100, 4'd9, 4'd0, 20'd42 };

        repeat (15) @(posedge clk);
        #1;
        check_reg(4'd9, 32'd42, "not-taken branch: fall-through must execute normally");

        // ===================================================================
        // TEST 2: forwarding into a branch comparison
        // x1 is overwritten immediately before BEQ reads it — if forwarding
        // fails, BEQ sees the STALE regfile value (0) and wrongly branches.
        // ===================================================================
        rst = 1;
        @(posedge clk);
        @(negedge clk);
        rst = 0;

        // addr 0:  ADDI x1, x0, 0    -- x1 = 0 (stale regfile value)
        // addr 4:  ADDI x1, x0, 9    -- x1 = 9 (regfile write hasn't landed yet)
        // addr 8:  BEQ  x1, x0, +100 -- must compare against FORWARDED x1=9, not stale 0
        // addr 12: ADDI x9, x0, 55   -- must execute (proves branch correctly NOT taken)
        dut.imem_inst.mem[0] = { 4'b0100, 4'd1, 4'd0, 20'd0 };
        dut.imem_inst.mem[1] = { 4'b0100, 4'd1, 4'd0, 20'd9 };
        dut.imem_inst.mem[2] = { 4'b0111, 4'd0, 4'd1, 20'd100 };
        dut.imem_inst.mem[3] = { 4'b0100, 4'd9, 4'd0, 20'd55 };

        repeat (15) @(posedge clk);
        #1;
        check_reg(4'd9, 32'd55, "forwarding into BEQ comparison must use the FRESH value, not stale regfile read");

        $finish;
    end
endmodule