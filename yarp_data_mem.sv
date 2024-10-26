// --------------------------------------------------------
// Data Memory - RTL
// --------------------------------------------------------

module yarp_data_mem import yarp_pkg::*; (
  input   logic           clk,
  input   logic           reset_n,

  // Data request from current instruction
  input   logic           data_req_i,           // Data request signal
  input   logic [31:0]    data_addr_i,          // Address for data memory
  input   logic [1:0]     data_byte_en_i,       // Data byte enable signal (BYTE, HALF_WORD, WORD)
  input   logic           data_wr_i,            // Write enable signal
  input   logic [31:0]    data_wr_data_i,       // Data to write into memory

  input   logic           data_zero_extnd_i,    // Signal for zero extension

  // Read/Write request to memory
  output  logic           data_mem_req_o,       // Memory request output signal
  output  logic  [31:0]   data_mem_addr_o,      // Memory address output
  output  logic  [1:0]    data_mem_byte_en_o,   // Byte enable signal for memory
  output  logic           data_mem_wr_o,        // Memory write enable signal
  output  logic  [31:0]	  data_mem_wr_data_o,   // Data to write into memory

  // Read data from memory
  input   logic [31:0]    mem_rd_data_i,        // Data read from memory

  // Data output
  output  logic [31:0]    data_mem_rd_data_o    // Processed data output
);

  // --------------------------------------------------------
  // Internal signals
  // --------------------------------------------------------
  logic [31:0] rd_data_sign_extnd;   // Sign-extended data
  logic [31:0] rd_data_zero_extnd;   // Zero-extended data
  logic [31:0] data_mem_rd_data;     // Final data after extension selection

  // --------------------------------------------------------
  // Sign Extension Logic
  // --------------------------------------------------------
  assign rd_data_sign_extnd = (data_byte_en_i == HALF_WORD) ? {{16{mem_rd_data_i[15]}}, mem_rd_data_i[15:0]}  :
                              (data_byte_en_i == BYTE)      ? {{24{mem_rd_data_i[7]}},  mem_rd_data_i[7:0]}   :
                                                             mem_rd_data_i;

  // --------------------------------------------------------
  // Zero Extension Logic
  // --------------------------------------------------------
  assign rd_data_zero_extnd = (data_byte_en_i == HALF_WORD) ? {{16{1'b0}}, mem_rd_data_i[15:0]}  :
                              (data_byte_en_i == BYTE)      ? {{24{1'b0}}, mem_rd_data_i[7:0]}   :
                                                             mem_rd_data_i;

  // --------------------------------------------------------
  // Mux between zero or sign extended data
  // --------------------------------------------------------
  assign data_mem_rd_data = data_zero_extnd_i ? rd_data_zero_extnd : rd_data_sign_extnd;

  // --------------------------------------------------------
  // Output assignments
  // --------------------------------------------------------
  assign data_mem_req_o     = data_req_i;        // Pass request signal
  assign data_mem_addr_o    = data_addr_i;       // Pass memory address
  assign data_mem_byte_en_o = data_byte_en_i;    // Pass byte enable signal
  assign data_mem_wr_o      = data_wr_i;         // Pass write enable signal
  assign data_mem_wr_data_o = data_wr_data_i;    // Pass data to write into memory
  assign data_mem_rd_data_o = data_mem_rd_data;  // Pass final read data after extension

endmodule
