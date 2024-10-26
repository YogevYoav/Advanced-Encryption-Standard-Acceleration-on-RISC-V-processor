// --------------------------------------------------------
// Branch Control - RTL
// --------------------------------------------------------

module yarp_branch_control import yarp_pkg::*; (
  // Source operands
  input  logic [31:0] opr_a_i,
  input  logic [31:0] opr_b_i,

  // Branch Type
  input  logic        is_b_type_ctl_i,
  input  logic [2:0]  instr_func3_ctl_i,

  // Branch outcome
  output logic        branch_taken_o
);

// --------------------------------------------------------
// Internal signals
// --------------------------------------------------------
logic [31:0] twos_compl_a;
logic [31:0] twos_compl_b;

logic branch_taken;

// Calculate two's complement for signed operations
assign twos_compl_a = opr_a_i[31] ? ~opr_a_i + 32'h1 : opr_a_i;
assign twos_compl_b = opr_b_i[31] ? ~opr_b_i + 32'h1 : opr_b_i;

// Branch condition logic based on funct3
always_comb begin
    case (instr_func3_ctl_i)
      BEQ     : branch_taken = (opr_a_i == opr_b_i);               // Branch if equal
      BNE     : branch_taken = (opr_a_i != opr_b_i);               // Branch if not equal
      BLT     : branch_taken = (twos_compl_a < twos_compl_b);      // Branch if less than (signed)
      BGE     : branch_taken = (twos_compl_a >= twos_compl_b);     // Branch if greater or equal (signed)
      BLTU    : branch_taken = (opr_a_i < opr_b_i);                // Branch if less than (unsigned)
      BGEU    : branch_taken = (opr_a_i >= opr_b_i);               // Branch if greater or equal (unsigned)
      default : branch_taken = 1'b0;                               // Default: no branch
    endcase
end

// Final branch decision: only if it's a branch-type instruction
assign branch_taken_o = is_b_type_ctl_i & branch_taken;

endmodule
