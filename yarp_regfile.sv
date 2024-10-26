// --------------------------------------------------------
// Register File - RTL
// --------------------------------------------------------

module yarp_regfile (
  input   logic          clk,
  input   logic          reset_n,

  // Source registers
  input   logic [4:0]    rs1_addr_i,  // Address of source register 1
  input   logic [4:0]    rs2_addr_i,  // Address of source register 2

  // Destination register
  input   logic [4:0]    rd_addr_i,   // Address of destination register
  input   logic          wr_en_i,     // Write enable signal
  input   logic [31:0]   wr_data_i,   // Data to write to destination register

  // Register Data
  output  logic [31:0]   rs1_data_o,  // Data from source register 1
  output  logic [31:0]   rs2_data_o   // Data from source register 2
);

  // --------------------------------------------------------
  // Internal Wires and Registers
  // --------------------------------------------------------
  logic [31:0] regfile [31:0];  // Register file: 32 registers, each 32 bits wide

  // --------------------------------------------------------
  // Write logic for the register file
  // --------------------------------------------------------
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      regfile[0] <= 32'h0;  // X0 register is hardwired to 0 on reset
    end else if (wr_en_i && rd_addr_i != 5'b00000) begin
      regfile[rd_addr_i] <= wr_data_i;  // Write to the register if write enabled and not writing to X0
    end
  end

  // --------------------------------------------------------
  // Read logic for the register file
  // --------------------------------------------------------
  assign rs1_data_o = regfile[rs1_addr_i];  // Read data from source register 1
  assign rs2_data_o = regfile[rs2_addr_i];  // Read data from source register 2

endmodule
