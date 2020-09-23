`timescale 1ns/10ps
module rcvc_arbiter(rc_ens,
                    vc_ens,
                    handshakes,
                    rc_dones,
                    vc_dones,
                    rs,
                    clk);
 
 parameter no_vc=12;
 
 output [(no_vc-1):0] rc_ens;
 output [(no_vc-1):0] vc_ens;
 input [(no_vc-1):0] handshakes,rc_dones,vc_dones;
 input rs,clk;
 
 wire [no_vc:0] tmp_vc_ens,tmp_rc_ens;
 wire [(no_vc-1):0] rc_needs,vc_needs;
 reg [(no_vc-1):0] tmp_rc_needs,tmp_vc_needs;

 assign rc_ens= tmp_rc_ens[no_vc:1];
 assign vc_ens= tmp_vc_ens[no_vc:1];
 assign rc_needs= tmp_rc_needs|handshakes;
 assign vc_needs= tmp_vc_needs|rc_dones;
 
 defparam rcvc_arbiter_counter_on_ones_rc_needs.no_vc=no_vc+1;
 counter_on_ones rcvc_arbiter_counter_on_ones_rc_needs(tmp_rc_ens,{rc_needs,1'b0},rs,clk);
 
 defparam rcvc_arbiter_counter_on_ones_vc_needs.no_vc=no_vc+1;
 counter_on_ones rcvc_arbiter_counter_on_ones_vc_needs(tmp_vc_ens,{vc_needs,1'b0},rs,clk);
 
 always@(posedge clk)
  begin
   if(rs)
    begin
     tmp_rc_needs=0;
     tmp_vc_needs=0;
    end
   else
    begin
     tmp_rc_needs=(rc_needs|handshakes)&~rc_dones;
     tmp_vc_needs=(vc_needs|rc_dones)&~vc_dones;
    end
 end
 
endmodule