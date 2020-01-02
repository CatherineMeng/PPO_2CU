
module cus #(
	parameter dataWidth = 32,
	parameter memblocksizeWeight = 7424, //when have two sys, remember to *2
	parameter memblocksizeal = 47104,
	parameter memsizedeltalzl = 9584640,
	parameter SysDimension = 16
)
(
	clk, // define the input clock
	rst, // define the input reset
	enable,
	streamLength,
	weightWriteEnableA,
	weightWriteEnableB,
	sel1,
	sel2,
	enact,
	enactd,
	enwu

);

//define the inpt
input clk;
input rst;
input enable;
input streamLength;
input weightWriteEnableA;
input weightWriteEnableB;
input sel1, sel2;
input enact,enactd,enwu;

//=================systolic Array=======================
wire [dataWidth*SysDimension - 1:0] weightBufferTosysArray;
wire [dataWidth*SysDimension - 1:0] sysarrayIn;
wire [dataWidth*SysDimension - 1:0] sysDataOut;

//wire [dataWidth*SysDimension - 1:0] weightBufferTosysArray_value;
//wire [dataWidth*SysDimension - 1:0] sysarrayIn_value;
//wire [dataWidth*SysDimension - 1:0] sysDataOut_value;

//=================Activation and Activation Derivative=======================
//wire [dataWidth*SysDimension - 1:0] reluIn;  ==> zlout
wire [dataWidth*SysDimension - 1:0] reluOut;
//wire [dataWidth*SysDimension - 1:0] reluDervIn; ==>zlout
wire [dataWidth*SysDimension - 1:0] reluDervOut;

//=================Weight Update: WU=======================
wire [dataWidth*SysDimension - 1:0] wuInA;
//wire [dataWidth*SysDimension - 1:0] wuInB; //=sysDataOut
wire [dataWidth*SysDimension - 1:0] wuOut;


//=================Multiplexers=======================
wire [dataWidth*SysDimension - 1:0] mux1inf;
wire [dataWidth*SysDimension - 1:0] mux1fw;
wire [dataWidth*SysDimension - 1:0] mux1bw;//choose -> weightbuffertosysarray
//wire [dataWidth*SysDimension - 1:0] mux1wu; //==> dlout/

wire [dataWidth*SysDimension - 1:0] mux2inf;
wire [dataWidth*SysDimension - 1:0] mux2fw;
//wire [dataWidth*SysDimension - 1:0] mux2bw; ==>dlout
wire [dataWidth*SysDimension - 1:0] mux2wu; //choose -> sysarrayin

parameter weightBufferAddressWidth = $clog2(memblocksizeWeight/dataWidth);
reg[weightBufferAddressWidth - 1:0] WeightAddr; //one for policy, one for value

parameter alBufferAddressWidth = $clog2(memblocksizeal/dataWidth);
reg[alBufferAddressWidth - 1:0] alAddrA;
reg[alBufferAddressWidth - 1:0] alAddrB;

parameter dlBufferAddressWidth = $clog2(memsizedeltalzl/dataWidth);
reg[dlBufferAddressWidth - 1:0] dlAddrA;
reg[dlBufferAddressWidth - 1:0] dlAddrB;

parameter zlBufferAddressWidth = $clog2(memsizedeltalzl/(dataWidth*SysDimension));
reg[zlBufferAddressWidth - 1:0] zlAddrA;
reg[zlBufferAddressWidth - 1:0] zlAddrB;

genvar i, j;

//=================Weight buffer: dataout, datain=======================
wire [dataWidth-1:0] dataoutwire[SysDimension-1:0][SysDimension-1:0];
wire [dataWidth-1:0] tempinf[SysDimension-1:0][SysDimension-1:0];
wire [dataWidth-1:0] tempwu[SysDimension-1:0][SysDimension-1:0];
wire [dataWidth-1:0] tempbw[SysDimension-1:0][SysDimension-1:0];

wire [dataWidth-1:0] datainwire[SysDimension-1:0][SysDimension-1:0];
wire [dataWidth-1:0] temp1[SysDimension-1:0][SysDimension-1:0]; //datain, big buffer for input to weight buffer

//=================al buffer: dataout, datain=======================
wire [dataWidth-1:0] dataoutwireal[SysDimension-1:0][SysDimension-1:0];
wire [dataWidth-1:0] tempinfal[SysDimension-1:0][SysDimension-1:0];
wire [dataWidth-1:0] tempfwal[SysDimension-1:0][SysDimension-1:0];
wire [dataWidth-1:0] tempwual[SysDimension-1:0][SysDimension-1:0];

wire [dataWidth-1:0] datainwireal[SysDimension-1:0][SysDimension-1:0];
wire [dataWidth-1:0] tempinfinal[SysDimension-1:0][SysDimension-1:0]; //datain - inf, big buffer for input to al buffer

//=================zl and dl buffers=======================
wire [dataWidth*SysDimension - 1:0] zlout;
wire [dataWidth*SysDimension - 1:0] dlin;
wire [dataWidth*SysDimension - 1:0] dlout;


generate
	for(i = 0;i < SysDimension; i = i + 1) begin : rowUroll
		for(j = 0; j < SysDimension; j = j + 1) begin : columnUroll
	
	           //=============make weight buffer====================
	          //data out and in wire to systolic array, none-transpose
		      if ( i==0 ) begin: and_weightinout_inf_wu
		          assign mux1inf[(j+1)*dataWidth-1:j*dataWidth] = tempinf[SysDimension - 1][j];
		          assign wuInA[(j+1)*dataWidth-1:j*dataWidth] = tempwu[SysDimension - 1][j];
		          assign tempinf[i][j] = dataoutwire[i][j];
		          assign tempwu[i][j] = dataoutwire[i][j];
		          assign wuOut[(j+1)*dataWidth-1:j*dataWidth] = temp1[SysDimension - 1][j]; //input to weight buffer
		          assign temp1[i][j] = datainwire[i][j];
		      end
		      else begin: and_weightinout2_inf_wu
		          assign tempinf[i][j] = tempinf[i - 1][j] & dataoutwire[i][j];
		          assign tempwu[i][j] = tempwu[i - 1][j] & dataoutwire[i][j];
		          assign temp1[i][j] = temp1[i - 1][j] & datainwire[i ][j];
		      end
		      //data out to systolic array, transpose (bw)
		      if(j==0) begin: and_weightout_bw
		          assign mux1bw[(i+1)*dataWidth-1:i*dataWidth] = tempbw[i][SysDimension - 1]; //T
		          assign tempbw[i][j] = dataoutwire[i][j]; //T
		      end
		      else begin: and_weightout2_bw
		          assign tempbw[i][j] = tempbw[i][j-1] & dataoutwire[i][j]; //T
		      end
		      		    
			bram #(.dataWidth(dataWidth),
		    .memblocksize(memblocksizeWeight), 
			.psys(SysDimension)) weightbuffer
			(
		        .clk(clk),
		        .rst(rst),
		        .enableA(enable),
		        .enableB(1'b0),
		        .writenableA(weightWriteEnableA),
		        .writenableB(weightWriteEnableB),
		        .dataoutA( dataoutwire[i][j]),
		        .datainA(datainwire[i][j]), ///
		        .dataoutB(),
		        .datainB(32'b0),
		        .addressA(WeightAddr),//random, cahnge to weightaddr ;ater =======================================
		        .addressB(32'b0)
			);
			
			
	           //=============make al buffer====================
	          //data out to systolic array, transpose
		      if ( i==0 ) begin: and_alout_wu
		          assign mux2wu[(j+1)*dataWidth-1:j*dataWidth] = tempwual[SysDimension - 1][j]; //T
		          assign tempwual[i][j] = dataoutwireal[i][j]; //T
		      end
		      else begin: and_alout2_wu
		          assign tempwual[i][j] = tempwual[i - 1][j] & dataoutwireal[i][j]; //T
		      end
		      //data in and out to systolic array, non-transpose (infin,infout)
		      if(j==0) begin: and_alinout_inf
		          assign mux2inf[(i+1)*dataWidth-1:i*dataWidth] = tempinfal[i][SysDimension - 1]; 
		          assign mux2fw[(i+1)*dataWidth-1:i*dataWidth] = tempfwal[i][SysDimension - 1]; 
		          assign tempinfal[i][j] = dataoutwireal[i][j]; 
		          assign tempfwal[i][j] = dataoutwireal[i][j];
		          assign reluOut[(j+1)*dataWidth-1:j*dataWidth] = tempinfinal[SysDimension - 1][j];
		          assign tempinfinal[i][j] = datainwireal[i][j];
		           
		      end
		      else begin: and_alinout2_inf
		          assign tempbw[i][j] = tempbw[i][j-1] & dataoutwireal[i][j]; 
		      end
		      		    
			dpram #(.dataWidth(dataWidth),
		    .memblocksize(memblocksizeal), 
			.psys(SysDimension)) albuffer
			(
                .clk(clk),
                .rst(rst),
                .enableA(enable),
                .enableB(enable),
                .writenableA(enable),
                .datainA(datainwireal[i][j]),
                .dataoutB(dataoutwireal[i][j]),
                .addressA(alAddrA), //random, cahnge to weightaddr later =======================================
                .addressB(alAddrB) //random, cahnge to weightaddr later =======================================
			);
		end
	end
endgenerate

sysArray #(
	.dataWidth(dataWidth),
	.SysDimension(SysDimension)
) Policysys
(
	.clk(clk), // define the input clock
	.rst(rst), // define the input reset
	.enable(enable),
	.streamLength(streamLength),
	.weightArray(weightBufferTosysArray), // define the input weight array
	.layerArray(sysarrayIn), // define the input feature array //Feature Array
	.outputArray(sysDataOut) // define the output feature array				// define the output feature array
);

//sysArray #(
//	.dataWidth(dataWidth),
//	.SysDimension(SysDimension)
//) Valuesys
//(
//	.clk(clk), // define the input clock
//	.rst(rst), // define the input reset
//	.enable(enable),
//	.weightArray(weightBufferTosysArray), // define the input weight array
//	.layerArray(sysarrayIn), // define the input feature array //Feature Array
//	.outputArray(sysDataOut) // define the output feature array				// define the output feature array
//);



parameter dlzlwidth= dataWidth*SysDimension;
dlzldpram #(.dataWidth(dlzlwidth),
.memblocksize(memsizedeltalzl), 
.psys(SysDimension)) zlbuffer
(
    .clk(clk),
    .rst(rst),
    .enableA(enable),
    .enableB(enable),
    .writenableA(enable),
    .datainA(sysDataOut),
    .dataoutB(zlout),
    .addressA(zlAddrA), //random, cahnge to weightaddr later =======================================
    .addressB(zlAddrA) //random, cahnge to weightaddr later =======================================
);
dlzldpram #(.dataWidth(dlzlwidth),
.memblocksize(memsizedeltalzl), 
.psys(SysDimension)) deltalbuffer
(
    .clk(clk),
    .rst(rst),
    .enableA(enable),
    .enableB(enable),
    .writenableA(enable),
    .datainA(dlin),
    .dataoutB(dlout),
    .addressA(dlAddrA), //random, cahnge to weightaddr later =======================================
    .addressB(dlAddrB) //random, cahnge to weightaddr later =======================================
);



always @(posedge clk or negedge rst) begin : proc_WeightAddr
	if(~rst) begin
		WeightAddr <= 0;
		alAddrA <= 0;
		alAddrB <= 0;
		dlAddrA <= 0;
		dlAddrB <= 0;
		zlAddrA <= 0;
		zlAddrB <= 0;

	end else begin
		WeightAddr <= WeightAddr + 1;
		alAddrA <= alAddrA + 1;
		alAddrB <= alAddrB + 1;
		dlAddrA <= alAddrA + 1;
		dlAddrB <= alAddrB + 1;
		zlAddrA <= alAddrA + 1;
		zlAddrB <= alAddrB + 1;		
	end
	
end





reluArray #(
	.dataWidth(dataWidth),
    .pactivation(SysDimension)
) singlereluArray
(
	.clk(clk),
	.rst(rst),
	.en(enact),
	.inputArray(zlout),
	.outputArray(reluOut)
);

reluDervArray #(
	.dataWidth(dataWidth),
    .pactivation(SysDimension)
) singlereluDervArray
(
	.clk(clk),
	.rst(rst),
	.en(enactd),
	.inputArray(zlout),
	.outputArray(reluDervOut)
);

multArray #(
	.dataWidth(dataWidth),
    .pactivation(SysDimension)
) multarray
(
	.clk(clk),
	.rst(rst),
	.inputArrayA(sysDataOut),
	.inputArrayB(reluDervOut),
	.outputArray(dlin)
);

wu #(
	.dataWidth(dataWidth),
    .pactivation(SysDimension)
)
(
	.clk(clk),
	.rst(rst),
	.en(enwu),
	.inputArrayA(wuInA),
	.inputArrayB(sysDataOut),
	.outputArray(wuOut)
);

mux_4to1_case #(    
	.dataWidth(dataWidth),
    .SysDimension(SysDimension)
	) mux1

(   .inf(mux1inf),                 // 4-bit input called a
    .fw(mux1inf),                 // inf & fw: same thing for weight buffer
    .bw(mux1bw),                 // 4-bit input called c
    .wu(dlout),                 // 4-bit input called d
    .sel(sel1),               // input sel used to select between a,b,c,d
    .out(weightBufferTosysArray));
    
mux_4to1_case #(    
	.dataWidth(dataWidth),
    .SysDimension(SysDimension)
	) mux2

(   .inf(mux2inf),                 // 4-bit input called a
    .fw(mux2fw),                 // 4-bit input called b
    .bw(dlout),                 // 4-bit input called c
    .wu(mux2wu),                 // 4-bit input called d
    .sel(sel2),               // input sel used to select between a,b,c,d
    .out(sysarrayIn));

//always @(posedge clk or negedge rst) begin : proc_outputArray
// 	if(~rst) begin
// 		outputArray <= 0;
// 	end else begin
// 		outputArray <= resultWireArray[SysDimension - 1];
// 	end
// end 


endmodule