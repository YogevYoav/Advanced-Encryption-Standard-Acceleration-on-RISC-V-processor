// --------------------------------------------------------
// YARP Top - RTL
// --------------------------------------------------------

module yarp_top import yarp_pkg::*; #(
  parameter RESET_PC = 32'h0000
)(
  input   logic          clk,
  input   logic          reset_n,

  // Instruction memory interface
  output  logic          instr_mem_req_o,
  output  logic [31:0]   instr_mem_addr_o,
  input   logic [31:0]   instr_mem_rd_data_i,

  // Data memory interface
  output  logic          data_mem_req_o,
  output  logic [31:0]   data_mem_addr_o,
  output  logic [1:0]    data_mem_byte_en_o,
  output  logic          data_mem_wr_o,
  output  logic [31:0]   data_mem_wr_data_o,
  input   logic [31:0]   data_mem_rd_data_i
);

  // --------------------------------------------------------
  // Internal signals
  // --------------------------------------------------------
  logic [31:0]  instr;
  logic [4:0]   rs1, rs2, rd;
  logic [31:0]  rs1_data, rs2_data, wr_data;
  logic [31:0]  alu_opr_a, alu_opr_b;
  logic [31:0]  mem_rd_data;
  logic [31:0]  next_seq_pc, next_pc;
  logic [31:0]  pc_q;
  logic [6:0]   opcode;
  logic [2:0]   funct3;
  logic [6:0]   funct7;
  logic         r_type, i_type, s_type, b_type, u_type, j_type;
  logic [31:0]  imm;
  logic [3:0]   alu_func;
  logic [31:0]  alu_res;
  logic         pc_sel, op1_sel, op2_sel, data_req, data_wr;
  logic [1:0]   data_byte, rf_wr_data_sel;
  logic         rf_wr_en, zero_extnd, branch_taken;
  logic         reset_seen_q;

  `ifdef YARP_VAL
    logic [31:0] [31:0] regfile;
    assign regfile = u_yarp_regfile.regfile;
  `endif

  // --------------------------------------------------------
  // Main logic
  // --------------------------------------------------------
  // Capture reset state
  always_ff @ (posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_seen_q <= 1'b0;
    end else begin
      reset_seen_q <= 1'b1;
    end
  end

  // Program Counter (PC) logic
  assign next_seq_pc = pc_q + 32'h4;
  assign next_pc = (branch_taken | pc_sel) ? {alu_res[31:1], 1'b0} : next_seq_pc;

  always_ff @ (posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      pc_q <= RESET_PC;
    end else if (reset_seen_q) begin
      pc_q <= next_pc;
    end
  end
  
  // --------------------------------------------------------
  // Instruction Memory
  // --------------------------------------------------------
  yarp_instr_mem u_yarp_instr_mem (
    .clk               (clk),
    .reset_n           (reset_n),
    .instr_mem_pc_i    (pc_q),
    .instr_mem_req_o   (instr_mem_req_o),
    .instr_mem_addr_o  (instr_mem_addr_o),
    .mem_rd_data_i     (instr_mem_rd_data_i),
    .instr_mem_instr_o (instr)
  );
  
  // --------------------------------------------------------
  // Instruction Decode
  // --------------------------------------------------------
  yarp_decode u_yarp_decode (
    .instr_i        (instr),
    .rs1_o          (rs1),
    .rs2_o          (rs2),
    .rd_o           (rd),
    .op_o           (opcode),
    .funct3_o       (funct3),
    .funct7_o       (funct7),
    .r_type_instr_o (r_type),
    .i_type_instr_o (i_type),
    .s_type_instr_o (s_type),
    .b_type_instr_o (b_type),
    .u_type_instr_o (u_type),
    .j_type_instr_o (j_type),
    .instr_imm_o    (imm)
  );
  
  // --------------------------------------------------------
  // Register File
  // --------------------------------------------------------
  // Register File write data
  assign wr_data = (rf_wr_data_sel == ALU) ? alu_res :
                   (rf_wr_data_sel == MEM) ? mem_rd_data :
                   (rf_wr_data_sel == IMM) ? imm :
                                             next_seq_pc;
  yarp_regfile u_yarp_regfile (
    .clk           (clk),
    .reset_n       (reset_n),
    .rs1_addr_i    (rs1),
    .rs2_addr_i    (rs2),
    .rd_addr_i     (rd),
    .wr_en_i       (rf_wr_en),
    .wr_data_i     (wr_data),
    .rs1_data_o    (rs1_data),
    .rs2_data_o    (rs2_data)
  );
  
  // --------------------------------------------------------
  // Control Unit
  // --------------------------------------------------------
  yarp_control u_yarp_control (
    .instr_funct3_i      (funct3),
    .instr_funct7_bit5_i (funct7[5]),
    .instr_opcode_i      (opcode),
    .is_r_type_i         (r_type),
    .is_i_type_i         (i_type),
    .is_s_type_i         (s_type),
    .is_b_type_i         (b_type),
    .is_u_type_i         (u_type),
    .is_j_type_i         (j_type),
    .pc_sel_o            (pc_sel),
    .op1sel_o            (op1_sel),
    .op2sel_o            (op2_sel),
    .data_req_o          (data_req),
    .data_wr_o           (data_wr),
    .data_byte_o         (data_byte),
    .zero_extnd_o        (zero_extnd),
    .rf_wr_en_o          (rf_wr_en),
    .rf_wr_data_o        (rf_wr_data_sel),
    .alu_func_o          (alu_func)
  );
  
  // --------------------------------------------------------
  // Branch Control
  // --------------------------------------------------------
  yarp_branch_control u_yarp_branch_control (
    .opr_a_i             (rs1_data),
    .opr_b_i             (rs2_data),
    .is_b_type_ctl_i     (b_type),
    .instr_func3_ctl_i   (funct3),
    .branch_taken_o      (branch_taken)
  );
  
  // --------------------------------------------------------
  // Execute Unit
  // --------------------------------------------------------
  // ALU operand mux
  assign alu_opr_a = op1_sel ? pc_q : rs1_data;
  assign alu_opr_b = op2_sel ? imm : rs2_data;

  yarp_execute u_yarp_execute (
    .opr_a_i    (alu_opr_a),
    .opr_b_i    (alu_opr_b),
    .op_sel_i   (alu_func),
    .alu_res_o  (alu_res)
  );

  // --------------------------------------------------------
  // Data Memory
  // --------------------------------------------------------
  yarp_data_mem u_yarp_data_mem (
    .clk                 (clk),
    .reset_n             (reset_n),
    .data_req_i          (data_req),
    .data_addr_i         (alu_res),
    .data_byte_en_i      (data_byte),
    .data_wr_i           (data_wr),
    .data_wr_data_i      (rs2_data),
    .data_zero_extnd_i   (zero_extnd),
    .data_mem_req_o      (data_mem_req_o),
    .data_mem_addr_o     (data_mem_addr_o),
    .data_mem_byte_en_o  (data_mem_byte_en_o),
    .data_mem_wr_o       (data_mem_wr_o),
    .data_mem_wr_data_o  (data_mem_wr_data_o),
    .mem_rd_data_i       (data_mem_rd_data_i),
    .data_mem_rd_data_o  (mem_rd_data)
  );

endmodule
