`timescale 1ns/10ps
module fork_module(fork_arm_data_out,
                   fork_arm_sent_req_vec_out,
                   fork_arm_new_vec_out,
                   fork_arm_ready_vec_in,
                   fork_arm_vc_no_vec_out,
                                      
                   fork_arm_data_in,
                   fork_arm_sent_req_vec_in,
                   fork_arm_new_vec_in,
                   fork_arm_ready_vec_out,
                   fork_arm_vc_no_vec_in,
                                      
                   fork_fingers_data_out,
                   fork_fingers_sent_req_vec_out,
                   fork_fingers_new_vec_out,
                   fork_fingers_ready_vec_in,
                   fork_fingers_vc_no_vec_out,
                   
                   fork_fingers_data_in,
                   fork_fingers_sent_req_vec_in,
                   fork_fingers_new_vec_in,
                   fork_fingers_ready_vec_out,
                   fork_fingers_vc_no_vec_in,
                   
                   busy,
                   my_addr,
                   rs,
                   clk);

parameter fork_arm_width=10;                 //this parameter detemine how much fork_arm is powerfull than an outport
parameter floorplusone_log2_fork_arm_width=2;
parameter no_fingers=6;
parameter floorplusone_log2_no_fingers=3;
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;
parameter flit_size=1;                       //In number of phits
parameter floorplusone_log2_flit_size=1;
parameter phit_size=16;                      //In number of bits
parameter buf_size=4;                        //In number of flits
parameter floorplusone_log2_buf_size=3;
parameter switching_method=1;                //1 to Store&forward, 2 to VCT, 3 to Wormhole switching
parameter addr_length=10;                    //In number of bits
parameter addr_place_in_header=0;            //bit number in header that address start
                   
output [(fork_arm_width*phit_size)-1:0] fork_arm_data_out;
output [(fork_arm_width-1):0] fork_arm_sent_req_vec_out;
output [(fork_arm_width-1):0] fork_arm_new_vec_out;
input [(fork_arm_width-1):0] fork_arm_ready_vec_in;
output [(fork_arm_width*floorplusone_log2_no_vc)-1:0] fork_arm_vc_no_vec_out;

input [(fork_arm_width*phit_size)-1:0] fork_arm_data_in;
input [(fork_arm_width-1):0] fork_arm_sent_req_vec_in;
input [(fork_arm_width-1):0] fork_arm_new_vec_in;
output [(fork_arm_width-1):0] fork_arm_ready_vec_out;
input [(fork_arm_width*floorplusone_log2_no_vc)-1:0] fork_arm_vc_no_vec_in;

output [(no_fingers*phit_size)-1:0] fork_fingers_data_out;
output [(no_fingers-1):0] fork_fingers_sent_req_vec_out;
output [(no_fingers-1):0] fork_fingers_new_vec_out;
input [(no_fingers-1):0] fork_fingers_ready_vec_in;
output [(no_fingers*floorplusone_log2_no_vc)-1:0] fork_fingers_vc_no_vec_out;

input [(no_fingers*phit_size)-1:0] fork_fingers_data_in;
input [(no_fingers-1):0] fork_fingers_sent_req_vec_in;
input [(no_fingers-1):0] fork_fingers_new_vec_in;
output [(no_fingers-1):0] fork_fingers_ready_vec_out;
input [(no_fingers*floorplusone_log2_no_vc)-1:0] fork_fingers_vc_no_vec_in;

output busy;
input [(addr_length-1):0] my_addr;
input rs,clk;  

wire sent_busy,rec_busy;

defparam fork_router_sent.no_outport=fork_arm_width;
defparam fork_router_sent.floorplusone_log2_no_outport=floorplusone_log2_fork_arm_width;
defparam fork_router_sent.no_inport=no_fingers;
defparam fork_router_sent.floorplusone_log2_no_inport=floorplusone_log2_no_fingers;
defparam fork_router_sent.no_vc=no_vc;
defparam fork_router_sent.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
defparam fork_router_sent.flit_size=flit_size;
defparam fork_router_sent.floorplusone_log2_flit_size=floorplusone_log2_flit_size;
defparam fork_router_sent.phit_size=phit_size;
defparam fork_router_sent.buf_size=buf_size;
defparam fork_router_sent.floorplusone_log2_buf_size=floorplusone_log2_buf_size;
defparam fork_router_sent.switching_method=switching_method;         
defparam fork_router_sent.addr_length=addr_length;           
defparam fork_router_sent.addr_place_in_header=addr_place_in_header;    
fork_router fork_router_sent(fork_arm_data_out,
                             fork_arm_sent_req_vec_out,
                             fork_arm_new_vec_out,
                             fork_arm_ready_vec_in,
                             fork_arm_vc_no_vec_out,
                                  
                             fork_fingers_data_in,
                             fork_fingers_sent_req_vec_in,
                             fork_fingers_new_vec_in,
                             fork_fingers_ready_vec_out,
                             fork_fingers_vc_no_vec_in,
                             
                             sent_busy,     
                             my_addr,
                             rs,
                             clk);

defparam fork_router_rec.no_outport=no_fingers;
defparam fork_router_rec.floorplusone_log2_no_outport=floorplusone_log2_no_fingers;
defparam fork_router_rec.no_inport=fork_arm_width;
defparam fork_router_rec.floorplusone_log2_no_inport=floorplusone_log2_fork_arm_width;
defparam fork_router_rec.no_vc=no_vc;
defparam fork_router_rec.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
defparam fork_router_rec.flit_size=flit_size;
defparam fork_router_rec.floorplusone_log2_flit_size=floorplusone_log2_flit_size;
defparam fork_router_rec.phit_size=phit_size;
defparam fork_router_rec.buf_size=buf_size;
defparam fork_router_rec.floorplusone_log2_buf_size=floorplusone_log2_buf_size;
defparam fork_router_rec.switching_method=switching_method;         
defparam fork_router_rec.addr_length=addr_length;           
defparam fork_router_rec.addr_place_in_header=addr_place_in_header; 

fork_router fork_router_rec(fork_fingers_data_out,
                            fork_fingers_sent_req_vec_out,
                            fork_fingers_new_vec_out,
                            fork_fingers_ready_vec_in,
                            fork_fingers_vc_no_vec_out,
                            
                            fork_arm_data_in,
                            fork_arm_sent_req_vec_in,
                            fork_arm_new_vec_in,
                            fork_arm_ready_vec_out,
                            fork_arm_vc_no_vec_in,
                            
                            rec_busy,
                            my_addr,
                            rs,
                            clk);
                            
assign busy=sent_busy|rec_busy;                            
endmodule