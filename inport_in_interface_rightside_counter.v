`timescale 1ns/10ps
module inport_in_interface_rightside_counter(out,
                                             inc,
                                             rs_to_end,
                                             rs_to_first,
                                             clk);

parameter flit_size=1;
parameter floorplusone_log2_flit_size=1;

output [(floorplusone_log2_flit_size-1):0] out;
input inc,rs_to_end,rs_to_first,clk;

reg [(floorplusone_log2_flit_size-1):0] out_tmp;

assign out=out_tmp;

always@(posedge clk)
 begin
  if(rs_to_end) out_tmp=flit_size;
  else if(rs_to_first) out_tmp=0;
  else if(inc) out_tmp=out_tmp+1;
 end
endmodule