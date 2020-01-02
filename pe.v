`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/26/2019 03:57:48 PM
// Design Name: 
// Module Name: pe
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


module pe #(
    parameter dataWidth = 32,
    parameter RowIndex = 0,
    parameter ColumnIndex = 0,
    parameter SysDimension = 16
)

    (
        clk,               // input clock
        rst,               // input reset
        enable,			   // input enable	
        streamLength,       // input: the length of data stream	, featureLen
        weight,            // input weights
        layerIn,         // input states or intermediate results
        resultIn,         // input previous result
        weightPass,         // pass weights(outputs)
        layerPass,        // output states or intermediate results
        resultOut       // pass states or intermediate results
    );
    // define the input
    input clk;
    input rst;
    input enable;
    input [8:0] streamLength; //2^9=512, max length 376
//    reg streamLength;
    input [dataWidth - 1:0] weight;
    input [dataWidth - 1:0] layerIn; //featureIn
    input [dataWidth - 1:0] resultIn; //preresult
    
    //define the output
    output [dataWidth - 1:0] weightPass;
    reg [dataWidth - 1:0] weightPass;
    output [dataWidth - 1:0] layerPass;//feature Pass
    reg [dataWidth - 1:0] layerPass;
    output [dataWidth - 1:0] resultOut; //feature out
    reg [dataWidth - 1:0] resultOut; //feature out


    
    
    parameter InitialLantency = 45;
    
    reg [9:0] StartPlace;
    //reg StartPlace = RowIndex + ColumnIndex + streamLength + InitialLantency  + 1;
    
//    parameter counterWidth = $clog2(InitialLantency + RowIndex + ColumnIndex + streamLength + 8);
    parameter counterWidth =10; //10 bits counter, should be enough
    
    
    parameter InitialStat = 1'b0;
    parameter PipelineStat = 1'b1;

always @(posedge clk or negedge rst) begin : assignStartplace
	if(~rst) begin
		StartPlace <= 0;
	end else begin
        StartPlace <= RowIndex + ColumnIndex + streamLength + InitialLantency  + 1;
    end
end


always @(posedge clk or negedge rst) begin : proc_weightPass //pass weight to next PE
	if(~rst) begin
		weightPass <= 0;
	end else begin
		if(enable)
			weightPass <= weight;
		else
			weightPass <= weightPass;
	end
end

always @(posedge clk or negedge rst) begin : proc_featurePass //pass layer to next PE
	if(~rst) begin
		layerPass <= 0;
	end else begin
		if(enable)
			layerPass <= layerIn;
		else
			layerPass <= layerPass;
	end
end


reg [counterWidth - 1: 0] counter;

reg state;

always @(posedge clk or negedge rst) begin : proc_state //Initial state (fist psys streams) or pipeline state (stacked streams following initial)
	if(~rst) begin
		state <= InitialStat;
	end else begin
		if(state == InitialStat && counter == StartPlace) begin 
			state <= PipelineStat;
		end
		else begin 
			state <= state;
		end
	end
end

always @(posedge clk or negedge rst) begin : proc_counter //start counting from start place to stream length, reset to 0 when reached streamlength(last element in the current stream)
	if(~rst) begin
		counter <= 0;
	end else begin
		if(enable) begin 
			if(state == InitialStat && counter < StartPlace - 1)
				counter <= counter + 1;
			else if(state == InitialStat && counter ==  StartPlace - 1)
				counter <= 0;
			else if(state == PipelineStat && counter < streamLength - 1)
				counter <= counter + 1;
			else if(state == PipelineStat && counter == streamLength - 1) //reset to 0
			    counter <= 0;
			else
				counter <= counter + 1;
		end
		else begin 
			counter <= counter;
		end
	end
end



reg dataValid;

always @(posedge clk or negedge rst) begin : proc_dataValid //is this data we calculate valid? as some PEs need to wait during initilization, only valid after r+c
	if(~rst) begin
		dataValid <= 1'b0;
	end else begin
		if( state == InitialStat  && enable && counter >= RowIndex + ColumnIndex )
			dataValid <= 1'b1;
		else if(state == PipelineStat && enable)
			dataValid <= 1'b1;
		else
			dataValid <= 1'b0;
	end
end

reg dataLast;

always @(posedge clk or negedge rst) begin : proc_dataLast //is this the last data in this stream?
	if(~rst) begin
		dataLast <= 0;
	end else begin
		if(state == InitialStat && enable && counter == RowIndex + ColumnIndex  + streamLength)
			dataLast <= 1'b1;
		else if(state == PipelineStat && enable && counter == streamLength)
			dataLast <= 1'b1;
		else
			dataLast <= 1'b0;
	end
end


//if valid, do MADD
wire Mulvalid;
wire [dataWidth - 1:0] Mulresult;
wire Mullast;

//this is an IP block, remember to rename to this name
floating_point_sys_adder sysMul (
  .aclk(clk),                                  // input wire aclk
  .s_axis_a_tvalid(dataValid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(weight),              // input wire [31 : 0] s_axis_a_tdata
  .s_axis_a_tlast(dataLast),              // input wire s_axis_a_tlast
  .s_axis_b_tvalid(dataValid),            // input wire s_axis_b_tvalid
  .s_axis_b_tdata(layerIn),              // input wire [31 : 0] s_axis_b_tdata
  .m_axis_result_tvalid(Mulvalid),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(Mulresult),    // output wire [31 : 0] m_axis_result_tdata
  .m_axis_result_tlast(Mullast)    // output wire m_axis_result_tlast
);

wire Accvalid;
wire [dataWidth - 1:0] Accresult;
wire Acclast;

//this is also an ip block, remember to rename to this name
floating_point_Sys_Acc sysAcc (
  .aclk(clk),                                  // input wire aclk
  .s_axis_a_tvalid(Mulvalid),            // input wire s_axis_a_tvalid
  .s_axis_a_tdata(Mulresult),              // input wire [31 : 0] s_axis_a_tdata
  .s_axis_a_tlast(Mullast),              // input wire s_axis_a_tlast
  .m_axis_result_tvalid(Accvalid),  // output wire m_axis_result_tvalid
  .m_axis_result_tdata(Accresult),    // output wire [31 : 0] m_axis_result_tdata
  .m_axis_result_tlast(Acclast)    // output wire m_axis_result_tlast
);


// 
reg [dataWidth - 1:0] temResult;

always @(posedge clk or negedge rst) begin : proc_temResult
	if(~rst) begin
		temResult <= 0;
	end else begin
		if(Acclast && Accvalid)
			temResult <= Accresult;
		else
			temResult <= temResult;
	end
end

always @(posedge clk or negedge rst) begin : proc_featureOut
	if(~rst) begin
		resultOut <= 0;
	end else begin
		if(state == PipelineStat && enable && counter == 2*SysDimension - (RowIndex + ColumnIndex)) //when the last PE finishes
			resultOut <= temResult;
		else if (state == PipelineStat && enable && counter > 2*SysDimension - (RowIndex + ColumnIndex)) //pass result into ram
			resultOut <= resultIn;
		else
			resultOut <= resultOut;
	end
end
endmodule
