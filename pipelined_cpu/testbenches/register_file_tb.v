module register_file_tb;
    reg clk = 0;
    reg we;
    reg [3:0] rd_addr, rs1_addr, rs2_addr;
    reg [31:0] rd_data;
    wire [31:0] rs1_data, rs2_data;

    register_file dut (
        .clk(clk),
        .we(we),    
        .rd_addr(rd_addr), .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );

    always #5 clk = ~clk; // 10 unit clk period

    initial begin
        $dumpfile("regfile.vcd");
        $dumpvars(0, register_file_tb);
        $monitor("t=%0t we=%b rd_addr=%d rd_data=%d | rs1=%d->%d rs2=%d->%d",
                  $time, we, rd_addr, rd_data, rs1_addr, rs1_data, rs2_addr, rs2_data);
        
        // instantiate initial states
        we = 0; rd_addr = 0; rd_data = 0; rs1_addr = 0; rs2_addr = 0;
        @(negedge clk);

        // write 42 into register 3
        we = 1; rd_addr = 4'd3; rd_data = 32'd42; 
        @(negedge clk);

        // write 99 into  register 5
        rd_addr = 4'd5; rd_data = 32'd99; 
        @(negedge clk);

        // stop writing, read fr register 3 into rs1, register 5 into rs2
        we = 0;
        rs1_addr = 4'd3; rs2_addr = 4'd5;
        #10;

        // try writing to x0 — should NOT change (stays 0)
        we = 1; rd_addr = 4'd0; rd_data = 32'd777;
        @(negedge clk);
        we = 0; rs1_addr = 4'd0;
        #10;

        $finish;
    end
endmodule
