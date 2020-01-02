module wu #(
	parameter dataWidth = 32,
    parameter pactivation= 16
)
(
	clk,
	rst,
	en,
	inputArrayA,
	inputArrayB,
	outputArray
);

// define the inpit
input clk;
input rst;
input en;
input [dataWidth*pactivation -1:0] inputArrayA;
input [dataWidth*pactivation -1:0] inputArrayB;

//define the output
output [dataWidth*pactivation -1:0] outputArray;

wire [dataWidth*pactivation -1:0] outputArray;


genvar i;
generate
	for(i = 0;i < pactivation; i = i+1) begin : singlesub
		// reluUnit #(.dataWidth(dataWidth)) reluUnitinstance
	 //    (
  //   		.clk(clk), // system clock 
  //   		.rst(rst),  // system rst
  //   		.z(inputArray[pactivation*(i+1) -1: pactivation*i]),  // input value Z
  //   		.a(outputArray[pactivation*(i+1) -1: pactivation*i])
  //   	); // output activation A
		floating_point_sub singlesub (
		  .aclk(aclk),                                  // input wire aclk
		  .s_axis_a_tvalid(en),            // input wire s_axis_a_tvalid
		  .s_axis_a_tdata(inputArrayA[pactivation*(i+1) -1: pactivation*i]),              // input wire [31 : 0] s_axis_a_tdata
		  .s_axis_b_tvalid(en),            // input wire s_axis_b_tvalid
		  .s_axis_b_tdata(inputArrayB[pactivation*(i+1) -1: pactivation*i]),              // input wire [31 : 0] s_axis_b_tdata
		  .m_axis_result_tvalid(1'b1),  // output wire m_axis_result_tvalid
		  .m_axis_result_tdata(outputArray[pactivation*(i+1) -1: pactivation*i])    // output wire [31 : 0] m_axis_result_tdata
		);
	end
endgenerate

endmodule