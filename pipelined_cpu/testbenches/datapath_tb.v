module datapath_tb;
    reg clk;
    reg rst;
    integer i;

    datapath dut (
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

    task check_mem(input [31:0] word_addr, input [31:0] expected, input [255:0] label);
        if (dut.data_memory_inst.mem[word_addr] !== expected)
            $display("FAIL [%0s]: mem[%0d] expected %d, got %d",
                       label, word_addr, expected, dut.data_memory_inst.mem[word_addr]);
        else
            $display("PASS [%0s]: mem[%0d] = %d", label, word_addr, dut.data_memory_inst.mem[word_addr]);
    endtask

    initial begin
        clk = 0;
        $dumpfile("vcd/datapath.vcd");
        $dumpvars(0, datapath_tb);
        for (i = 0; i < 16; i = i + 1)
            $dumpvars(0, dut.reg_file_inst.regs[i]);
        for (i = 0; i < 16; i = i + 1)
            $dumpvars(0, dut.imem_inst.mem[i]);

        // --- reset ---
        rst = 1;
        @(negedge clk);
        rst = 0;

        // --- program ---
        // addr 0:  ADD x3, x1, x2        rd=3 rs1=1 rs2=2
        dut.imem_inst.mem[0] = { 4'b0000, 4'd3, 4'd1, 4'd2, 16'b0 };
        // addr 4:  SUB x4, x3, x1        rd=4 rs1=3 rs2=1
        dut.imem_inst.mem[1] = { 4'b0001, 4'd4, 4'd3, 4'd1, 16'b0 };
        // addr 8:  SW  x4 -> MEM[x1+0]   rd=4 (source data) rs1=1 (base) imm=0
        dut.imem_inst.mem[2] = { 4'b0110, 4'd4, 4'd1, 20'd0 };
        // addr 12: LW  x5 <- MEM[x1+0]   rd=5 (dest) rs1=1 (base) imm=0
        dut.imem_inst.mem[3] = { 4'b0101, 4'd5, 4'd1, 20'd0 };

        // --- initial register values ---
        dut.reg_file_inst.regs[1] = 32'd10;  // x1 = 10 (used as SW/LW base address too)
        dut.reg_file_inst.regs[2] = 32'd7;   // x2 = 7

        // --- cycle 1: executes ADD (addr 0), PC advances to 4 ---
        @(posedge clk);
        #1;
        check_reg(4'd3, 32'd17, "ADD x3 = x1+x2");

        // --- cycle 2: executes SUB (addr 4), PC advances to 8 ---
        @(posedge clk);
        #1;
        check_reg(4'd4, 32'd7, "SUB x4 = x3-x1");

        // --- cycle 3: executes SW (addr 8), PC advances to 12 ---
        // data_memory indexes by word (addr>>2), so base=10, imm=0 -> byte addr 10 -> word index 2
        @(posedge clk);
        #1;
        check_mem(32'd2, 32'd7, "SW stores x4 into MEM[x1+0]");

        // --- cycle 4: executes LW (addr 12), PC advances to 16 ---
        @(posedge clk);
        #1;
        check_reg(4'd5, 32'd7, "LW loads x5 <- MEM[x1+0]");

        $finish;
    end
endmodule