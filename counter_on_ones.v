`timescale 1ns/10ps
module counter_on_ones(out,
                       in,
                       rs,
                       clk);
parameter no_vc=13;
output [(no_vc-1):0] out;
input [(no_vc-1):0] in;
input rs,clk;

reg [no_vc-1:0] count;
wire allcount_zero,all_zero;
wire [no_vc-1:0] input_bypass,count_input;
wire [no_vc-1:0] tmp;
genvar i;

assign allcount_zero=~(|((tmp|{{(no_vc-1){1'b0}},count[0]})&count));
assign input_bypass={no_vc{allcount_zero}}|(tmp&{{(no_vc-1){1'b1}},1'b0});
assign count_input=input_bypass&in;
assign tmp[0]=0;
assign tmp[1]=count[0];
assign all_zero=~|count;
assign out=(all_zero?in:count&(~tmp));

generate for (i=2;i<no_vc;i=i+1) begin:tmp_loop
          assign tmp[i]= tmp[i-1]|count[i-1];
         end
endgenerate     
   

always@(posedge clk)
begin
  if(rs) count=0;
  else count=count_input;
end
endmodule