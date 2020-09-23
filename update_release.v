`timescale 1ns/10ps
module update_release(vc_no,
                      allowed_vcs,
                      port_no_vec,
                      update_en,
                      ok,
                      tags,
                      invc_nos,
                      all_allowed_vcs,
                      updates,
                      rs,
                      clk);
parameter no_inport=6;
parameter floorplusone_log2_no_inport=3;
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;

output [(floorplusone_log2_no_vc-1):0] vc_no ;
output [(no_vc-1):0] allowed_vcs;
output [(no_inport-1):0] port_no_vec;
output update_en;
output [(no_inport-1):0] ok;
input [(no_vc-1):0] tags;
input [(no_inport*floorplusone_log2_no_vc)-1:0] invc_nos ;
input [(no_inport*no_vc)-1:0] all_allowed_vcs;
input [(no_inport-1):0] updates;
input rs,clk;

wire [(floorplusone_log2_no_vc)-1:0] invc_noss [(no_inport-1):0];
wire [(floorplusone_log2_no_vc)-1:0] tmp_vc_no [(no_inport-1):0];
wire [(no_inport-1):0] tmp_vc_no_vec [(floorplusone_log2_no_vc-1):0];
wire [(no_vc-1):0] allowed_vcss [(no_inport-1):0];
wire [(no_vc-1):0] tmp_allowed_vcss [(no_inport-1):0];
wire [(no_inport-1):0] tmp_allowed_vcs_vec [(no_vc-1):0];
wire [(no_inport-1):0] middle_turn,mature_turn;
wire [(no_inport-1):0] chain;
wire [(no_inport-1):0] matured_update;
wire [(no_vc-1):0] tmp_matured_update [(no_inport-1):0];
reg [(no_inport-1):0] turn;
genvar i,j;

assign middle_turn[0]=turn[0]|(chain[no_inport-1]);
generate for(i=1;i<no_inport;i=i+1) begin:middle_turn_loop
  assign middle_turn[i]=turn[i]|(chain[i-1]);
 end
endgenerate

generate for(i=0;i<no_inport;i=i+1) begin:invc_noss_loop
  assign invc_noss[i]=invc_nos[(((i+1)*floorplusone_log2_no_vc)-1):(i*floorplusone_log2_no_vc)];
 end
endgenerate

generate for(i=0;i<no_inport;i=i+1) begin:tmp_vc_no_loop
  assign tmp_vc_no[i]={floorplusone_log2_no_vc{mature_turn[i]}}&invc_noss[i];
 end
endgenerate

generate for(i=0;i<floorplusone_log2_no_vc;i=i+1) begin:tmp_vc_no_vec_outloop
            for(j=0;j<no_inport;j=j+1) begin:tmp_vc_no_vec_inloop
               assign tmp_vc_no_vec[i][j]=tmp_vc_no[j][i];
            end
          end
endgenerate

generate for(i=0;i<floorplusone_log2_no_vc;i=i+1) begin:vc_no_loop
  assign vc_no[i]=|tmp_vc_no_vec[i];
 end
endgenerate

generate for(i=0;i<no_inport;i=i+1) begin:allowed_vcss_loop
  assign allowed_vcss[i]=all_allowed_vcs[(((i+1)*no_vc)-1):(i*no_vc)];
 end
endgenerate

generate for(i=0;i<no_inport;i=i+1) begin:tmp_allowed_vcss_loop
  assign tmp_allowed_vcss[i]={no_vc{mature_turn[i]}}&allowed_vcss[i];
 end
endgenerate

generate for(i=0;i<no_vc;i=i+1) begin:tmp_allowed_vcs_vec_outloop
            for(j=0;j<no_inport;j=j+1) begin:tmp_allowed_vcs_vec_inloop
               assign tmp_allowed_vcs_vec[i][j]=tmp_allowed_vcss[j][i];
            end
          end
endgenerate

generate for(i=0;i<no_vc;i=i+1) begin:allowed_vcs_loop
  assign allowed_vcs[i]=|tmp_allowed_vcs_vec[i];
 end
endgenerate

generate for(i=0;i<no_inport;i=i+1) begin: tmp_matured_update_outloop
            for(j=0;j<no_vc;j=j+1) begin: tmp_matured_update_inloop
              assign tmp_matured_update[i][j]=allowed_vcss[i][j]&~tags[j];
            end
          end
endgenerate

generate for(i=0;i<no_inport;i=i+1) begin: matured_update_loop
  assign matured_update[i]=(|tmp_matured_update[i])&updates[i];
 end
endgenerate

assign mature_turn=(matured_update)&middle_turn;
assign update_en=|mature_turn;
assign ok=mature_turn;
assign port_no_vec=mature_turn;
assign chain=middle_turn&(~matured_update);
 
always@(posedge clk)
begin
  if(rs) turn={{(no_inport-1){1'b0}},1'b1};
  else if(turn!={1'b1,{(no_inport-1){1'b0}}}) turn=turn<<1;
  else if(turn=={1'b1,{(no_inport-1){1'b0}}}) turn={{(no_inport-1){1'b0}},1'b1};
end

endmodule