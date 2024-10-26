module yarp_instr_mem (
  input    logic          clk,
  input    logic          reset_n,

  input    logic [31:0]   instr_mem_pc_i,      // PC input for instruction fetch

  // Output signals to request memory read
  output   logic          instr_mem_req_o,
  output   logic [31:0]   instr_mem_addr_o,
  
  // Input data from memory
  input    logic [31:0]   mem_rd_data_i,

  // Output instruction
  output   logic [31:0]   instr_mem_instr_o
);

  // --------------------------------------------------------
  // Internal signals
  // --------------------------------------------------------
  logic instr_mem_req_q;

  // --------------------------------------------------------
  // Instruction Memory Request Logic
  // --------------------------------------------------------

  // Assert memory request always after reset
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      instr_mem_req_q <= 1'b0;                // Deassert request on reset
    else
      instr_mem_req_q <= 1'b1;                // Always request instruction after reset
  end

  // Assigning the registered request signal to the output
  assign instr_mem_req_o = instr_mem_req_q;

  // --------------------------------------------------------
  // Address and Data Handling
  // --------------------------------------------------------

  // Pass PC to the memory address output
  assign instr_mem_addr_o = instr_mem_pc_i;

  // Pass memory read data to the output instruction
  assign instr_mem_instr_o = mem_rd_data_i;

endmodule
