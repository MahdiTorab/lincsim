module simulator_top;

//Topology Parameters
parameter no_clusters=1;
parameter each_cluster_dimension=2;
parameter cluster_topology=0;                       //0:Mesh, 1:Torus
parameter cluster_first_dimension_up_bound=7;
parameter cluster_second_dimension_up_bound=6;
parameter cluster_third_dimension_up_bound=0;
parameter have_fork=0;                              //0: there is no fork, 1: there is fork(s)
parameter no_fork=2;                                //number of forks between clusters
parameter no_fork_fingers=5;                        //number of fingers that every fork have
parameter fork_arm_width=2;                         //this parameter detemine how much fork_arm is powerfull than an outport
parameter have_express_link=0;                      //0: there is no express_link, 1: there is express_link(s)
parameter no_express_link=10;                       //number of express_link(s)


//Routers Parameters
parameter no_vc= 4;                     //Number of virtual channel per port
parameter flit_size= 1;                 //In number of phits
parameter phit_size= 32;                //In number of bits
parameter switching_method= 3;          //1 to Store&forward, 2 to VCT, 3 to Wormhole switching
parameter buffer_size= 1;               //In number of flits. If switching_method is Wormhole it automatically set to 1
parameter addr_place_in_header= 0;      //bit number in header that address start


//Traffic Parameters
parameter local_traffic_domain= 3;
parameter percentage_of_locality= 50;
parameter percentage_of_hotspot= 80;
parameter hotspot_id= 13;
parameter injection_rate= 0.2;
parameter simulation_time_per_injection_rate_point=500000;     //Just for synthetic
parameter warm_up_time= 2000;                                  //for both synthetic and real traffic
parameter syn_or_real= 1;                                      //If synthetic traffic set to 0 ,If real set to 1
parameter [2:0] syn_pattern= 3'b000;                           //3'b000:Uniform ,3'b001:Local ,3'b010:Hotspot ,else:Reserved
parameter syn_packet_length= 10;                               //This parameter determine synthetic traffic packet_length
parameter traffic_real_no_packet= 0;                           //This parameter determine how many packet from tracefile injected to network, Set it to zero for all packets
parameter traffic_extension= 8;                                //Extending real traffic, means lower injection rate (only for real traffic!)
parameter string trace_file_name="ocean.txt";                  //Please insert trace file name


//Links Parameters
parameter voltage= 1;                                                  //in Volt

parameter cluster_first_dimension_link_type= 0;                          //0:wire link, 1:other(wireless or optic) link(planar)
parameter cluster_first_dimension_link_capacitance= 1000;                //in femto_Farad
parameter cluster_first_dimension_link_energy_per_bit_for_non_wire= 10;//For non_wire links in femto_Joule

parameter cluster_second_dimension_link_type= 0;                         //0:wire link, 1:other(wireless or optic) link(planar)
parameter cluster_second_dimension_link_capacitance= 1200;               //in femto_Farad
parameter cluster_second_dimension_link_energy_per_bit_for_non_wire= 10; //For non_wire links in femto_Joule

parameter cluster_third_dimension_link_type= 0;                          //0:wire link, 1:other(wireless or optic) link(TSVs)
parameter cluster_third_dimension_link_capacitance= 400;                 //in femto_Farad
parameter cluster_third_dimension_link_energy_per_bit_for_non_wire= 10;  //For non_wire links in femto_Joule

parameter express_link_type= 0;                                    //0:wire link, 1:other(wireless or optic) link(TSVs)
parameter express_link_capacitance= 500;                           //in femto_Farad
parameter express_link_energy_per_bit_for_non_wire= 10;            //For non_wire links in femto_Joule

parameter fork_finger_link_type= 0;                                      //0:wire link, 1:other(wireless or optic) link(TSVs)
parameter fork_finger_capacitance= 10;                                   //in femto_Farad
parameter fork_finger_link_energy_per_bit_for_non_wire= 10;              //For non_wire links in femto_Joule

parameter fork_arm_link_type= 0;                                         //0:wire link, 1:other(wireless or optic) link(TSVs)
parameter fork_arm_capacitance= 10;                                      //in femto_Farad
parameter fork_arm_link_energy_per_bit_for_non_wire= 10;                 //For non_wire links in femto_Joule

//Design Compiler Parameters(These parameters use to generate Design Compiler script automatically)
parameter string design_compiler_project_path="/home/abbas/Mahdi/test";    //If you want to estimate power by Design Compiler, define Design Compiler project path
parameter string library_name="osu018_stdcells.db";                      //If you want to estimate power by Design Compiler, define your desirable .db name(guide for more details)

//Other Parameters
parameter frequency= 100;                     //in Mega Hertz
parameter want_routers_power_estimation= 0;   //0: If you don't want to run Design Compiler flow to estimate routers power, 1:If you want routers power estimation (guide for more details)
parameter is_netlist_provided= 0;             //0: If you want estimate routers power and provide netlists set it to 1, else 0 (guide for more details)
parameter mapping_strategy= 1;                //0: import mapfile, 1:Sequential Mapping, 2: Random Mapping
parameter seed=10;                             //if random mapping, change the seed for every new mapping
//*Inter-cluster links and fork links description parameter comes in Network.sv file after local parameters*  



//Local Parameters(Don't change local parameter)
localparam buf_size=(switching_method==3)?1:buffer_size;
localparam no_fork_links_id_bits= (have_fork==1)?$clog2(no_fork_fingers+1):1;
localparam cluster_first_dimension_no_addr_bits=$clog2(cluster_first_dimension_up_bound+1);
localparam cluster_second_dimension_no_addr_bits=$clog2(cluster_second_dimension_up_bound+1);
localparam cluster_third_dimension_no_addr_bits=(each_cluster_dimension>2)?$clog2(cluster_third_dimension_up_bound+1):1;
localparam no_cluster_no_addr_bits=(no_clusters>1)?$clog2(no_clusters):1;
localparam addr_length= cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                        cluster_third_dimension_no_addr_bits+no_cluster_no_addr_bits;
localparam link_addr_length= addr_length+(have_fork*no_fork_links_id_bits)+5;
localparam want_vcd_files= (want_routers_power_estimation==1) && (is_netlist_provided==1);                                            

wire [63:0] link_energy_consumption;
wire [3:0] link_class,node_no_port_from_network_to_manager;
wire [31:0] averge_time_of_flies,no_packet_recieve;
wire busy,full_rs,report_rs,clk;
wire [(addr_length-1):0] pe_addr_called,hotspot_addr;
wire [(link_addr_length-1):0] link_addr_called;
wire pe_report_en;
wire program_active,active;
wire [(addr_length-1):0] inject_dest_addr;
integer log_file,pe_id,packet_length,inject_time;
integer pe_addr_called_x_addr,pe_addr_called_y_addr,pe_addr_called_z_addr,pe_addr_called_c_addr;

defparam network.each_cluster_dimension=each_cluster_dimension;
defparam network.cluster_topology=cluster_topology;
defparam network.cluster_first_dimension_up_bound=cluster_first_dimension_up_bound;
defparam network.cluster_second_dimension_up_bound=cluster_second_dimension_up_bound;
defparam network.cluster_third_dimension_up_bound=cluster_third_dimension_up_bound;
defparam network.no_clusters=no_clusters;
defparam network.cluster_first_dimension_no_addr_bits=cluster_first_dimension_no_addr_bits;
defparam network.cluster_second_dimension_no_addr_bits=cluster_second_dimension_no_addr_bits;
defparam network.cluster_third_dimension_no_addr_bits=cluster_third_dimension_no_addr_bits;
defparam network.no_cluster_no_addr_bits=no_cluster_no_addr_bits;
defparam network.have_fork=have_fork;
defparam network.no_fork=no_fork;
defparam network.no_fork_fingers=no_fork_fingers;
defparam network.fork_arm_width=fork_arm_width;
defparam network.have_express_link=have_express_link; 
defparam network.no_express_link=no_express_link;
defparam network.no_vc=no_vc;
defparam network.flit_size=flit_size;
defparam network.phit_size=phit_size;
defparam network.local_traffic_domain=local_traffic_domain;
defparam network.percentage_of_locality=percentage_of_locality;
defparam network.percentage_of_hotspot=percentage_of_hotspot;
defparam network.injection_rate=injection_rate;
defparam network.syn_or_real=syn_or_real;
defparam network.syn_pattern=syn_pattern;
defparam network.switching_method=switching_method;
defparam network.buf_size=buf_size;
defparam network.addr_place_in_header=addr_place_in_header;
defparam network.want_vcd_files=want_vcd_files;
defparam network.frequency=frequency;
defparam network.voltage=voltage;                                 
defparam network.cluster_first_dimension_link_type=cluster_first_dimension_link_type;                         
defparam network.cluster_first_dimension_link_capacitance=cluster_first_dimension_link_capacitance;                 
defparam network.cluster_first_dimension_link_energy_per_bit_for_non_wire=
                                                        cluster_first_dimension_link_energy_per_bit_for_non_wire; 
defparam network.cluster_second_dimension_link_type=cluster_second_dimension_link_type;                        
defparam network.cluster_second_dimension_link_capacitance=cluster_second_dimension_link_capacitance;                
defparam network.cluster_second_dimension_link_energy_per_bit_for_non_wire=
                                                       cluster_second_dimension_link_energy_per_bit_for_non_wire;
defparam network.cluster_third_dimension_link_type=cluster_third_dimension_link_type;                        
defparam network.cluster_third_dimension_link_capacitance=cluster_third_dimension_link_capacitance;                
defparam network.cluster_third_dimension_link_energy_per_bit_for_non_wire=
                                                        cluster_third_dimension_link_energy_per_bit_for_non_wire;
defparam network.express_link_type=express_link_type;                        
defparam network.express_link_capacitance=express_link_capacitance;                
defparam network.express_link_energy_per_bit_for_non_wire=express_link_energy_per_bit_for_non_wire;
defparam network.fork_finger_link_type=fork_finger_link_type;                        
defparam network.fork_finger_capacitance=fork_finger_capacitance;                     
defparam network.fork_finger_link_energy_per_bit_for_non_wire=fork_finger_link_energy_per_bit_for_non_wire;
defparam network.fork_arm_link_type=fork_arm_link_type;                          
defparam network.fork_arm_capacitance=fork_arm_capacitance;
defparam network.fork_arm_link_energy_per_bit_for_non_wire=fork_arm_link_energy_per_bit_for_non_wire;
defparam network.want_routers_power_estimation=want_routers_power_estimation;
defparam network.is_netlist_provided=is_netlist_provided;
network network(averge_time_of_flies,
                no_packet_recieve,
                link_energy_consumption,
                link_class,
                node_no_port_from_network_to_manager,
                busy,
                log_file,
                pe_id,
                inject_dest_addr,
                packet_length,
                inject_time,
                pe_addr_called,
                pe_addr_called_x_addr,
                pe_addr_called_y_addr,
                pe_addr_called_z_addr,
                pe_addr_called_c_addr,
                link_addr_called,
                hotspot_addr,
                pe_report_en,
                program_active,
                active,
                full_rs,
                report_rs,
                clk);


defparam manager.each_cluster_dimension=each_cluster_dimension;
defparam manager.cluster_topology=cluster_topology;
defparam manager.cluster_first_dimension_up_bound=cluster_first_dimension_up_bound;
defparam manager.cluster_second_dimension_up_bound=cluster_second_dimension_up_bound;
defparam manager.cluster_third_dimension_up_bound=cluster_third_dimension_up_bound;
defparam manager.no_clusters=no_clusters;
defparam manager.cluster_first_dimension_no_addr_bits=cluster_first_dimension_no_addr_bits;
defparam manager.cluster_second_dimension_no_addr_bits=cluster_second_dimension_no_addr_bits;
defparam manager.cluster_third_dimension_no_addr_bits=cluster_third_dimension_no_addr_bits;
defparam manager.no_cluster_no_addr_bits=no_cluster_no_addr_bits;
defparam manager.have_fork=have_fork;
defparam manager.no_fork=no_fork;
defparam manager.no_fork_fingers=no_fork_fingers;
defparam manager.have_express_link=have_express_link;
defparam manager.no_express_link=no_express_link;
defparam manager.mapping_strategy=mapping_strategy; 
defparam manager.frequency=frequency;
defparam manager.injection_rate=injection_rate;
defparam manager.simulation_time=simulation_time_per_injection_rate_point;
defparam manager.warm_up_time=warm_up_time;
defparam manager.syn_or_real=syn_or_real;
defparam manager.syn_pattern=syn_pattern;
defparam manager.hotspot_id=hotspot_id;
defparam manager.syn_packet_length= syn_packet_length;
defparam manager.traffic_extension=traffic_extension; 
defparam manager.trace_file_name=trace_file_name;
defparam manager.traffic_real_no_packet=traffic_real_no_packet;
defparam manager.seed=seed;
defparam manager.want_routers_power_estimation=want_routers_power_estimation;
defparam manager.is_netlist_provided=is_netlist_provided;
defparam manager.design_compiler_project_path=design_compiler_project_path;
defparam manager.library_name=library_name;
 manager manager(inject_dest_addr,
                 packet_length,
                 inject_time,
                 log_file,
                 pe_id,
                 pe_addr_called,
                 pe_addr_called_x_addr,
                 pe_addr_called_y_addr,
                 pe_addr_called_z_addr,
                 pe_addr_called_c_addr,
                 link_addr_called,
                 hotspot_addr,
                 pe_report_en,
                 program_active,
                 active,
                 full_rs,
                 report_rs,
                 clk,
                 averge_time_of_flies,
                 no_packet_recieve,
                 link_energy_consumption,
                 link_class,
                 node_no_port_from_network_to_manager,
                 busy);

endmodule