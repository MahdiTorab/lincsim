`timescale 1ns/10ps
module encoder(out,
               in);
               
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;

output reg [(floorplusone_log2_no_vc-1):0] out;
input [(no_vc-1):0] in;

reg [(floorplusone_log2_no_vc-1):0] i;

always@(in)
begin
 for(i=0;i<=(no_vc-1);i=i+1)
  begin
   if(|in)
    begin
     if(in[i]) out=i;
    end
   else out=0;
  end
end
endmodule