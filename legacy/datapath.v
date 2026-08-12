module datapath(
    input clk,
    input rst
);
    // program counter wires
    wire [31:0] pc_current; 
    wire [31:0] pc_plus4;
    wire [31:0] instruction;

    // register file wires
    wire [3:0]  rd_addr, rs1_addr, rs2_addr;
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] imm_extended;

    // alu wires
    wire [31:0] alu_b_in;
    wire [31:0] alu_result;
    wire        alu_zero;
    
    // control unit wires
    wire [2:0] alu_op;
    wire       alu_src, reg_write, use_rd_as_rs2, mem_write, mem_to_reg, branch;

    wire [31:0] branch_target;
    wire take_branch;
    wire [31:0] pc_next_actual;

    assign branch_target = pc_current + imm_extended;
    assign take_branch = branch && alu_zero; // BEQ --> branch = 1; Zero comparison --> 1; VALID BRANCH
    assign pc_next_actual = take_branch ? branch_target : pc_plus4;

    // data memory wires
    wire [31:0] mem_read_data;
    wire [31:0] write_back_data;

    // [31:28]=opcode, [27:24]=rd_addr, [23:20]=rs1_addr, [19:16]=rs2_addr, [19:0]=imm for I-type)
    assign rd_addr = instruction[27:24];
    assign rs1_addr = instruction[23:20];
    assign rs2_addr = instruction[19:16];

    wire [3:0] rs2_addr_actual;
    assign rs2_addr_actual = use_rd_as_rs2 ? rd_addr : rs2_addr;

    // immediate value sign extension
    assign imm_extended = { {12{instruction[19]}}, instruction[19:0]}; //12 of MSB concatenated to 20 bits

    control_unit ctrl_inst (
        .opcode(instruction[31:28]),    // input: opcode
        .alu_op(alu_op),                // output: ALU opcode --> what ALU does
        .alu_src(alu_src),              // output: ALU src (0: rs2, 1: imm)
        .reg_write(reg_write),          // output: write alu to registers (0: no, 1: yes)
        .use_rd_as_rs2(use_rd_as_rs2),  // output: read from register position (0: rs2 field, 1: rd field)
        .mem_write(mem_write),          // output: write to memory (Store Word) (0: no, 1: yes)
        .mem_to_reg(mem_to_reg),        // output: write back source (Load Word) (0: ALU, 1: data_memory read_data)
        .branch(branch)                 // output: possible to jump? (0: no, 1: yes)
    );

    // fetch stage
    pc pc_inst (                        // pc_out holds instruction being executed THIS cycle
        .clk(clk),                      // input: clock cycle
        .rst(rst),                      // input: reset pc
        .pc_next(pc_next_actual),       // input: next pc instruction
        .pc_out(pc_current)             // output: current pc instruction
    );

    instr_mem imem_inst (
        .addr(pc_current),              // input: addr of current PC
        .instr(instruction)             // output:  instruction at PC
    );

    // execution phase
    register_file reg_file_inst (
        .clk(clk),                      // input: clock cycle
        .we(reg_write),                 // input: write enable
        .rd_addr(rd_addr),              // input: destination register
        .rd_data(write_back_data),      // input: data to write to rd
        .rs1_addr(rs1_addr),            // input: source register 1
        .rs2_addr(rs2_addr_actual),     // input: source register 2
        .rs1_data(rs1_data),            // output: data register 1
        .rs2_data(rs2_data)             // output: data register 2
    );

    // alu_src --> 0 = use rs2_data, 1 = use immediate
    assign alu_b_in = alu_src ? imm_extended : rs2_data;   

    alu alu_inst (
        .rs1(rs1_data),                 // input: data from source register 1
        .rs2(alu_b_in),                 // input: data from either source register 2 or immediate
        .alu_op(alu_op),                // input: ALU operation to compute
        .rd(alu_result),                // output: result from ALU operation
        .zero(alu_zero)                 // output: zero_flag
    );

    data_memory data_memory_inst (
        .clk(clk),                      // input: clock cycle
        .mem_write(mem_write),          // input: write to memory (Store Word) (0: no, 1: yes)
        .addr(alu_result),              // input: address to write to (rs1 + immediate)
        .write_data(rs2_data),          // input: data to write (source register 2 is default dest register UNLESS opcode ) 
        .read_data(mem_read_data)       // output: loaded value
    );

    assign write_back_data = mem_to_reg ? mem_read_data : alu_result; // if mem_to_reg, opcode 5 --> load word fr memory, otw alu result
    assign pc_plus4 = pc_current + 32'd4; // increment pc normally
endmodule