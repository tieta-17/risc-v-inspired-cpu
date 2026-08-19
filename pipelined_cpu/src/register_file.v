module register_file(
    input clk,              // clock signal 
    input we,               // write enable
    input rst,              // reset
    input [3:0] rd_addr,    // write destination
    input [31:0] rd_data,   // write data
    input [3:0] rs1_addr,   // 1 of 16 registers --> port 1
    input [3:0] rs2_addr,   // 1 of 16 registers --> port 2
    output [31:0] rs1_data, // 32 bits --> value fr rs1_addr
    output [31:0] rs2_data  // 32 bits --> value fr rs2_addr
);
    reg [31:0] regs [15:0]; // 16 32-bit registers grouped into an array
    integer i;
    // synchronous write (dependent on clk)
    always @(posedge clk) begin // always on rising clock edge
        if (rst) begin
            for (i = 0; i < 16; i = i+1)
                regs[i] <= 32'b0;
        end else if (we && rd_addr != 4'b0) begin // write enable and NOT register 0
            regs[rd_addr] <= rd_data; // non-blocking — schedules update for end of rising clock edge
        end
    end

    // combinational read
    assign rs1_data = (rs1_addr == 4'b0) ? 32'b0 : 
                      (we && rd_addr == rs1_addr) ? rd_data : // if dest is source register 1, just pass rd_data, rather than read fr addr
                      regs[rs1_addr]; // if rs1_addr = 0, return 0, otw return whatever value in rs1
    assign rs2_data = (rs2_addr == 4'b0) ? 32'b0 : 
                      (we && rd_addr == rs2_addr) ? rd_data : // if dest is source register 1, just pass rd_data, rather than read fr addr
                      regs[rs2_addr]; // if rs2_addr = 0, return 0, otw return whatever value in rs2
endmodule