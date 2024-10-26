module test_bench();
  logic clk;
  logic reset_n;

  // Instruction memory signals
  logic instr_mem_req_o;
  logic [31:0] instr_mem_addr_o;
  logic [31:0] instr_mem_rd_data_i;

  // Data memory signals
  logic data_mem_req_o;
  logic [31:0] data_mem_addr_o;
  logic [1:0] data_mem_byte_en_o;
  logic data_mem_wr_o;
  logic [31:0] data_mem_wr_data_o;
  logic [31:0] data_mem_rd_data_i;

  // Simulated instruction memory (array)
  reg [31:0] instr_mem [0:2047];  //2047x32-bit instruction memory
  // simulated instruction byte memory (array)
  reg [7:0] byte_mem [0:8191];
  
  
  
 // reg [31:0] data_mem [0:8192];  // 1024x32-bit instruction memory

  // Clock generation
  always #5 clk = ~clk;  // Clock with a period of 10 time units

  // Instantiate the yarp_top module
  yarp_top #(.RESET_PC(32'h0000)) uut (
    .clk(clk),
    .reset_n(reset_n),
    .instr_mem_req_o(instr_mem_req_o),
    .instr_mem_addr_o(instr_mem_addr_o),
    .instr_mem_rd_data_i(instr_mem_rd_data_i),
    .data_mem_req_o(data_mem_req_o),
    .data_mem_addr_o(data_mem_addr_o),
    .data_mem_byte_en_o(data_mem_byte_en_o),
    .data_mem_wr_o(data_mem_wr_o),
    .data_mem_wr_data_o(data_mem_wr_data_o),
    .data_mem_rd_data_i(data_mem_rd_data_i)
  );

integer i;

  // Testbench initialization
  initial begin
    // Initialize signals
    clk = 0;
    reset_n = 0;
    data_mem_rd_data_i = 32'h0;

    // Load instruction memory from a file or manually
    $readmemh("machine_code.mem", instr_mem);  // Load machine code file  // Load instructions from file into instruction memory array
	

    // Split each 32-bit instruction into 4 bytes and store them in the 8-bit memory
    for (i = 0; i < 2048; i = i + 1) begin
        byte_mem[i*4+3]     = instr_mem[i][7:0];    // First byte (most significant)
        byte_mem[i*4+2]   = instr_mem[i][15:8];   // Second byte
        byte_mem[i*4+1]   = instr_mem[i][23:16];  // Third byte
        byte_mem[i*4]   = instr_mem[i][31:24];  // Fourth byte (least significant)
    end



    // Apply reset (active-low)
    #10 reset_n = 1;  // Deassert reset after 10 time units

    // Simulate for 1000 time units and finish
    #1000 $finish;
  end

  // Instruction memory read logic
  always_comb begin
    if (instr_mem_req_o) begin
      // Read instruction from simulated instruction memory based on address
      instr_mem_rd_data_i = {byte_mem[instr_mem_addr_o],byte_mem[instr_mem_addr_o+1],byte_mem[instr_mem_addr_o+2],byte_mem[instr_mem_addr_o+3]};  // Instruction memory is word-aligned
    end else begin
      instr_mem_rd_data_i = 32'h0;
    end
  end

 /*// Data memory read logic
  always_comb begin
    if (instr_mem_req_o) begin
      // Read instruction from simulated instruction memory based on address
      instr_mem_rd_data_i = instr_mem[instr_mem_addr_o];  // Instruction memory is word-aligned
    end else begin
      instr_mem_rd_data_i = 32'h0;
    end
  end*/



endmodule

