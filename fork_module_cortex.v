`timescale 1ns/10ps
module fork_module_cortex(fork_arm_data_out,
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
parameter want_routers_power_estimation= 1;  //0: If you don't want to run Design Compiler flow to estimate routers power, 1:If you want routers power estimation (guide for more details)
parameter is_netlist_provided= 1;            //0: If you want estimate routers power and provide netlists set it to 1, else 0 (guide for more details)

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

generate if(want_routers_power_estimation==1 && is_netlist_provided==1)
  begin
   fork_module_netlist fork_module_netlist(fork_arm_data_out,
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
  end
 else
  begin
   fork_module#(fork_arm_width,
                floorplusone_log2_fork_arm_width,
                no_fingers,
                floorplusone_log2_no_fingers,
                no_vc,
                floorplusone_log2_no_vc,
                flit_size,
                floorplusone_log2_flit_size,
                phit_size,
                buf_size,
                floorplusone_log2_buf_size,
                switching_method,
                addr_length,
                addr_place_in_header)
    fork_module(fork_arm_data_out,
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
  end
endgenerate

endmodule
