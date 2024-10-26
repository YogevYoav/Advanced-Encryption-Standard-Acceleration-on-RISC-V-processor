// --------------------------------------------------------
// Execute - RTL
// --------------------------------------------------------

module yarp_execute import yarp_pkg::*; (
  // Source operands
  input   logic [31:0] opr_a_i,  // Operand A
  input   logic [31:0] opr_b_i,  // Operand B

  // ALU Operation
  input   logic [3:0]  op_sel_i, // ALU operation selector

  // ALU output
  output  logic [31:0] alu_res_o // ALU result
);

  // --------------------------------------------------------
  // Internal wires and regs
  // --------------------------------------------------------
  logic [31:0] twos_compl_a;  // Two's complement of operand A
  logic [31:0] twos_compl_b;  // Two's complement of operand B
  logic [31:0] alu_res;       // ALU result register

  // Generate two's complement for signed operations
  assign twos_compl_a = opr_a_i[31] ? ~opr_a_i + 32'h1 : opr_a_i;
  assign twos_compl_b = opr_b_i[31] ? ~opr_b_i + 32'h1 : opr_b_i;

  // --------------------------------------------------------
  // ALU operation logic
  // --------------------------------------------------------
  always_comb begin
    case (op_sel_i)
      OP_ADD  : alu_res = opr_a_i + opr_b_i;                          // Addition
      OP_SUB  : alu_res = opr_a_i - opr_b_i;                          // Subtraction
      OP_SLL  : alu_res = opr_a_i << opr_b_i[4:0];                    // Shift left logical
      OP_SRL  : alu_res = opr_a_i >> opr_b_i[4:0];                    // Shift right logical
      OP_SRA  : alu_res = $signed(opr_a_i) >>> opr_b_i[4:0];          // Shift right arithmetic
      OP_OR   : alu_res = opr_a_i | opr_b_i;                          // Bitwise OR
      OP_AND  : alu_res = opr_a_i & opr_b_i;                          // Bitwise AND
      OP_XOR  : alu_res = opr_a_i ^ opr_b_i;                          // Bitwise XOR
      OP_SLTU : alu_res = {31'h0, opr_a_i < opr_b_i};                 // Unsigned less than
      OP_SLT  : alu_res = {31'h0, twos_compl_a < twos_compl_b};       // Signed less than
      default : alu_res = 32'h0;                                      // Default case
    endcase
  end

  // Assign the ALU result to the output
  assign alu_res_o = alu_res;

endmodule
