`timescale 1ns/10ps
module inport_in_interface(outdatas,
                           out_sent_req_vec,
                           out_new_vec,
                           invc_req,
                           allowed_vcs,
                           out_vec_update,
                           header,
                           pre_full,
                           full,
                           rc_req,
                           handshake_done,
                           rc_done,
                           vc_done,
                           indata,
                           in_new,
                           insent_req,
                           calls,
                           ready_vec,
                           ok_vec,
                           outport_vec_from_rc,
                           allowed_vcs_from_rc,
                           rc_valid,
                           data_en,
                           rc_en,
                           vc_en,
                           rs,
                           clk);

parameter no_outport=6;
parameter floorplusone_log2_no_outport=3;
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;
parameter flit_size=1;                
parameter floorplusone_log2_flit_size=1;
parameter phit_size=16;               
parameter buf_size=4;                 
parameter floorplusone_log2_buf_size=4;
parameter switching_method=1;         
parameter addr_length=10;             
parameter vc_no=3;      

output [(no_outport*phit_size)-1:0] outdatas;
output [(no_outport-1):0]out_sent_req_vec,out_new_vec;
output [(floorplusone_log2_no_vc-1):0] invc_req;
output [(no_vc-1):0] allowed_vcs;
output [(no_outport-1):0] out_vec_update;
output [(flit_size*phit_size)-1:0] header;
output pre_full,full;
output rc_req,handshake_done,rc_done,vc_done;
input [(phit_size)-1:0]indata;
input in_new,insent_req;
input [(no_outport-1):0] calls,ready_vec,ok_vec,outport_vec_from_rc;
input [(no_vc-1):0] allowed_vcs_from_rc;
input rc_valid,data_en,rc_en,vc_en,rs,clk;

wire [(flit_size*phit_size)-1:0] data_from_left_to_buf,data_from_buf_to_right;
wire [(no_outport-1):0] outport_vec_from_left;
wire [(no_vc-1):0] allowed_vcs_from_left;
wire [1:0] state;
wire reset,all_done,empty,head_from_left_to_buf,valid,
     head_from_buf_to_right,tail_from_left_to_buf,tail_from_buf_to_right,want,new_from_left,in_new_from_left_to_buf;
     
state inport_in_interface_state(state,
                                reset,
                                handshake_done,
                                rc_done,
                                vc_done,
                                all_done,
                                vc_en,
                                rs,
                                clk);

defparam inport_in_interface_leftside.no_outport=no_outport;
defparam inport_in_interface_leftside.no_vc=no_vc;
defparam inport_in_interface_leftside.flit_size=flit_size;              
defparam inport_in_interface_leftside.floorplusone_log2_flit_size=floorplusone_log2_flit_size;
defparam inport_in_interface_leftside.phit_size=phit_size;              
defparam inport_in_interface_leftside.switching_method=switching_method;
inport_in_interface_leftside inport_in_interface_leftside(data_from_left_to_buf,
                                                          new_from_left,
                                                          head_from_left_to_buf,
                                                          tail_from_left_to_buf,
                                                          outport_vec_from_left,
                                                          allowed_vcs_from_left,
                                                          header,
                                                          rc_req,
                                                          handshake_done,
                                                          in_new_from_left_to_buf,
                                                          valid,
                                                          rc_done,
                                                          full,
                                                          indata,
                                                          rc_valid,
                                                          outport_vec_from_rc,
                                                          allowed_vcs_from_rc,
                                                          state,
                                                          insent_req,
                                                          in_new,
                                                          data_en,
                                                          rc_en,
                                                          reset,
                                                          clk);
                          
defparam inport_in_interface_buf.flit_size=flit_size;       
defparam inport_in_interface_buf.phit_size=phit_size;              
defparam inport_in_interface_buf.buf_size=buf_size;                 
defparam inport_in_interface_buf.floorplusone_log2_buf_size=floorplusone_log2_buf_size;  
inport_in_interface_buf inport_in_interface_buf(data_from_buf_to_right,
                                                pre_full,
                                                full,
                                                empty,
                                                head_from_buf_to_right,
                                                tail_from_buf_to_right,
                                                data_from_left_to_buf,
                                                new_from_left,
                                                head_from_left_to_buf,
                                                tail_from_left_to_buf,
                                                want,
                                                in_new_from_left_to_buf,
                                                valid,
                                                reset,
                                                clk);

defparam inport_in_interface_rightside.no_outport=no_outport;
defparam inport_in_interface_rightside.floorplusone_log2_no_outport=floorplusone_log2_no_outport;
defparam inport_in_interface_rightside.flit_size=flit_size;
defparam inport_in_interface_rightside.floorplusone_log2_flit_size=floorplusone_log2_flit_size;
defparam inport_in_interface_rightside.phit_size=phit_size;
inport_in_interface_rightside inport_in_interface_rightside(outdatas,
                                                            out_sent_req_vec,
                                                            out_new_vec,
                                                            want,
                                                            all_done,
                                                            data_from_buf_to_right,
                                                            ready_vec,
                                                            calls,
                                                            outport_vec_from_left,
                                                            state,
                                                            head_from_buf_to_right,
                                                            tail_from_buf_to_right,
                                                            empty,
                                                            reset,
                                                            clk);

defparam inport_in_interface_updater.no_outport=no_outport;
defparam inport_in_interface_updater.no_vc=no_vc;
defparam inport_in_interface_updater.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
defparam inport_in_interface_updater.vc_no=vc_no;
inport_in_interface_updater inport_in_interface_updater(invc_req,
                                                        out_vec_update,
                                                        allowed_vcs,
                                                        vc_done,
                                                        state,
                                                        outport_vec_from_left,
                                                        allowed_vcs_from_left,
                                                        ok_vec,
                                                        vc_en,
                                                        reset,
                                                        clk);

endmodule