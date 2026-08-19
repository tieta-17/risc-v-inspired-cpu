// instruction fetch, instruction decode register
// carries what fetch produced into decode phase
module if_id_reg (
    input           clk,
    input           rst,
    input           stall,          // hazard detected; freeze register from moving
    input           flush,          // clear register; branch taken --> discard fetched instruction
    input   [31:0]  instr_in,       // instruction_in
    input   [31:0]  pc_in,
    output reg [31:0] instr_out,
    output reg [31:0] pc_out
);
    always @(posedge clk) begin
        if (rst || flush) begin
            instr_out <= 32'b0;
            pc_out <= 32'b0;
        end else if (!stall) begin
            instr_out <= instr_in;
            pc_out <= pc_in;
        end
    end
endmodule