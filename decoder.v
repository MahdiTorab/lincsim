`timescale 1ns/10ps
module decoder(out,
               in);
  parameter no_vc=13;
  parameter floorplusone_log2_no_vc=4;
  
  output reg [(no_vc-1):0] out;
  input [(floorplusone_log2_no_vc-1):0] in;
  reg [(floorplusone_log2_no_vc-1):0] i;
  
 always@(in)
  begin
   for(i=0;i<=(no_vc-1);i=i+1)
    begin
     if(i!=in)out[i]=0;
     else if(i==in) out[i]=1;
    end
  end
endmodule