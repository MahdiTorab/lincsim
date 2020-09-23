`timescale 1ns/10ps
`timescale 1ns/10ps
module inport_in_interface_updater(invc_req,
                                   out_vec,
                                   out_allow_vcs,
                                   vc_done,
                                   state,
                                   outport_vec,
                                   allow_vcs,
                                   ok_vec,
                                   en,
                                   reset,
                                   clk);
                                   
parameter no_outport=6;
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;
parameter vc_no=1;

output reg [(floorplusone_log2_no_vc-1):0] invc_req;
output reg [(no_outport-1):0] out_vec;
output reg [(no_vc-1):0] out_allow_vcs;
output vc_done;
input [1:0] state;
input [(no_outport-1):0] outport_vec;
input [(no_vc-1):0] allow_vcs;
input [(no_outport-1):0] ok_vec;
input en,reset,clk;

reg after_update_flag,en_reg;
reg internal_state;
reg [(no_outport-1):0] tmp_outport_vec;
wire [(no_outport-1):0] tmp_outport_vec_sig;

assign tmp_outport_vec_sig= outport_vec ^ ok_vec;
assign vc_done= en_reg & state[1] & ~|tmp_outport_vec_sig;
     
always@(posedge clk)
begin
  if(reset)
   begin
    internal_state=0;
    after_update_flag=0;
    invc_req=0;
    out_vec=0;
    out_allow_vcs=0;
   end
  else if(~reset)
   begin
    if(state==2'b10 && en==1 && internal_state==0)
     begin
      invc_req=vc_no;
      out_vec=outport_vec;
      out_allow_vcs=allow_vcs;
      tmp_outport_vec=outport_vec;
      internal_state=1;
      after_update_flag=1;
     end
    else if(state==2'b10 && en==0 && internal_state==1)
     begin
      if (after_update_flag)
       begin
        if(|tmp_outport_vec_sig)
         begin 
          out_vec=0;
          invc_req=0;
          tmp_outport_vec=tmp_outport_vec_sig;
          after_update_flag=0;
          out_allow_vcs=0;
         end
        if(~|tmp_outport_vec_sig)
         begin
          out_vec=0;
          invc_req=0;
          tmp_outport_vec=tmp_outport_vec_sig;
          after_update_flag=0;
          out_allow_vcs=0;
         end
       end
      else if(~after_update_flag)
       begin
        out_vec=0;
        invc_req=0;
        out_allow_vcs=0;
       end
     end
    else if(state==2'b10 && en==1 && internal_state==1)
     begin
      if(after_update_flag)
       begin
        if(|tmp_outport_vec_sig)
         begin 
          tmp_outport_vec=tmp_outport_vec_sig;
          out_vec=tmp_outport_vec_sig;
          invc_req=vc_no;
          out_allow_vcs=allow_vcs;
          after_update_flag=1;
         end
        if(~|tmp_outport_vec_sig)
         begin
          tmp_outport_vec=tmp_outport_vec_sig;
          out_vec=0;
          invc_req=0;
          out_allow_vcs=0;
          after_update_flag=0;
         end
       end
      if(~after_update_flag)
       begin
        if(|tmp_outport_vec_sig)
         begin
          out_vec=tmp_outport_vec;
          invc_req=vc_no;
          out_allow_vcs=allow_vcs;
          after_update_flag=1;
         end
        if(~|tmp_outport_vec_sig)
         begin
          out_vec=0;
          invc_req=0;
          out_allow_vcs=0;
          after_update_flag=0;
         end             
       end 
     end
    else
     begin
      out_allow_vcs=0;
      invc_req=0;
      out_vec=0;
      out_allow_vcs=0;
     end
   end
end

always @(posedge clk) en_reg=en;

endmodule