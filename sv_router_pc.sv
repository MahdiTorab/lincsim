`timescale 1ns/10ps
module sv_router_pc(out_data_array,
                    sent_req_out_array,
                    new_out_array,
                    ready_in,
                    vc_no_out_array,
                 
                    data_in_array,
                    sent_req_in_array,
                    new_in_array,
                    ready_out_array,
                    vc_no_in_array,

                    average_time_of_flies_report,
                    no_packet_recieve_report,
                    busy,
                    active,
                    syn_or_real,
                    syn_pattern,
                    program_active,
                    source_addr_from_manager,
                    dest_addr,
                    hotspot_addr,
                    inject_time,
                    packet_length,
                    log_file,
                    pe_id,
                    report_enable,
                    report_reset,
                    full_reset,
                    clk);

parameter each_cluster_dimension=2;
parameter cluster_topology=0; //0:Mesh, 1:Torus
parameter cluster_first_dimension_up_bound=8;
parameter cluster_second_dimension_up_bound=8;
parameter cluster_third_dimension_up_bound=5;
parameter no_clusters=5;
parameter cluster_first_dimension_no_addr_bits=1;
parameter cluster_second_dimension_no_addr_bits=1;
parameter cluster_third_dimension_no_addr_bits=1;
parameter no_cluster_no_addr_bits=1;
parameter have_fork_port=0;
parameter have_express_port=0;
parameter local_traffic_domain=5;
parameter percentage_of_locality=100;
parameter percentage_of_hotspot=50;
parameter injection_rate=0.01;
parameter no_outport=4;
parameter no_inport=6;
parameter no_vc=13;
parameter flit_size=1;                   //In number of phits
parameter phit_size=16;                  //In number of bits
parameter switching_method=1;            //1 to Store&forward, 2 to VCT, 3 to Wormhole switching
parameter buf_size=4;                    //In number of flits
parameter addr_length=8;                 //In number of bits
parameter addr_place_in_header=0;        //bit number in header that address start
parameter [(addr_length-1):0] my_addr=0;
parameter [3:0] my_type=1;
parameter [31:0] node_links_directions=0;
parameter want_vcd_files=1;              //0: no vcd file generation, 1: vcd file generation
parameter want_routers_power_estimation= 1;   //0: If you don't want to run Design Compiler flow to estimate routers power, 1:If you want routers power estimation (guide for more details)
parameter is_netlist_provided= 1;             //0: If you want estimate routers power and provide netlists set it to 1, else 0 (guide for more details)
parameter no_nodes=10;

output [(phit_size-1):0] out_data_array [(no_outport-1):0];
output [(no_outport-1):0] sent_req_out_array;
output [(no_outport-1):0] new_out_array;
input [(no_outport-1):0] ready_in;
output [($clog2(no_vc+1)-1):0] vc_no_out_array [(no_outport-1):0];
 
input [(phit_size-1):0] data_in_array [(no_inport-1):0];
input [(no_inport-1):0] sent_req_in_array;
input [(no_inport-1):0] new_in_array;
output [(no_inport-1):0] ready_out_array;
input [($clog2(no_vc+1)-1):0] vc_no_in_array [(no_inport-1):0];

output [31:0] average_time_of_flies_report;
output [31:0] no_packet_recieve_report;
output busy;
input active;
input syn_or_real;
input [2:0] syn_pattern;
input program_active;
input [(addr_length-1):0] source_addr_from_manager;
input [(addr_length-1):0] dest_addr;
input [(addr_length-1):0] hotspot_addr;
input integer inject_time;
input integer packet_length;
input integer log_file,pe_id;
input report_enable;
input report_reset,full_reset,clk;

wire [(phit_size-1):0] data_out_array_from_router [no_outport:0];
wire [no_outport:0] sent_req_out_array_from_router;
wire [no_outport:0] new_out_array_from_router;
wire [no_outport:0] ready_in_array_to_router;
wire [($clog2(no_vc+1)-1):0] vc_no_out_array_from_router [no_outport:0];
wire [(phit_size-1):0] data_in_array_to_router [no_inport:0];
wire [no_inport:0] sent_req_in_array_to_router;
wire [no_inport:0] new_in_array_to_router;
wire [no_inport:0] ready_out_array_from_router;
wire [($clog2(no_vc+1)-1):0] vc_no_in_array_to_router [no_inport:0];
wire router_busy,produce_mem_busy;
integer pe_id_reg;

genvar i;

generate for(i=0;i<no_outport;i++) begin: outports_loop
  assign out_data_array[i]= data_out_array_from_router[i+1];
  assign sent_req_out_array[i]= sent_req_out_array_from_router[i+1];
  assign new_out_array[i]= new_out_array_from_router[i+1];
  assign ready_in_array_to_router[i+1]= ready_in[i];
  assign vc_no_out_array[i]= vc_no_out_array_from_router[i+1]; 
 end
endgenerate

generate for(i=0;i<no_inport;i++) begin: inports_loop
  assign data_in_array_to_router[i+1]= data_in_array[i];
  assign sent_req_in_array_to_router[i+1]= sent_req_in_array[i];
  assign new_in_array_to_router[i+1]= new_in_array[i];
  assign ready_out_array[i]= ready_out_array_from_router[i+1];
  assign vc_no_in_array_to_router[i+1]= vc_no_in_array[i];
 end
endgenerate

defparam sv_router.each_cluster_dimension=each_cluster_dimension;
defparam sv_router.cluster_topology=cluster_topology;
defparam sv_router.cluster_first_dimension_up_bound=cluster_first_dimension_up_bound;
defparam sv_router.cluster_second_dimension_up_bound=cluster_second_dimension_up_bound;
defparam sv_router.cluster_third_dimension_up_bound=cluster_third_dimension_up_bound;
defparam sv_router.no_clusters=no_clusters;
defparam sv_router.cluster_first_dimension_no_addr_bits=cluster_first_dimension_no_addr_bits;
defparam sv_router.cluster_second_dimension_no_addr_bits=cluster_second_dimension_no_addr_bits;
defparam sv_router.cluster_third_dimension_no_addr_bits=cluster_third_dimension_no_addr_bits;
defparam sv_router.no_cluster_no_addr_bits=no_cluster_no_addr_bits;
defparam sv_router.have_fork_port=have_fork_port;
defparam sv_router.have_express_port=have_express_port;
defparam sv_router.no_outport=no_outport+1;
defparam sv_router.floorplusone_log2_no_outport=$clog2(no_outport+1+1);
defparam sv_router.no_inport=no_inport+1;
defparam sv_router.floorplusone_log2_no_inport=$clog2(no_inport+1+1);
defparam sv_router.no_vc=no_vc;
defparam sv_router.floorplusone_log2_no_vc=$clog2(no_vc+1);
defparam sv_router.flit_size=flit_size;
defparam sv_router.floorplusone_log2_flit_size=$clog2(flit_size+1);
defparam sv_router.phit_size=phit_size;
defparam sv_router.buf_size=buf_size;
defparam sv_router.floorplusone_log2_buf_size=$clog2(buf_size+1);
defparam sv_router.switching_method=switching_method;
defparam sv_router.addr_length=addr_length;
defparam sv_router.addr_place_in_header=addr_place_in_header;
defparam sv_router.my_type=my_type;
defparam sv_router.node_links_directions=node_links_directions;
defparam sv_router.want_vcd_files=want_vcd_files;
defparam sv_router.want_routers_power_estimation=want_routers_power_estimation;
defparam sv_router.is_netlist_provided=is_netlist_provided;

sv_router sv_router(data_out_array_from_router,
                    sent_req_out_array_from_router,
                    new_out_array_from_router,
                    ready_in_array_to_router,
                    vc_no_out_array_from_router,
                    data_in_array_to_router,
                    sent_req_in_array_to_router,
                    new_in_array_to_router,
                    ready_out_array_from_router,
                    vc_no_in_array_to_router,
                    router_busy,
                    my_addr,
                    pe_id_reg,
                    active,
                    full_reset,
                    clk);

defparam producer_and_consumer.each_cluster_dimension=each_cluster_dimension;
defparam producer_and_consumer.cluster_topology=cluster_topology;
defparam producer_and_consumer.cluster_first_dimension_up_bound=cluster_first_dimension_up_bound;
defparam producer_and_consumer.cluster_second_dimension_up_bound=cluster_second_dimension_up_bound;
defparam producer_and_consumer.cluster_third_dimension_up_bound=cluster_third_dimension_up_bound;
defparam producer_and_consumer.cluster_first_dimension_no_addr_bits=cluster_first_dimension_no_addr_bits;
defparam producer_and_consumer.cluster_second_dimension_no_addr_bits=cluster_second_dimension_no_addr_bits;
defparam producer_and_consumer.cluster_third_dimension_no_addr_bits=cluster_third_dimension_no_addr_bits;
defparam producer_and_consumer.no_cluster_no_addr_bits=no_cluster_no_addr_bits;
defparam producer_and_consumer.no_clusters=no_clusters;
defparam producer_and_consumer.local_traffic_domain=local_traffic_domain;
defparam producer_and_consumer.percentage_of_locality=percentage_of_locality;
defparam producer_and_consumer.percentage_of_hotspot=percentage_of_hotspot;
defparam producer_and_consumer.flit_size=flit_size;
defparam producer_and_consumer.floorplusone_log2_flit_size=$clog2(flit_size+1);
defparam producer_and_consumer.phit_size=phit_size;
defparam producer_and_consumer.addr_place_in_header=addr_place_in_header;
defparam producer_and_consumer.addr_length=addr_length;
defparam producer_and_consumer.injection_rate=injection_rate;
defparam producer_and_consumer.my_addr=my_addr;
defparam producer_and_consumer.no_vc=no_vc;
defparam producer_and_consumer.floorplusone_log2_no_vc=$clog2(no_vc+1);
defparam producer_and_consumer.no_nodes=no_nodes;
producer_and_consumer producer_and_consumer(data_in_array_to_router[0],
                                            sent_req_in_array_to_router[0],
                                            new_in_array_to_router[0],
                                            ready_out_array_from_router[0],
                                            vc_no_in_array_to_router[0],
                                           
                                            data_out_array_from_router[0],
                                            sent_req_out_array_from_router[0],
                                            new_out_array_from_router[0],
                                            ready_in_array_to_router[0],
                                            vc_no_out_array_from_router[0],

                                            average_time_of_flies_report,
                                            no_packet_recieve_report,
                                            produce_mem_busy,
                                            active,
                                            syn_or_real,
                                            syn_pattern,
                                            program_active,
                                            source_addr_from_manager,
                                            dest_addr,
                                            hotspot_addr,
                                            inject_time,
                                            packet_length,
                                            report_enable,
                                            log_file,
                                            pe_id_reg,
                             
                                            report_reset,
                                            full_reset,
                                            clk);
                                            
assign busy= router_busy|produce_mem_busy;                                             
                                            
always@(posedge clk)
 if(program_active && source_addr_from_manager==my_addr)pe_id_reg= pe_id;
                                           
                                                                                    
endmodule