module hazard_detect (
    input [3:0] id_rs1_addr,
    input [3:0] id_rs2_addr_actual,
    input [3:0] ex_rd_addr,
    input ex_mem_to_reg,
    output stall
); 
    assign stall = ex_mem_to_reg &&
                    (ex_rd_addr != 4'b0) && 
                    ((ex_rd_addr == id_rs1_addr) || 
                     (ex_rd_addr == id_rs2_addr_actual));
    // stall if the instruction ahead in the pipeline is 
    // loading a value from memory, and the register it's 
    // loading the value into is about to read from
endmodule