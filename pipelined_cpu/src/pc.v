module pc (
    input clk,
    input rst,              // reset pc to 0
    input [31:0] pc_next,   // next pc value
    output [31:0] pc_out     // current pc value
);
    reg [31:0] pc_state;
    assign pc_out = pc_state;

    always @(posedge clk) begin
        if (rst)
            pc_state <= 32'b0;
        else
            pc_state <= pc_next;
    end
endmodule