module pipelined_datapath_tb;
    reg clk;
    reg rst;

    pipelined_datapath dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        $dumpfile("build/pipelined_datapath.vcd");
        $dumpvars(0, pipelined_datapath_tb);

        rst = 1;
        @(negedge clk);
        rst = 0;

        // preload a trivial program: just NOP-like ADDs so we can confirm
        // the pipeline advances without errors before testing real hazards
        // addr 0: ADD x1, x0, x0   (x1 = 0 + 0 = 0, harmless)
        dut.imem_inst.mem[0] = { 4'b0000, 4'd1, 4'd0, 4'd0, 16'b0 };
        // addr 4: ADD x2, x0, x0
        dut.imem_inst.mem[1] = { 4'b0000, 4'd2, 4'd0, 4'd0, 16'b0 };
        // addr 8: ADD x3, x0, x0
        dut.imem_inst.mem[2] = { 4'b0000, 4'd3, 4'd0, 4'd0, 16'b0 };

        // just run several cycles and watch it not blow up
        repeat (10) @(posedge clk);

        $display("Ran 10 cycles without error. PC ended at: %d", dut.pc_current);
        $finish;
    end
endmodule