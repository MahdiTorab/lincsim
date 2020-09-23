`timescale 1ns/10ps
module router_cortex(outdata_vec,
                     outsent_req_vec,
                     outnew_vec,
                     inready_vec,
                     outvc_no_vec,
           
                     indata_vec,
                     insent_req_vec,
                     innew_vec,
                     outready_vec,
                     invc_no_vec,
              
                     busy,
                     my_addr,
                     node_links_directions,
                     have_fork_port,
                     have_express_port,
                     reset,
                     clk);

parameter each_cluster_dimension=3;
parameter cluster_topology=0;         //0:Mesh, 1:Torus
parameter cluster_first_dimension_up_bound=1;
parameter cluster_second_dimension_up_bound=1;
parameter cluster_third_dimension_up_bound=1;
parameter no_clusters=1;
parameter cluster_first_dimension_no_addr_bits=1;
parameter cluster_second_dimension_no_addr_bits=1;
parameter cluster_third_dimension_no_addr_bits=1;
parameter no_cluster_no_addr_bits=1;
parameter no_outport=7;
parameter floorplusone_log2_no_outport=3;
parameter no_inport=7;
parameter floorplusone_log2_no_inport=3;
parameter no_vc=4;
parameter floorplusone_log2_no_vc=3;
parameter flit_size=1;                //In number of phits
parameter floorplusone_log2_flit_size=1;
parameter phit_size=32;               //In number of bits
parameter buf_size=4;                 //In number of flits
parameter floorplusone_log2_buf_size=3;
parameter switching_method=3;         //1 to Store&forward, 2 to VCT, 3 to Wormhole switching
parameter addr_length=4;              //In number of bits
parameter addr_place_in_header=0;     //bit number in header that address start
parameter my_type=0;
parameter want_routers_power_estimation= 1;   //0: If you don't want to run Design Compiler flow to estimate routers power, 1:If you want routers power estimation (guide for more details)
parameter is_netlist_provided= 1;             //0: If you want estimate routers power and provide netlists set it to 1, else 0 (guide for more details)

output [(no_outport*phit_size)-1:0] outdata_vec;
output [(no_outport-1):0] outsent_req_vec,outnew_vec;
input [(no_outport-1):0] inready_vec;
output [(no_outport*floorplusone_log2_no_vc)-1:0] outvc_no_vec;

input [(no_inport*phit_size)-1:0] indata_vec;
input [(no_inport-1):0] insent_req_vec,innew_vec;
output [(no_inport-1):0] outready_vec;
input [(no_inport*floorplusone_log2_no_vc)-1:0] invc_no_vec;

output busy;
input [(addr_length-1):0] my_addr;
input [31:0] node_links_directions;
input have_fork_port,have_express_port;
input reset,clk;

generate 
 if(want_routers_power_estimation==1 && is_netlist_provided==1 && my_type==0)
  router_type_0_netlist router_type_0_netlist(outdata_vec,
                                              outsent_req_vec,
                                              outnew_vec,
                                              inready_vec,
                                              outvc_no_vec,
           
                                              indata_vec,
                                              insent_req_vec,
                                              innew_vec,
                                              outready_vec,
                                              invc_no_vec,
               
                                              busy,
                                              my_addr,
                                              node_links_directions,
                                              have_fork_port,
                                              have_express_port,
                                              reset,
                                              clk);
                                              
 else if(want_routers_power_estimation==1 && is_netlist_provided==1 && my_type==1)
  router_type_1_netlist router_type_1_netlist(outdata_vec,
                                              outsent_req_vec,
                                              outnew_vec,
                                              inready_vec,
                                              outvc_no_vec,
           
                                              indata_vec,
                                              insent_req_vec,
                                              innew_vec,
                                              outready_vec,
                                              invc_no_vec,
               
                                              busy,
                                              my_addr,
                                              node_links_directions,
                                              have_fork_port,
                                              have_express_port,
                                              reset,
                                              clk);
                                              
 else if(want_routers_power_estimation==1 && is_netlist_provided==1 && my_type==2)
  router_type_2_netlist router_type_2_netlist(outdata_vec,
                                              outsent_req_vec,
                                              outnew_vec,
                                              inready_vec,
                                              outvc_no_vec,
           
                                              indata_vec,
                                              insent_req_vec,
                                              innew_vec,
                                              outready_vec,
                                              invc_no_vec,
               
                                              busy,
                                              my_addr,
                                              node_links_directions,
                                              have_fork_port,
                                              have_express_port,
                                              reset,
                                              clk);
                                              
 else if(want_routers_power_estimation==1 && is_netlist_provided==1 && my_type==3)
  router_type_3_netlist router_type_3_netlist(outdata_vec,
                                              outsent_req_vec,
                                              outnew_vec,
                                              inready_vec,
                                              outvc_no_vec,
           
                                              indata_vec,
                                              insent_req_vec,
                                              innew_vec,
                                              outready_vec,
                                              invc_no_vec,
               
                                              busy,
                                              my_addr,
                                              node_links_directions,
                                              have_fork_port,
                                              have_express_port,
                                              reset,
                                              clk);
                                              
 else if(want_routers_power_estimation==1 && is_netlist_provided==1 && my_type==4)
  router_type_4_netlist router_type_4_netlist(outdata_vec,
                                              outsent_req_vec,
                                              outnew_vec,
                                              inready_vec,
                                              outvc_no_vec,
           
                                              indata_vec,
                                              insent_req_vec,
                                              innew_vec,
                                              outready_vec,
                                              invc_no_vec,
               
                                              busy,
                                              my_addr,
                                              node_links_directions,
                                              have_fork_port,
                                              have_express_port,
                                              reset,
                                              clk);
                                              
 else if(want_routers_power_estimation==1 && is_netlist_provided==1 && my_type==5)
  router_type_5_netlist router_type_5_netlist(outdata_vec,
                                              outsent_req_vec,
                                              outnew_vec,
                                              inready_vec,
                                              outvc_no_vec,
           
                                              indata_vec,
                                              insent_req_vec,
                                              innew_vec,
                                              outready_vec,
                                              invc_no_vec,
               
                                              busy,
                                              my_addr,
                                              node_links_directions,
                                              have_fork_port,
                                              have_express_port,
                                              reset,
                                              clk);
                                              
 else if(want_routers_power_estimation==1 && is_netlist_provided==1 && my_type==6)
  router_type_6_netlist router_type_6_netlist(outdata_vec,
                                              outsent_req_vec,
                                              outnew_vec,
                                              inready_vec,
                                              outvc_no_vec,
           
                                              indata_vec,
                                              insent_req_vec,
                                              innew_vec,
                                              outready_vec,
                                              invc_no_vec,
               
                                              busy,
                                              my_addr,
                                              node_links_directions,
                                              have_fork_port,
                                              have_express_port,
                                              reset,
                                              clk);
                                              
 else if(want_routers_power_estimation==1 && is_netlist_provided==1 && my_type==7)
  router_type_7_netlist router_type_7_netlist(outdata_vec,
                                              outsent_req_vec,
                                              outnew_vec,
                                              inready_vec,
                                              outvc_no_vec,
           
                                              indata_vec,
                                              insent_req_vec,
                                              innew_vec,
                                              outready_vec,
                                              invc_no_vec,
               
                                              busy,
                                              my_addr,
                                              node_links_directions,
                                              have_fork_port,
                                              have_express_port,
                                              reset,
                                              clk);
                                              
 else 
  begin
   router#(each_cluster_dimension,
           cluster_topology,
           cluster_first_dimension_up_bound,
           cluster_second_dimension_up_bound,
           cluster_third_dimension_up_bound,
           no_clusters,
           cluster_first_dimension_no_addr_bits,
           cluster_second_dimension_no_addr_bits,
           cluster_third_dimension_no_addr_bits,
           no_cluster_no_addr_bits,
           no_outport,
           floorplusone_log2_no_outport,
           no_inport,
           floorplusone_log2_no_inport,
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
   
    router(outdata_vec,
           outsent_req_vec,
           outnew_vec,
           inready_vec,
           outvc_no_vec,
           
           indata_vec,
           insent_req_vec,
           innew_vec,
           outready_vec,
           invc_no_vec,
              
           busy,
           my_addr,
           node_links_directions,
           have_fork_port,
           have_express_port,
           reset,
           clk);
  end  
endgenerate

endmodule
