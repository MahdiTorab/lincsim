`timescale 1ns/10ps
module inport_out_interface(call_invc,
                            ok_vec,
                            ready_vec,
                            outdata,
                            out_update,
                            invc_req_no_to_out,
                            in_allowed_vcs,
                            new,
                            sent_req,
                            ok,
                            ready,
                            invc_req_no_from_in,
                            out_allowed_vcs,
                            outdatas,
                            news,
                            sent_reqs,
                            in_update,
                            invc_no_from_outport,
                            en,
                            clk);

parameter no_outport=6;
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;
parameter phit_size=16;
parameter iden_no=0; //This parameter is a identifier that show the number of outport that this module responses it!
parameter [(no_outport-1):0] iden_vec=2**iden_no;

output [(no_vc-1):0] call_invc;
output [(no_outport-1):0] ok_vec,ready_vec;
output [(phit_size-1):0] outdata;
output out_update;
output [(floorplusone_log2_no_vc-1):0] invc_req_no_to_out;
output [(no_vc-1):0] out_allowed_vcs;
output new,sent_req;
input ok;
input ready;
input [(floorplusone_log2_no_vc-1):0] invc_req_no_from_in;
input [(no_vc-1):0] in_allowed_vcs;
input [(no_vc-1):0] news;
input [(no_vc*phit_size)-1:0] outdatas;
input [(no_vc-1):0] sent_reqs;
input in_update;
input [(floorplusone_log2_no_vc)-1:0] invc_no_from_outport;
input en,clk;

wire [(no_vc-1):0] tmp_call_invc;
wire [(phit_size-1):0] out_datas [(no_vc-1):0];
wire [(floorplusone_log2_no_vc-1):0] in_vc_reqs [(no_vc-1):0];
wire [(no_vc-1):0] tmp_invc_req_no [(floorplusone_log2_no_vc-1):0];
reg en_reg;
reg [(floorplusone_log2_no_vc)-1:0] invc_no_from_outport_reg;

genvar i,j,k,l,m;

generate for(i=0;i<no_vc;i=i+1) begin: out_datas_loop
  assign out_datas[i]=outdatas[((i+1)*phit_size)-1:(i*phit_size)];
end
endgenerate

defparam inport_out_interface_decoder.no_vc=no_vc;
defparam inport_out_interface_decoder.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
decoder inport_out_interface_decoder(tmp_call_invc,
                                     invc_no_from_outport);
assign call_invc={no_vc{en}}&tmp_call_invc;

assign ok_vec={no_outport{ok}}&iden_vec;
assign ready_vec=en?{no_outport{ready}}&iden_vec:0;
assign out_update= in_update;
assign out_allowed_vcs= in_allowed_vcs;
assign invc_req_no_to_out= invc_req_no_from_in;
assign outdata= {phit_size{en_reg}} & out_datas[invc_no_from_outport_reg];
assign new= en_reg & news[invc_no_from_outport_reg];
assign sent_req= en_reg & sent_reqs[invc_no_from_outport_reg];

always@(posedge clk)
 begin
  en_reg=en;
  invc_no_from_outport_reg=invc_no_from_outport;
 end
 
endmodule