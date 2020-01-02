module mux_4to1_case #(    
	parameter dataWidth = 32,
    parameter SysDimension = 16
	)

(   input [dataWidth*SysDimension-1:0] inf,                 // 4-bit input called a
    input [dataWidth*SysDimension-1:0] fw,                 // 4-bit input called b
    input [dataWidth*SysDimension-1:0] bw,                 // 4-bit input called c
    input [dataWidth*SysDimension-1:0] wu,                 // 4-bit input called d
    input [1:0] sel,               // input sel used to select between a,b,c,d
    output reg [dataWidth*SysDimension-1:0] out);         // 4-bit output based on input sel
 
   // This always block gets executed whenever a/b/c/d/sel changes value
   // When that happens, based on value in sel, output is assigned to either a/b/c/d
   always @ (inf or fw or bw or wu or sel) begin
      case (sel)
         2'b00 : out <= inf;
         2'b01 : out <= fw;
         2'b10 : out <= bw;
         2'b11 : out <= wu;
      endcase
   end
endmodule