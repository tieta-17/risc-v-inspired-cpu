module hazard_detect_tb;
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

    initial begin
        clk = 0;
        $dumpfile("dumpfiles/hazard_detect.vcd");
        $dumpvars(0, hazard_detect_tb);

        rst = 1;
        @(negedge clk);
        rst = 0;

        // --- initial register values ---
        dut.reg_file_inst.regs[1] = 32'd10;   // x1 = 10
        dut.reg_file_inst.regs[2] = 32'd7;    // x2 = 7

        // --- program ---
        // addr 0:  ADD x3, x1, x2       -- x3 = 17   (back-to-back hazard target)
        dut.imem_inst.mem[0] = { 4'b0000, 4'd3, 4'd1, 4'd2, 16'b0 };
        // addr 4:  SUB x5, x3, x1       -- needs x3 IMMEDIATELY (EX/MEM forward case)
        dut.imem_inst.mem[1] = { 4'b0001, 4'd5, 4'd3, 4'd1, 16'b0 };
        // addr 8:  ADDI x6, x1, 0       -- unrelated filler instruction
        dut.imem_inst.mem[2] = { 4'b0100, 4'd6, 4'd1, 20'd0 };
        // addr 12: ADD x7, x3, x2       -- needs x3, one instruction later (MEM/WB forward case)
        dut.imem_inst.mem[3] = { 4'b0000, 4'd7, 4'd3, 4'd2, 16'b0 };
        // addr 16: LW  x8, 0(x1)        -- load (address = x1 = 10 -> word index 2, uninitialized -> 0)
        dut.imem_inst.mem[4] = { 4'b0101, 4'd8, 4'd1, 20'd0 };
        // addr 20: ADD x9, x8, x1       -- load-use hazard: needs x8 IMMEDIATELY (stall + forward)
        dut.imem_inst.mem[5] = { 4'b0000, 4'd9, 4'd8, 4'd1, 16'b0 };

        // run enough cycles for everything (including the stall bubble) to fully drain
        // 6 instructions, deepest pipeline latency ~5 stages, +1 for the stall = ~16 cycles is safe
        
        repeat (20) @(posedge clk);
        #1;

        check_reg(4'd3, 32'd17, "ADD x3 = x1+x2");
        check_reg(4'd5, 32'd7,  "SUB x5 = x3-x1 (EX/MEM forward)");
        check_reg(4'd7, 32'd24, "ADD x7 = x3+x2 (MEM/WB forward, one gap)");
        check_reg(4'd9, 32'd10, "ADD x9 = x8+x1 (load-use stall+forward)");

        $display("Final PC: %d", dut.pc_current);
        $finish;
    end
endmodule