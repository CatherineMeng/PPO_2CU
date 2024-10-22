module reluArray #(
	parameter dataWidth = 32,
    parameter pactivation= 16
)
(
	clk,
	rst,
	en,
	inputArray,
	outputArray
);

// define the inpit
input clk;
input rst;
input en;
input [dataWidth*pactivation -1:0] inputArray;

//define the output
output [dataWidth*pactivation -1:0] outputArray;

wire [dataWidth*pactivation -1:0] outputArray;


genvar i;
generate
	for(i = 0;i < pactivation; i = i+1) begin : singlerelu
		reluUnit #(.dataWidth(dataWidth)) reluUnitinstance
	    (
    		.clk(clk), // system clock 
    		.rst(rst),  // system rst
    		.en(en),
    		.z(inputArray[pactivation*(i+1) -1: pactivation*i]),  // input value Z
    		.a(outputArray[pactivation*(i+1) -1: pactivation*i])
    	); // output activation A

	end
endgenerate

endmodule

module reluDervArray #(
	parameter dataWidth = 32,
    parameter pactivation= 16
)
(
	clk,
	rst,
	en,
	inputArray,
	outputArray
);

// define the inpit
input clk;
input rst;
input en;
input [dataWidth*pactivation -1:0] inputArray;

//define the output
output [dataWidth*pactivation -1:0] outputArray;

wire [dataWidth*pactivation -1:0] outputArray;


genvar i;
generate
	for(i = 0;i < pactivation; i = i+1) begin : singlerelu
		reluDervUnit #(.dataWidth(dataWidth)) reluDervUnitinstance
	    (
    		.clk(clk), // system clock 
    		.rst(rst),  // system rst
    		.en(en),
    		.z(inputArray[pactivation*(i+1) -1: pactivation*i]),  // input value Z
    		.a(outputArray[pactivation*(i+1) -1: pactivation*i])
    	); // output activation A

	end
endgenerate

endmodule