`timescale 1ns/10ps
module sv_fork_module(fork_arm_data_out,
                      fork_arm_sent_req_vec_out,
                      fork_arm_new_vec_out,
                      fork_arm_ready_vec_in,
                      fork_arm_vc_no_vec_out,                      
                      
                      fork_arm_data_in,
                      fork_arm_sent_req_vec_in,
                      fork_arm_new_vec_in,
                      fork_arm_ready_vec_out,
                      fork_arm_vc_no_vec_in,
                                           
                      fork_finger_data_out_array,
                      fork_finger_sent_req_vec_out_array,
                      fork_finger_new_vec_out_array,
                      fork_finger_ready_vec_in_array,
                      fork_finger_vc_no_vec_out_array,       
        
                      fork_finger_data_in_array,
                      fork_finger_sent_req_vec_in_array,
                      fork_finger_new_vec_in_array,
                      fork_finger_ready_vec_out_array,
                      fork_finger_vc_no_vec_in_array,                     
                      
                      busy,
                      active,
                      rs,
                      clk);

parameter no_fork=1;
parameter my_fork_id=1;
parameter fork_arm_width=10;              //this parameter detemine how much fork_arm is powerfull than an outport
parameter floorplusone_log2_fork_arm_width=2;
parameter no_fingers=6;
parameter floorplusone_log2_no_fingers=3;
parameter head_zero_head_one=0;
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;
parameter flit_size=1;                    //In number of phits
parameter floorplusone_log2_flit_size=1;
parameter phit_size=16;                   //In number of bits
parameter buf_size=4;                     //In number of flits
parameter floorplusone_log2_buf_size=3;
parameter switching_method=1;             //1 to Store&forward, 2 to VCT, 3 to Wormhole switching
parameter addr_place_in_header=0;         //bit number in header that address start
parameter want_vcd_files=1;               //0: no vcd file generation, 1: vcd file generation
parameter want_routers_power_estimation= 1;   //0: If you don't want to run Design Compiler flow to estimate routers power, 1:If you want routers power estimation (guide for more details)
parameter is_netlist_provided= 1;             //0: If you want estimate routers power and provide netlists set it to 1, else 0 (guide for more details)

localparam addr_length=$clog2(no_fork+1); //In number of bits
localparam [(addr_length-1):0] my_addr= my_fork_id;

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

output [(phit_size-1):0] fork_finger_data_out_array [(no_fingers-1):0];
output [(no_fingers-1):0] fork_finger_sent_req_vec_out_array;
output [(no_fingers-1):0] fork_finger_new_vec_out_array;
input [(no_fingers-1):0] fork_finger_ready_vec_in_array;
output [(floorplusone_log2_no_vc-1):0] fork_finger_vc_no_vec_out_array [(no_fingers-1):0];
       
input [(phit_size-1):0] fork_finger_data_in_array [(no_fingers-1):0];
input [(no_fingers-1):0] fork_finger_sent_req_vec_in_array;
input [(no_fingers-1):0] fork_finger_new_vec_in_array;
output [(no_fingers-1):0] fork_finger_ready_vec_out_array;                      
input [(floorplusone_log2_no_vc-1):0] fork_finger_vc_no_vec_in_array [(no_fingers-1):0];

output busy;
input active,rs,clk;
                      
wire [(no_fingers*phit_size)-1:0] fork_fingers_data_out;
wire [(no_fingers*phit_size)-1:0] fork_fingers_data_in;
wire [(no_fingers*floorplusone_log2_no_vc)-1:0] fork_finger_vc_no_vec_out;
wire [(no_fingers*floorplusone_log2_no_vc)-1:0] fork_finger_vc_no_vec_in;

genvar i,j;

generate for(i=0;i<no_fingers;i++) begin: fork_finger_data_array_loop
          assign fork_finger_data_out_array[i]=fork_fingers_data_out[((i+1)*phit_size)-1:(i*phit_size)];
          assign fork_fingers_data_in[((i+1)*phit_size)-1:(i*phit_size)]=fork_finger_data_in_array[i];
          assign fork_finger_vc_no_vec_out_array[i]=fork_finger_vc_no_vec_out[((i+1)*floorplusone_log2_no_vc)-1:(i*floorplusone_log2_no_vc)];
          assign fork_finger_vc_no_vec_in[((i+1)*floorplusone_log2_no_vc)-1:(i*floorplusone_log2_no_vc)]=fork_finger_vc_no_vec_in_array[i];
         end
endgenerate  

defparam fork_module_cortex.fork_arm_width=fork_arm_width;
defparam fork_module_cortex.floorplusone_log2_fork_arm_width=floorplusone_log2_fork_arm_width;
defparam fork_module_cortex.no_fingers=no_fingers;
defparam fork_module_cortex.floorplusone_log2_no_fingers=floorplusone_log2_no_fingers;
defparam fork_module_cortex.no_vc=no_vc;
defparam fork_module_cortex.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
defparam fork_module_cortex.flit_size=flit_size;
defparam fork_module_cortex.floorplusone_log2_flit_size=floorplusone_log2_flit_size;
defparam fork_module_cortex.phit_size=phit_size;
defparam fork_module_cortex.buf_size=buf_size;
defparam fork_module_cortex.floorplusone_log2_buf_size=floorplusone_log2_buf_size;
defparam fork_module_cortex.switching_method=switching_method;
defparam fork_module_cortex.addr_length=addr_length;
defparam fork_module_cortex.addr_place_in_header=addr_place_in_header;
defparam fork_module_cortex.want_routers_power_estimation=want_routers_power_estimation;
defparam fork_module_cortex.is_netlist_provided=is_netlist_provided;
fork_module_cortex fork_module_cortex(fork_arm_data_out,
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
                                      fork_finger_sent_req_vec_out_array,
                                      fork_finger_new_vec_out_array,
                                      fork_finger_ready_vec_in_array,
                                      fork_finger_vc_no_vec_out,
                                             
                                      fork_fingers_data_in,
                                      fork_finger_sent_req_vec_in_array,
                                      fork_finger_new_vec_in_array,
                                      fork_finger_ready_vec_out_array,
                                      fork_finger_vc_no_vec_in,
                                                  
                                      busy,
                                      my_addr,
                                      rs,
                                      clk); 

always@(posedge active)
 if(want_vcd_files==1)
 begin
  if(head_zero_head_one==0 && my_fork_id==0)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_0.vcd");
  if(head_zero_head_one==0 && my_fork_id==1)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_1.vcd");
  if(head_zero_head_one==0 && my_fork_id==2)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_2.vcd");
  if(head_zero_head_one==0 && my_fork_id==3)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_3.vcd");
  if(head_zero_head_one==0 && my_fork_id==4)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_4.vcd");
  if(head_zero_head_one==0 && my_fork_id==5)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_5.vcd");
  if(head_zero_head_one==0 && my_fork_id==6)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_6.vcd");
  if(head_zero_head_one==0 && my_fork_id==7)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_7.vcd");
  if(head_zero_head_one==0 && my_fork_id==8)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_8.vcd");
  if(head_zero_head_one==0 && my_fork_id==9)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_9.vcd");
  if(head_zero_head_one==0 && my_fork_id==10)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_10.vcd");
  if(head_zero_head_one==0 && my_fork_id==11)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_11.vcd");
  if(head_zero_head_one==0 && my_fork_id==12)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_12.vcd");
  if(head_zero_head_one==0 && my_fork_id==13)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_13.vcd");
  if(head_zero_head_one==0 && my_fork_id==14)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_14.vcd");
  if(head_zero_head_one==0 && my_fork_id==15)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_15.vcd");
  if(head_zero_head_one==0 && my_fork_id==16)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_16.vcd");
  if(head_zero_head_one==0 && my_fork_id==17)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_17.vcd");
  if(head_zero_head_one==0 && my_fork_id==18)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_18.vcd");
  if(head_zero_head_one==0 && my_fork_id==19)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_19.vcd");
  if(head_zero_head_one==0 && my_fork_id==20)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_20.vcd");
  if(head_zero_head_one==0 && my_fork_id==21)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_21.vcd");
  if(head_zero_head_one==0 && my_fork_id==22)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_22.vcd");
  if(head_zero_head_one==0 && my_fork_id==23)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_23.vcd");
  if(head_zero_head_one==0 && my_fork_id==24)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_24.vcd");
  if(head_zero_head_one==0 && my_fork_id==25)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_25.vcd");
  if(head_zero_head_one==0 && my_fork_id==26)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_26.vcd");
  if(head_zero_head_one==0 && my_fork_id==27)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_27.vcd");
  if(head_zero_head_one==0 && my_fork_id==28)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_28.vcd");
  if(head_zero_head_one==0 && my_fork_id==29)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_29.vcd");
  if(head_zero_head_one==0 && my_fork_id==30)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_30.vcd");
  if(head_zero_head_one==0 && my_fork_id==31)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_31.vcd");
  if(head_zero_head_one==0 && my_fork_id==32)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_32.vcd");
  if(head_zero_head_one==0 && my_fork_id==33)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_33.vcd");
  if(head_zero_head_one==0 && my_fork_id==34)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_34.vcd");
  if(head_zero_head_one==0 && my_fork_id==35)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_35.vcd");
  if(head_zero_head_one==0 && my_fork_id==36)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_36.vcd");
  if(head_zero_head_one==0 && my_fork_id==37)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_37.vcd");
  if(head_zero_head_one==0 && my_fork_id==38)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_38.vcd");
  if(head_zero_head_one==0 && my_fork_id==39)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_39.vcd");
  if(head_zero_head_one==0 && my_fork_id==40)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_40.vcd");
  if(head_zero_head_one==0 && my_fork_id==41)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_41.vcd");
  if(head_zero_head_one==0 && my_fork_id==42)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_42.vcd");
  if(head_zero_head_one==0 && my_fork_id==43)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_43.vcd");
  if(head_zero_head_one==0 && my_fork_id==44)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_44.vcd");
  if(head_zero_head_one==0 && my_fork_id==45)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_45.vcd");
  if(head_zero_head_one==0 && my_fork_id==46)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_46.vcd");
  if(head_zero_head_one==0 && my_fork_id==47)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_47.vcd");
  if(head_zero_head_one==0 && my_fork_id==48)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_48.vcd");
  if(head_zero_head_one==0 && my_fork_id==49)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_49.vcd");
  if(head_zero_head_one==0 && my_fork_id==50)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_50.vcd");
  if(head_zero_head_one==0 && my_fork_id==51)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_51.vcd");
  if(head_zero_head_one==0 && my_fork_id==52)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_52.vcd");
  if(head_zero_head_one==0 && my_fork_id==53)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_53.vcd");
  if(head_zero_head_one==0 && my_fork_id==54)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_54.vcd");
  if(head_zero_head_one==0 && my_fork_id==55)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_55.vcd");
  if(head_zero_head_one==0 && my_fork_id==56)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_56.vcd");
  if(head_zero_head_one==0 && my_fork_id==57)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_57.vcd");
  if(head_zero_head_one==0 && my_fork_id==58)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_58.vcd");
  if(head_zero_head_one==0 && my_fork_id==59)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_59.vcd");
  if(head_zero_head_one==0 && my_fork_id==60)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_60.vcd");
  if(head_zero_head_one==0 && my_fork_id==61)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_61.vcd");
  if(head_zero_head_one==0 && my_fork_id==62)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_62.vcd");
  if(head_zero_head_one==0 && my_fork_id==63)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_63.vcd");
  if(head_zero_head_one==0 && my_fork_id==64)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_64.vcd");
  if(head_zero_head_one==0 && my_fork_id==65)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_65.vcd");
  if(head_zero_head_one==0 && my_fork_id==66)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_66.vcd");
  if(head_zero_head_one==0 && my_fork_id==67)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_67.vcd");
  if(head_zero_head_one==0 && my_fork_id==68)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_68.vcd");
  if(head_zero_head_one==0 && my_fork_id==69)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_69.vcd");
  if(head_zero_head_one==0 && my_fork_id==70)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_70.vcd");
  if(head_zero_head_one==0 && my_fork_id==71)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_71.vcd");
  if(head_zero_head_one==0 && my_fork_id==72)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_72.vcd");
  if(head_zero_head_one==0 && my_fork_id==73)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_73.vcd");
  if(head_zero_head_one==0 && my_fork_id==74)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_74.vcd");
  if(head_zero_head_one==0 && my_fork_id==75)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_75.vcd");
  if(head_zero_head_one==0 && my_fork_id==76)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_76.vcd");
  if(head_zero_head_one==0 && my_fork_id==77)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_77.vcd");
  if(head_zero_head_one==0 && my_fork_id==78)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_78.vcd");
  if(head_zero_head_one==0 && my_fork_id==79)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_79.vcd");
  if(head_zero_head_one==0 && my_fork_id==80)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_80.vcd");
  if(head_zero_head_one==0 && my_fork_id==81)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_81.vcd");
  if(head_zero_head_one==0 && my_fork_id==82)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_82.vcd");
  if(head_zero_head_one==0 && my_fork_id==83)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_83.vcd");
  if(head_zero_head_one==0 && my_fork_id==84)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_84.vcd");
  if(head_zero_head_one==0 && my_fork_id==85)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_85.vcd");
  if(head_zero_head_one==0 && my_fork_id==86)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_86.vcd");
  if(head_zero_head_one==0 && my_fork_id==87)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_87.vcd");
  if(head_zero_head_one==0 && my_fork_id==88)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_88.vcd");
  if(head_zero_head_one==0 && my_fork_id==89)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_89.vcd");
  if(head_zero_head_one==0 && my_fork_id==90)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_90.vcd");
  if(head_zero_head_one==0 && my_fork_id==91)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_91.vcd");
  if(head_zero_head_one==0 && my_fork_id==92)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_92.vcd");
  if(head_zero_head_one==0 && my_fork_id==93)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_93.vcd");
  if(head_zero_head_one==0 && my_fork_id==94)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_94.vcd");
  if(head_zero_head_one==0 && my_fork_id==95)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_95.vcd");
  if(head_zero_head_one==0 && my_fork_id==96)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_96.vcd");
  if(head_zero_head_one==0 && my_fork_id==97)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_97.vcd");
  if(head_zero_head_one==0 && my_fork_id==98)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_98.vcd");
  if(head_zero_head_one==0 && my_fork_id==99)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_zero_99.vcd");
  if(head_zero_head_one==1 && my_fork_id==0)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_0.vcd");
  if(head_zero_head_one==1 && my_fork_id==1)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_1.vcd");
  if(head_zero_head_one==1 && my_fork_id==2)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_2.vcd");
  if(head_zero_head_one==1 && my_fork_id==3)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_3.vcd");
  if(head_zero_head_one==1 && my_fork_id==4)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_4.vcd");
  if(head_zero_head_one==1 && my_fork_id==5)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_5.vcd");
  if(head_zero_head_one==1 && my_fork_id==6)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_6.vcd");
  if(head_zero_head_one==1 && my_fork_id==7)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_7.vcd");
  if(head_zero_head_one==1 && my_fork_id==8)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_8.vcd");
  if(head_zero_head_one==1 && my_fork_id==9)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_9.vcd");
  if(head_zero_head_one==1 && my_fork_id==10)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_10.vcd");
  if(head_zero_head_one==1 && my_fork_id==11)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_11.vcd");
  if(head_zero_head_one==1 && my_fork_id==12)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_12.vcd");
  if(head_zero_head_one==1 && my_fork_id==13)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_13.vcd");
  if(head_zero_head_one==1 && my_fork_id==14)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_14.vcd");
  if(head_zero_head_one==1 && my_fork_id==15)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_15.vcd");
  if(head_zero_head_one==1 && my_fork_id==16)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_16.vcd");
  if(head_zero_head_one==1 && my_fork_id==17)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_17.vcd");
  if(head_zero_head_one==1 && my_fork_id==18)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_18.vcd");
  if(head_zero_head_one==1 && my_fork_id==19)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_19.vcd");
  if(head_zero_head_one==1 && my_fork_id==20)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_20.vcd");
  if(head_zero_head_one==1 && my_fork_id==21)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_21.vcd");
  if(head_zero_head_one==1 && my_fork_id==22)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_22.vcd");
  if(head_zero_head_one==1 && my_fork_id==23)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_23.vcd");
  if(head_zero_head_one==1 && my_fork_id==24)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_24.vcd");
  if(head_zero_head_one==1 && my_fork_id==25)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_25.vcd");
  if(head_zero_head_one==1 && my_fork_id==26)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_26.vcd");
  if(head_zero_head_one==1 && my_fork_id==27)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_27.vcd");
  if(head_zero_head_one==1 && my_fork_id==28)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_28.vcd");
  if(head_zero_head_one==1 && my_fork_id==29)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_29.vcd");
  if(head_zero_head_one==1 && my_fork_id==30)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_30.vcd");
  if(head_zero_head_one==1 && my_fork_id==31)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_31.vcd");
  if(head_zero_head_one==1 && my_fork_id==32)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_32.vcd");
  if(head_zero_head_one==1 && my_fork_id==33)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_33.vcd");
  if(head_zero_head_one==1 && my_fork_id==34)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_34.vcd");
  if(head_zero_head_one==1 && my_fork_id==35)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_35.vcd");
  if(head_zero_head_one==1 && my_fork_id==36)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_36.vcd");
  if(head_zero_head_one==1 && my_fork_id==37)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_37.vcd");
  if(head_zero_head_one==1 && my_fork_id==38)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_38.vcd");
  if(head_zero_head_one==1 && my_fork_id==39)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_39.vcd");
  if(head_zero_head_one==1 && my_fork_id==40)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_40.vcd");
  if(head_zero_head_one==1 && my_fork_id==41)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_41.vcd");
  if(head_zero_head_one==1 && my_fork_id==42)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_42.vcd");
  if(head_zero_head_one==1 && my_fork_id==43)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_43.vcd");
  if(head_zero_head_one==1 && my_fork_id==44)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_44.vcd");
  if(head_zero_head_one==1 && my_fork_id==45)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_45.vcd");
  if(head_zero_head_one==1 && my_fork_id==46)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_46.vcd");
  if(head_zero_head_one==1 && my_fork_id==47)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_47.vcd");
  if(head_zero_head_one==1 && my_fork_id==48)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_48.vcd");
  if(head_zero_head_one==1 && my_fork_id==49)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_49.vcd");
  if(head_zero_head_one==1 && my_fork_id==50)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_50.vcd");
  if(head_zero_head_one==1 && my_fork_id==51)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_51.vcd");
  if(head_zero_head_one==1 && my_fork_id==52)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_52.vcd");
  if(head_zero_head_one==1 && my_fork_id==53)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_53.vcd");
  if(head_zero_head_one==1 && my_fork_id==54)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_54.vcd");
  if(head_zero_head_one==1 && my_fork_id==55)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_55.vcd");
  if(head_zero_head_one==1 && my_fork_id==56)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_56.vcd");
  if(head_zero_head_one==1 && my_fork_id==57)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_57.vcd");
  if(head_zero_head_one==1 && my_fork_id==58)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_58.vcd");
  if(head_zero_head_one==1 && my_fork_id==59)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_59.vcd");
  if(head_zero_head_one==1 && my_fork_id==60)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_60.vcd");
  if(head_zero_head_one==1 && my_fork_id==61)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_61.vcd");
  if(head_zero_head_one==1 && my_fork_id==62)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_62.vcd");
  if(head_zero_head_one==1 && my_fork_id==63)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_63.vcd");
  if(head_zero_head_one==1 && my_fork_id==64)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_64.vcd");
  if(head_zero_head_one==1 && my_fork_id==65)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_65.vcd");
  if(head_zero_head_one==1 && my_fork_id==66)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_66.vcd");
  if(head_zero_head_one==1 && my_fork_id==67)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_67.vcd");
  if(head_zero_head_one==1 && my_fork_id==68)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_68.vcd");
  if(head_zero_head_one==1 && my_fork_id==69)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_69.vcd");
  if(head_zero_head_one==1 && my_fork_id==70)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_70.vcd");
  if(head_zero_head_one==1 && my_fork_id==71)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_71.vcd");
  if(head_zero_head_one==1 && my_fork_id==72)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_72.vcd");
  if(head_zero_head_one==1 && my_fork_id==73)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_73.vcd");
  if(head_zero_head_one==1 && my_fork_id==74)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_74.vcd");
  if(head_zero_head_one==1 && my_fork_id==75)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_75.vcd");
  if(head_zero_head_one==1 && my_fork_id==76)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_76.vcd");
  if(head_zero_head_one==1 && my_fork_id==77)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_77.vcd");
  if(head_zero_head_one==1 && my_fork_id==78)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_78.vcd");
  if(head_zero_head_one==1 && my_fork_id==79)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_79.vcd");
  if(head_zero_head_one==1 && my_fork_id==80)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_80.vcd");
  if(head_zero_head_one==1 && my_fork_id==81)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_81.vcd");
  if(head_zero_head_one==1 && my_fork_id==82)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_82.vcd");
  if(head_zero_head_one==1 && my_fork_id==83)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_83.vcd");
  if(head_zero_head_one==1 && my_fork_id==84)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_84.vcd");
  if(head_zero_head_one==1 && my_fork_id==85)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_85.vcd");
  if(head_zero_head_one==1 && my_fork_id==86)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_86.vcd");
  if(head_zero_head_one==1 && my_fork_id==87)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_87.vcd");
  if(head_zero_head_one==1 && my_fork_id==88)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_88.vcd");
  if(head_zero_head_one==1 && my_fork_id==89)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_89.vcd");
  if(head_zero_head_one==1 && my_fork_id==90)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_90.vcd");
  if(head_zero_head_one==1 && my_fork_id==91)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_91.vcd");
  if(head_zero_head_one==1 && my_fork_id==92)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_92.vcd");
  if(head_zero_head_one==1 && my_fork_id==93)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_93.vcd");
  if(head_zero_head_one==1 && my_fork_id==94)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_94.vcd");
  if(head_zero_head_one==1 && my_fork_id==95)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_95.vcd");
  if(head_zero_head_one==1 && my_fork_id==96)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_96.vcd");
  if(head_zero_head_one==1 && my_fork_id==97)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_97.vcd");
  if(head_zero_head_one==1 && my_fork_id==98)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_98.vcd");
  if(head_zero_head_one==1 && my_fork_id==99)$fdumpvars(2,sv_fork_module.fork_module_cortex,"./dump_files/fork_head_one_99.vcd");
  if(my_fork_id>99) $display("Max number of forks is 100!!!");   
 end                       
endmodule