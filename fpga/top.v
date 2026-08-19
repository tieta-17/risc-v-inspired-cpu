module top(
    input clk,
    output [5:0] led
);

    reg [3:0] rst_counter = 4'd0;
    reg rst_reg = 1'b1;

    always @(posedge clk) begin
        if (rst_counter < 4'd15)
            rst_counter <= rst_counter + 4'd1;
        rst_reg <= (rst_counter < 4'd15);
    end
    
    wire [31:0] wb_data;
    wire [3:0] wb_rd_addr;
    wire       wb_reg_write;

    pipelined_datapath dut (
        .clk(clk), .rst(rst_reg),
        .dbg_wb_data(wb_data),
        .dbg_wb_rd_addr(wb_rd_addr),
        .dbg_wb_reg_write(wb_reg_write)
    );

    // watch for any write to x3, latch the value
    reg [31:0] x3_shadow;
    always @(posedge clk) begin
        if (rst_reg)
            x3_shadow <= 32'b0;
        else if (wb_reg_write && wb_rd_addr == 4'd3)
            x3_shadow <= wb_data;
    end

    assign led[5:0] = ~x3_shadow[5:0];    // result, lower 6 bits (active-low)
endmodule    
