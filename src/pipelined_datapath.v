/*
  * Opcode	Mnemonic	Type	Meaning
  * 0000	ADD	R	rd = rs1 + rs2
  * 0001	SUB	R	rd = rs1 - rs2
  * 0010	AND	R	rd = rs1 & rs2
  * 0011	OR	R	rd = rs1 | rs2
  * 0100	ADDI	I	rd = rs1 + imm
  * 0101	LW	I	rd = MEM[rs1 + imm]
  * 0110	SW	I	MEM[rs1 + imm] = rd
  * 0111	BEQ	I	if (rs1 == rd) PC += imm
* */

// IF --> ID --> EX --> MEM --> WB

module pipelined_datapath (
    input clk,
    input rst,
    output [31:0] dbg_wb_data,
    output [3:0] dbg_wb_rd_addr,
    output       dbg_wb_reg_write
); 
    // instruction fetch stage
    wire [31:0] pc_current, pc_plus4, pc_next_actual, branch_target;
    wire [31:0] if_instr;
    wire        stall;
    wire        ex_take_branch;

    assign pc_plus4 = pc_current + 32'd4;
    // next pc:
    // stall? --> current otw
    // ex_take_branch? --> jump to whatever branch is loaded, otw increment pc normally
    assign pc_next_actual = stall ? pc_current : (ex_take_branch ? branch_target : pc_plus4);

    pc pc_inst (
        .clk(clk), .rst(rst),
        .pc_next(pc_next_actual),
        .pc_out(pc_current)
    );

    // pc_current points somewhere in instruction memory
    // instr_mem fetches the 32-bit word there --> instruction
    instr_mem imem_inst (
        .addr(pc_current),
        .instr(if_instr)
    );

    // IF/ID phase
    wire [31:0] id_instr, id_pc;

    // holds the instruction fetched **1 cycle ago**
    if_id_reg if_id (
        .clk(clk), .rst(rst),
        .stall(stall), 
        .flush(ex_take_branch),
        .instr_in(if_instr), .pc_in(pc_current),
        .instr_out(id_instr), .pc_out(id_pc)
    );
    
    // id_instr
    // instruction layout: -- [31:28] -- [27:24] -- [23:20] --- [19:16] ---- [15:0]
    // dedicated bits:     --  opcode -- rd_addr -- rs1_addr -- rs2_addr -- free space 

    // ID stage
    wire [3:0]  id_rd_addr, id_rs1_addr, id_rs2_addr, id_rs2_addr_actual;
    wire [31:0] id_imm_extended;
    wire [2:0]  id_alu_op;
    wire        id_alu_src, id_reg_write, id_use_rd_as_rs2,
                id_mem_write, id_mem_to_reg, id_branch;
    wire [31:0] id_rs1_data, id_rs2_data;
    wire [31:0] wb_write_back_data;   // fed back from WB, declared early since regfile needs it
    wire [3:0]  wb_rd_addr;
    wire        wb_reg_write;

    assign id_rd_addr  = id_instr[27:24];
    assign id_rs1_addr = id_instr[23:20];
    assign id_rs2_addr = id_instr[19:16];
    assign id_rs2_addr_actual = id_use_rd_as_rs2 ? id_rd_addr : id_rs2_addr;
    assign id_imm_extended = { {12{id_instr[19]}}, id_instr[19:0] };

    control_unit ctrl_inst (
        .opcode(id_instr[31:28]),
        .alu_op(id_alu_op), .alu_src(id_alu_src), .reg_write(id_reg_write),
        .use_rd_as_rs2(id_use_rd_as_rs2), .mem_write(id_mem_write),
        .mem_to_reg(id_mem_to_reg), .branch(id_branch)
    );

    register_file reg_file_inst (
        .clk(clk),
        .rst(rst),
        .we(wb_reg_write),
        .rd_addr(wb_rd_addr), .rd_data(wb_write_back_data),
        .rs1_addr(id_rs1_addr), .rs1_data(id_rs1_data),
        .rs2_addr(id_rs2_addr_actual), .rs2_data(id_rs2_data)
    );

    // ID/EX 
    wire [2:0]  ex_alu_op;
    wire        ex_alu_src, ex_reg_write, ex_mem_write, ex_mem_to_reg, ex_branch;
    wire [31:0] ex_rs1_data, ex_rs2_data, ex_imm_extended, ex_pc;
    wire [3:0]  ex_rd_addr, ex_rs1_addr, ex_rs2_addr;

    // stall inserts a bubble into EX (flush), rather than freezing ID/EX
    // flush on ex_take_branch --> if branch condition is satisfied, whatever is in id-ex is incorrect, need to flush
    id_ex_reg id_ex (
        .clk(clk), .rst(rst), .stall(1'b0), .flush(stall || ex_take_branch),
        .alu_op_in(id_alu_op), .alu_src_in(id_alu_src),
        .reg_write_in(id_reg_write), .mem_write_in(id_mem_write),
        .mem_to_reg_in(id_mem_to_reg), .branch_in(id_branch),
        .rs1_data_in(id_rs1_data), .rs2_data_in(id_rs2_data),
        .imm_extended_in(id_imm_extended), .pc_in(id_pc),
        .rd_addr_in(id_rd_addr), .rs1_addr_in(id_rs1_addr), .rs2_addr_in(id_rs2_addr_actual),

        .alu_op_out(ex_alu_op), .alu_src_out(ex_alu_src),
        .reg_write_out(ex_reg_write), .mem_write_out(ex_mem_write),
        .mem_to_reg_out(ex_mem_to_reg), .branch_out(ex_branch),
        .rs1_data_out(ex_rs1_data), .rs2_data_out(ex_rs2_data),
        .imm_extended_out(ex_imm_extended), .pc_out(ex_pc),
        .rd_addr_out(ex_rd_addr), .rs1_addr_out(ex_rs1_addr), .rs2_addr_out(ex_rs2_addr)
    );
    
    wire [31:0] alu_rs1_in, alu_rs2_in;
    wire ex_alu_zero;

    wire [1:0] forward_a, forward_b;

    forwarding_unit fwd_unit(
        .ex_rs1_addr(ex_rs1_addr), .ex_rs2_addr(ex_rs2_addr),
        .mem_rd_addr(mem_rd_addr), .mem_reg_write(mem_reg_write),
        .wb_rd_addr(wb_rd_addr), .wb_reg_write(wb_reg_write),
        .forward_a(forward_a), .forward_b(forward_b) 
    );

    assign alu_rs1_in = (forward_a == 2'b01) ? mem_alu_result : 
                        (forward_a == 2'b10) ? wb_write_back_data : ex_rs1_data;

    assign alu_rs2_in = (forward_b == 2'b01) ? mem_alu_result : 
                        (forward_b == 2'b10) ? wb_write_back_data : ex_rs2_data;

    
    wire [31:0] ex_alu_b_in, ex_alu_result;
    assign ex_alu_b_in = ex_alu_src ? ex_imm_extended : alu_rs2_in;

    alu alu_inst (
        .rs1(alu_rs1_in), .rs2(ex_alu_b_in),
        .alu_op(ex_alu_op),
        .rd(ex_alu_result), .zero(ex_alu_zero)
    );
    
    assign branch_target = ex_pc + ex_imm_extended;
    assign ex_take_branch = ex_branch  && ex_alu_zero; // take branch if branch is possible, and zero flag (equality operation)

    // EX/MEM 
    wire [31:0] mem_alu_result, mem_rs2_data;
    wire [3:0]  mem_rd_addr;
    wire        mem_reg_write, mem_mem_write, mem_mem_to_reg;

    ex_mem_reg ex_mem (
        .clk(clk), .rst(rst), .stall(1'b0), .flush(1'b0),
        .alu_result_in(ex_alu_result), .rs2_data_in(ex_rs2_data),
        .rd_addr_in(ex_rd_addr),
        .reg_write_in(ex_reg_write), .mem_write_in(ex_mem_write),
        .mem_to_reg_in(ex_mem_to_reg),

        .alu_result_out(mem_alu_result), .rs2_data_out(mem_rs2_data),
        .rd_addr_out(mem_rd_addr),
        .reg_write_out(mem_reg_write), .mem_write_out(mem_mem_write),
        .mem_to_reg_out(mem_mem_to_reg)
    );

    //  MEM stage 
    wire [31:0] mem_read_data;

    data_memory data_memory_inst (
        .clk(clk), .rst(rst), .mem_write(mem_mem_write),
        .addr(mem_alu_result), .write_data(mem_rs2_data),
        .read_data(mem_read_data)
    );

    //  MEM/WB 
    wire [31:0] wb_alu_result, wb_mem_read_data;
    wire        wb_mem_to_reg;

    mem_wb_reg mem_wb (
        .clk(clk), .rst(rst), .stall(1'b0), .flush(1'b0),
        .alu_result_in(mem_alu_result), .mem_read_data_in(mem_read_data),
        .rd_addr_in(mem_rd_addr),
        .reg_write_in(mem_reg_write), .mem_to_reg_in(mem_mem_to_reg),

        .alu_result_out(wb_alu_result), .mem_read_data_out(wb_mem_read_data),
        .rd_addr_out(wb_rd_addr),
        .reg_write_out(wb_reg_write), .mem_to_reg_out(wb_mem_to_reg)
    );

    // WB stage 
    assign wb_write_back_data = wb_mem_to_reg ? wb_mem_read_data : wb_alu_result;

    //  Hazard detection 
    hazard_detect hazard_inst (
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr_actual(id_rs2_addr_actual),
        .ex_rd_addr(ex_rd_addr),
        .ex_mem_to_reg(ex_mem_to_reg),
        .stall(stall)
    );

    assign dbg_wb_data = wb_write_back_data;
    assign dbg_wb_rd_addr = wb_rd_addr;
    assign dbg_wb_reg_write = wb_reg_write;

endmodule
