`timescale 1ns/10ps
module ones_counter(out,
                    inc,
                    dec,
                    rs,
                    clk);
parameter floorplusone_log2_no_vc=4;
output reg [floorplusone_log2_no_vc-1:0] out;
input inc,dec,rs,clk;

always@(posedge clk)
begin
	if(rs)out=0;
	else if(inc&dec==1) out=out;
	else if(inc)out=out+1;
	else if(dec)out=out-1;
end

endmodule