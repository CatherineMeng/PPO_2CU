`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/26/2019 12:12:27 AM
// Design Name: 
// Module Name: bram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bram #(
	parameter dataWidth = 32,
    parameter memblocksize = 7424, //humanoid: 232*32 hopper:24*32
	parameter psys = 16)

	(
        clk,
        rst,
        enableA,
        enableB,
        writenableA,
        writenableB,
    //	din,
    //	dout,
    //	addr
        dataoutA,
        datainA,
        dataoutB,
        datainB,
        addressA,
        addressB

	);
    parameter addressWidth = $clog2(memblocksize/dataWidth);
    //parameter memorySize = addressWidth * dataWidth;
    
    input clk;
    input rst;
    input enableA;
    input enableB;
    input writenableA;
    input writenableB;
    
    input [dataWidth - 1:0] datainA;
    input [dataWidth - 1:0] datainB;
    input [addressWidth -1:0] addressA;
    input [addressWidth -1:0] addressB;
    output [dataWidth - 1:0]dataoutA;
    output [dataWidth - 1:0]dataoutB;

   xpm_memory_tdpram #(
      .ADDR_WIDTH_A(addressWidth),               // DECIMAL
      .ADDR_WIDTH_B(addressWidth),               // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(32),        // DECIMAL
      .BYTE_WRITE_WIDTH_B(32),        // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE("none"),      // String
      .MEMORY_INIT_PARAM("0"),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("auto"),      // String
      .MEMORY_SIZE(memblocksize),             // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_A(dataWidth),         // DECIMAL
      .READ_DATA_WIDTH_B(dataWidth),         // DECIMAL
      .READ_LATENCY_A(2),             // DECIMAL
      .READ_LATENCY_B(2),             // DECIMAL
      .READ_RESET_VALUE_A("0"),       // String
      .READ_RESET_VALUE_B("0"),       // String
      .RST_MODE_A("SYNC"),            // String
      .RST_MODE_B("SYNC"),            // String
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A(dataWidth),        // DECIMAL
      .WRITE_DATA_WIDTH_B(dataWidth),        // DECIMAL
      .WRITE_MODE_A("no_change"),     // String
      .WRITE_MODE_B("no_change")      // String
   )
   xpm_memory_tdpram_inst (
      .dbiterra(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .douta(dataoutA),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .doutb(dataoutB),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterra(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port A.

      .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(addressA),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .addrb(addressB),                   // ADDR_WIDTH_B-bit input: Address for port B write and read operations.
      .clka(clk),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(clk),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(datainA),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .dinb(datainB),                     // WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
      .ena(enableA),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .enb(enableA),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectdbiterrb(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterrb(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regcea(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rsta(rst),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .rstb(rst),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(writenableA),                       // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
                                       // data port dina. 1 bit wide when word-wide writes are used. In
                                       // byte-wide write configurations, each bit controls the writing one
                                       // byte of dina to address addra. For example, to synchronously write
                                       // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
                                       // 4'b0010.

      .web(writenableB)                        // WRITE_DATA_WIDTH_B-bit input: Write enable vector for port B input
                                       // data port dinb. 1 bit wide when word-wide writes are used. In
                                       // byte-wide write configurations, each bit controls the writing one
                                       // byte of dinb to address addrb. For example, to synchronously write
                                       // only bits [15-8] of dinb when WRITE_DATA_WIDTH_B is 32, web would be
                                       // 4'b0010.

   );

   // End of xpm_memory_tdpram_inst instantiation
				
			
endmodule
