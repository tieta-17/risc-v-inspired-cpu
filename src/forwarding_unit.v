module forwarding_unit (
    input [3:0] ex_rs1_addr, ex_rs2_addr,   // the instruction currently in EX, about to use the ALU
    input [3:0] mem_rd_addr,                // instruction in EX/MEM (one stage ahead)
    input       mem_reg_write,
    input [3:0] wb_rd_addr,                 // instruction in MEM/WB (two stages ahead)
    input       wb_reg_write,

    output reg [1:0] forward_a,   // controls ALU's rs1 input
    output reg [1:0] forward_b    // controls ALU's rs2 input
); 
    // 2'b00 = no forwarding (use register file value)
    // 2'b01 = forward from EX/MEM (most recent) --> case; instructions next to each other
    // 2'b10 = forward from MEM/WB (older) --> case; instructions offset by 1, data is in WB but hasn't been updated
    always @(*) begin
        // for rs1
        if (mem_reg_write && (mem_rd_addr != 4'b0) && (mem_rd_addr == ex_rs1_addr))
            forward_a = 2'b01;
        else if (wb_reg_write && (wb_rd_addr != 4'b0) && (wb_rd_addr == ex_rs1_addr))
            forward_a = 2'b10;
        else
            forward_a = 2'b00;
        
        // for rs2
        if (mem_reg_write && (mem_rd_addr != 4'b0) && (mem_rd_addr == ex_rs2_addr))
            forward_b = 2'b01;
        else if (wb_reg_write && (wb_rd_addr != 4'b0) && (wb_rd_addr == ex_rs2_addr))
            forward_b = 2'b10;
        else
            forward_b = 2'b00;
    end
endmodule;