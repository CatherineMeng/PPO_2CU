
module sysArray #(
	parameter dataWidth = 32,
	parameter SysDimension = 16
)
(
	clk, // define the input clock
	rst, // define the input reset
	enable,
	streamLength,
	weightArray, // define the input weight array
	layerArray, // define the input feature array //Feature Array
	outputArray // define the output feature array
);

//define the inpt
input clk;
input rst;
input enable;
input streamLength;
input [dataWidth*SysDimension - 1:0] weightArray;
input [dataWidth*SysDimension - 1:0] layerArray;
output [dataWidth*SysDimension - 1:0] outputArray;
reg [dataWidth*SysDimension - 1:0] outputArray;

wire [dataWidth*SysDimension - 1:0] weightWireArray[0:SysDimension - 1];
wire [dataWidth*SysDimension - 1:0] featureWireArray[0:SysDimension - 1];

wire [dataWidth*SysDimension - 1:0] resultWireArray[0:SysDimension - 1];


genvar i,j;
generate
	for (i = 0; i < SysDimension; i = i + 1) begin : rowUroll
		for (j = 0; j < SysDimension; j = j + 1) begin : columnUroll

			// define weight wire connection
			wire [dataWidth - 1:0] iweightwire;
			
			assign iweightwire = (j == 0) ? 
			  weightArray[(i + 1)*dataWidth - 1: i * dataWidth]
			: weightWireArray[j - 1][(i + 1)*dataWidth - 1: i * dataWidth];

			wire [dataWidth - 1:0] iweightwireOut;

			assign iweightwireOut = weightWireArray[j][(i + 1)*dataWidth  - 1: i * dataWidth];

			// define feature(layers) wire connection

			wire [dataWidth - 1:0] ilayerwire ;

			assign ilayerwire = (i == 0) ? 
			layerArray[(j + 1)*dataWidth - 1: j * dataWidth]: 
			featureWireArray[i - 1][(j + 1)*dataWidth - 1: j * dataWidth];

			wire [dataWidth - 1:0] ilayerwireOut;

			assign ilayerwireOut = featureWireArray[i][(j + 1)*dataWidth - 1: j * dataWidth];

			// define the result wire connection

			wire [dataWidth - 1:0] iresultIn;

			assign iresultIn = (i == 0)? 0:  
			resultWireArray[i - 1][(j + 1)*dataWidth - 1: j * dataWidth];

			wire [dataWidth - 1:0] iresultOut;

			assign iresultOut = resultWireArray[i][(j + 1)*dataWidth - 1: j * dataWidth];

			

			pe #(
   	 			.dataWidth(dataWidth),
    			.RowIndex(i),
    			.ColumnIndex(j),
    			.SysDimension(SysDimension)
			) singlePE
			(
				.clk(clk),                    // input clock
				.rst(rst),                    // input reset
				.enable(enable),			  // input enable	
				.streamLength(streamLength),  // length of input stream (common layer size)
				.weight(iweightwire),         // input weight
				.layerIn(ilayerwire),     // input feature
				.resultIn(iresultIn),        // input previous result
				.weightPass(iweightwireOut),
				.layerPass(ilayerwireOut),// output feature
				.resultOut(iresultOut)      // output result 
				
			);

		end
	end
endgenerate


always @(posedge clk or negedge rst) begin : proc_outputArray
 	if(~rst) begin
 		outputArray <= 0;
 	end else begin
 		outputArray <= resultWireArray[SysDimension - 1];
 	end
 end 

endmodule