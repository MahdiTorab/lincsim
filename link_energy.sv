`timescale 1ns/10ps
module link_energy(link_energy_consumption,
                   link_class_out,
                   my_addr,
                   report_addr,
                   data,
                   sent_req,
                   new_sig,
                   ready,
                   vc_no,
                   rs,
                   clk);

parameter floorplusone_log2_no_vc=4;
parameter phit_size=16;
parameter link_addr_length=8;
parameter link_type=0;                    //0:wire link, 1:other(wireless or optic) link
parameter capacitance=10;                 //in femto_Farad
parameter voltage=3.3;
parameter energy_per_bit_for_non_wire=10; //just for non_wire links in femto_Joule
parameter fork_arm_width=10;              //this parameter detemine how much fork_arm is powerfull than an outport
parameter [3:0] link_class=0;             //0: not valid, 1:first_dimension_link, 2:second_dimension_link, 3:third_dimension_link,
                                          //4:express_link ,5:fork_finger_link, 6:fork_arm_link, else: reserved

localparam energy_consumption_per_bit=(link_type==0)?0.5*capacitance*(voltage**2):energy_per_bit_for_non_wire;

output tri [63:0] link_energy_consumption;
output tri [3:0] link_class_out;
input [(link_addr_length-1):0] my_addr;
input [(link_addr_length-1):0] report_addr;
input [((link_class==6)?(fork_arm_width*phit_size):phit_size)-1:0] data;
input [((link_class==6)?fork_arm_width:1)-1:0] sent_req,new_sig,ready;
input [((link_class==6)?(fork_arm_width*floorplusone_log2_no_vc):floorplusone_log2_no_vc)-1:0] vc_no;
input rs,clk;

wire [63:0] tmp_link_energy_consumption;

reg [63:0] data_energy_consumption,sent_req_energy_consumption,new_sig_energy_consumption,
           ready_signal_energy_consumption,vc_no_energy_consumption;

genvar i;

generate for(i=0;i<64;i++) begin: link_energy_consumption_loop
  assign link_energy_consumption[i]= (my_addr==report_addr)? tmp_link_energy_consumption[i]:1'bz;
 end
endgenerate

generate for(i=0;i<4;i++) begin: link_class_out_loop
  assign link_class_out[i]= (my_addr==report_addr)? link_class[i]:1'bz;
 end
endgenerate

generate for(i=0;i<((link_class==6)?(fork_arm_width*phit_size):phit_size);i++) begin: data_energy_consumption_loop             
 always@(data[i])
  begin
   if(rs) data_energy_consumption=0;
   else data_energy_consumption=data_energy_consumption+energy_consumption_per_bit;
  end
 end
endgenerate            

generate for(i=0;i<((link_class==6)?fork_arm_width:1);i++) begin: sent_req_energy_consumption_loop
 always@(sent_req[i])
  begin
   if(rs) sent_req_energy_consumption=0;
   else sent_req_energy_consumption=sent_req_energy_consumption+energy_consumption_per_bit;
  end
 end
endgenerate

generate for(i=0;i<((link_class==6)?fork_arm_width:1);i++) begin: new_sig_energy_consumption_loop
 always@(new_sig[i])
  begin
   if(rs) new_sig_energy_consumption=0;
   else new_sig_energy_consumption=new_sig_energy_consumption+energy_consumption_per_bit;
  end
 end
endgenerate

generate for(i=0;i<((link_class==6)?fork_arm_width:1);i++) begin: ready_signal_energy_consumption_loop
 always@(ready[i])
  begin
   if(rs) ready_signal_energy_consumption=0;
   else ready_signal_energy_consumption=ready_signal_energy_consumption+energy_consumption_per_bit;
  end
 end
endgenerate
                                                                                        
generate for(i=0;i<((link_class==6)?(fork_arm_width*floorplusone_log2_no_vc):floorplusone_log2_no_vc);i++) begin:vc_no_energy_consumption_loop             
 always@(vc_no[i])
  begin
   if(rs) vc_no_energy_consumption=0;
   else vc_no_energy_consumption=vc_no_energy_consumption+energy_consumption_per_bit;
  end
 end
endgenerate 

assign tmp_link_energy_consumption= vc_no_energy_consumption+ready_signal_energy_consumption+new_sig_energy_consumption+
                                    sent_req_energy_consumption+data_energy_consumption;                                                                                        

endmodule