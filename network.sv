`timescale 1ns/10ps
module network(average_time_of_flies,
               no_packet_recieve,
               link_energy_consumption,
               link_class,
               node_no_port_to_manager,
               busy,
               log_file,
               pe_id,
               inject_dest_addr,
               packet_length,
               inject_time,
               pe_addr_called,
               pe_addr_called_x_addr_from_manager,
               pe_addr_called_y_addr_from_manager,
               pe_addr_called_z_addr_from_manager,
               pe_addr_called_c_addr_from_manager,               
               link_addr_called,
               hotspot_addr,
               pe_report_en,
               program_active,
               active,
               full_rs,
               report_rs,
               clk);

parameter each_cluster_dimension=2;
parameter cluster_topology=0; //0:Mesh, 1:Torus
parameter cluster_first_dimension_up_bound=1;
parameter cluster_second_dimension_up_bound=1;
parameter cluster_third_dimension_up_bound=2;
parameter no_clusters=1;
parameter cluster_first_dimension_no_addr_bits=1;
parameter cluster_second_dimension_no_addr_bits=1;
parameter cluster_third_dimension_no_addr_bits=1;
parameter no_cluster_no_addr_bits=1;
parameter have_fork=1;                  //0: there is no fork, 1: there is fork(s)
parameter no_fork=1;                    //number of forks between clusters
parameter no_fork_fingers=2;            //number of fingers that every fork have
parameter fork_arm_width=3;             //this parameter detemine how much fork_arm is powerfull than an outport
parameter have_express_link=1;          //0: there is no express_link, 1: there is express_link(s)
parameter no_express_link=1;            //number of express_link(s)
parameter no_vc=2;
parameter flit_size=1;                  //In number of phits
parameter phit_size=16;                 //In number of bits
parameter local_traffic_domain=5;
parameter percentage_of_locality=100;
parameter percentage_of_hotspot=50;
parameter injection_rate=0.0001;
parameter syn_or_real=0;
parameter [2:0] syn_pattern=3'b000;
parameter switching_method=1;            //1 to Store&forward, 2 to VCT, 3 to Wormhole switching
parameter buf_size=4;                    //In number of flits  
parameter addr_place_in_header=0;        //bit number in header that address start
parameter want_vcd_files=1;
parameter frequency= 100;
parameter voltage=3.3;                                 
parameter cluster_first_dimension_link_type=0;                         
parameter cluster_first_dimension_link_capacitance=10;                 
parameter cluster_first_dimension_link_energy_per_bit_for_non_wire=10; 
parameter cluster_second_dimension_link_type=0;                        
parameter cluster_second_dimension_link_capacitance=10;                
parameter cluster_second_dimension_link_energy_per_bit_for_non_wire=10;
parameter cluster_third_dimension_link_type=0;                        
parameter cluster_third_dimension_link_capacitance=10;                
parameter cluster_third_dimension_link_energy_per_bit_for_non_wire=10;
parameter express_link_type=0;                        
parameter express_link_capacitance=10;                
parameter express_link_energy_per_bit_for_non_wire=10;
parameter fork_finger_link_type=0;                        
parameter fork_finger_capacitance=10;                     
parameter fork_finger_link_energy_per_bit_for_non_wire=10;
parameter fork_arm_link_type=0;                          
parameter fork_arm_capacitance=10;
parameter fork_arm_link_energy_per_bit_for_non_wire=10;
parameter want_routers_power_estimation= 1;      //0: If you don't want to run Design Compiler flow to estimate routers power, 1:If you want routers power estimation (guide for more details)
parameter is_netlist_provided= 1;             //0: If you want estimate routers power and provide netlists set it to 1, else 0 (guide for more details)

localparam addr_length= cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                        cluster_third_dimension_no_addr_bits+no_cluster_no_addr_bits;
localparam no_fork_id_bits=(have_fork==1)?$clog2(no_fork+1):0;
localparam no_fork_links_id_bits= (have_fork==1)?$clog2(no_fork_fingers+1):1;
localparam no_express_link_id_bits= (have_express_link==1)?$clog2(no_express_link+1):1;
localparam integer no_nodes=(each_cluster_dimension==2 && no_clusters==1)?
                             (cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1):
             ((each_cluster_dimension==3 && no_clusters==1)?
              ((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)*(cluster_third_dimension_up_bound+1)):
                ((each_cluster_dimension==2 && no_clusters>1)?
                 ((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)*no_clusters):
                  ((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)*
                                     (cluster_third_dimension_up_bound+1)*no_clusters)));
localparam link_addr_length=addr_length+(have_fork*no_fork_links_id_bits)+5;
localparam floorplusone_log2_no_vc=$clog2(no_vc+1);

localparam  [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0] 
            [(no_express_link_id_bits+1):0] express_link_parse  = express_link_generator();
                                  
localparam  [(no_clusters-1):0]
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [($clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1):0] fork_link_parse = fork_link_generator();

localparam  [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [(addr_length-1):0] node_addr= node_addr_generator();
            
localparam  [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [7:0]
            [(link_addr_length-1):0] link_addr= link_addr_generator();
            
localparam  [(no_fork-1):0]
            [1:0]
            [(link_addr_length-1):0] fork_arm_link_addr=fork_arm_link_addr_generator(); 
            
localparam  [(no_fork-1):0]
            [1:0]
            [(no_fork_fingers-1):0]
            [(link_addr_length-1):0] fork_fingers_link_addr= fork_fingers_link_addr_generator();
               
localparam  [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [3:0] node_no_port= node_no_port_generator();
            
localparam  [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [3:0] node_express_port_no= node_express_port_no_generator();

localparam  [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [3:0] node_fork_port_no= node_fork_port_no_generator();                      

localparam [3:0] tmp_max_no_port= tmp_max_no_port_generator();         
localparam [3:0] max_no_port= max_no_port_generator();
localparam [3:0] min_no_port= min_no_port_generator();

localparam  [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [(max_no_port-1):0]
            [4:0] node_ports_class_direction= node_ports_class_direction_generator();
            
localparam  [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [(max_no_port-1):0]
            [(addr_length+$clog2(max_no_port+1)):0] node_ports_next_router_port= node_ports_next_router_port_generator();
            
localparam  [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [7:0]
            [3:0] node_links_directions= node_links_directions_generator();
            
localparam  [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [31:0] node_links_directions_to_nodes= node_links_directions_to_nodes_generator();                                          

/*
*
*
*
*/

//Describe express and Fork links here

//Inter-cluster links description parameter
parameter [(addr_length-1):0] express_links_description [(no_express_link-1):0][1:0] =
{ 
{ {1'd0,1'd0,3'd0,3'd0} , {1'd1,1'd0,3'd0,3'd0} },
{ {1'd0,1'd0,3'd1,3'd0} , {1'd1,1'd0,3'd1,3'd0} },
{ {1'd0,1'd0,3'd2,3'd0} , {1'd1,1'd0,3'd2,3'd0} },
{ {1'd0,1'd0,3'd3,3'd0} , {1'd1,1'd0,3'd3,3'd0} },
{ {1'd0,1'd0,3'd4,3'd0} , {1'd1,1'd0,3'd4,3'd0} },
{ {1'd0,1'd0,3'd0,3'd5} , {1'd1,1'd0,3'd0,3'd5} },
{ {1'd0,1'd0,3'd1,3'd5} , {1'd1,1'd0,3'd1,3'd5} },
{ {1'd0,1'd0,3'd2,3'd5} , {1'd1,1'd0,3'd2,3'd5} },
{ {1'd0,1'd0,3'd3,3'd5} , {1'd1,1'd0,3'd3,3'd5} },
{ {1'd0,1'd0,3'd4,3'd5} , {1'd1,1'd0,3'd4,3'd5} }
};

/*
*
*
*
*/

//Fork Links description parameter
parameter [(addr_length-1):0] fork_links_description [(no_fork-1):0][1:0][(no_fork_fingers-1):0]=
{ 
{  { {1'd0,1'd0,3'd0,3'd0} , {1'd0,1'd0,3'd1,3'd0} , {1'd0,1'd0,3'd2,3'd0} , {1'd0,1'd0,3'd3,3'd0} , {1'd0,1'd0,3'd4,3'd0} }  ,  { {1'd1,1'd0,3'd0,3'd0} , {1'd1,1'd0,3'd1,3'd0} , {1'd1,1'd0,3'd2,3'd0} , {1'd1,1'd0,3'd3,3'd0} , {1'd1,1'd0,3'd4,3'd0} }  },
{  { {1'd0,1'd0,3'd0,3'd5} , {1'd0,1'd0,3'd1,3'd5} , {1'd0,1'd0,3'd2,3'd5} , {1'd0,1'd0,3'd3,3'd5} , {1'd0,1'd0,3'd4,3'd5} }  ,  { {1'd1,1'd0,3'd0,3'd5} , {1'd1,1'd0,3'd1,3'd5} , {1'd1,1'd0,3'd2,3'd5} , {1'd1,1'd0,3'd3,3'd5} , {1'd1,1'd0,3'd4,3'd5} }  }
};

/*
*
*
*
*/

output [31:0] average_time_of_flies,no_packet_recieve;
output [63:0] link_energy_consumption;
output [3:0] link_class;
output [3:0] node_no_port_to_manager;
output busy;
input integer log_file,pe_id;
input [(addr_length-1):0] inject_dest_addr;
input integer packet_length,inject_time;
input [(addr_length-1):0] pe_addr_called;
input integer pe_addr_called_x_addr_from_manager,pe_addr_called_y_addr_from_manager;
input integer pe_addr_called_z_addr_from_manager,pe_addr_called_c_addr_from_manager;
input [(link_addr_length-1):0] link_addr_called;
input [(addr_length-1):0] hotspot_addr;
input pe_report_en;
input program_active,active;
input full_rs,report_rs,clk;

wire [cluster_first_dimension_up_bound:0] routers_busy [(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                                           [cluster_second_dimension_up_bound:0];
wire [cluster_second_dimension_up_bound:0] router_busy_line [(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0];
wire [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0] router_busy_plan [(no_clusters-1):0];
wire [(no_clusters-1):0] router_busy_cluster ;
wire router_busy_all;
wire [1:0] fork_module_busies [(no_fork-1):0];
wire [(no_fork-1):0] fork_busies;
wire fork_busy;

wire [(phit_size-1):0] node_data_out_array[(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                     [cluster_second_dimension_up_bound:0][cluster_first_dimension_up_bound:0][(max_no_port-1):0];
wire [(max_no_port-1):0] node_sent_req_out_array[(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                     [cluster_second_dimension_up_bound:0][cluster_first_dimension_up_bound:0];
wire [(max_no_port-1):0] node_new_out_array[(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                     [cluster_second_dimension_up_bound:0][cluster_first_dimension_up_bound:0];
wire [(max_no_port-1):0] node_ready_in_array[(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                     [cluster_second_dimension_up_bound:0][cluster_first_dimension_up_bound:0];
wire [($clog2(no_vc+1)-1):0] node_vc_no_out_array[(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                     [cluster_second_dimension_up_bound:0][cluster_first_dimension_up_bound:0][(max_no_port-1):0];
wire [(phit_size-1):0] node_data_in_array[(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                     [cluster_second_dimension_up_bound:0][cluster_first_dimension_up_bound:0][(max_no_port-1):0];
wire [(max_no_port-1):0] node_sent_req_in_array[(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                     [cluster_second_dimension_up_bound:0][cluster_first_dimension_up_bound:0];
wire [(max_no_port-1):0] node_new_in_array[(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                     [cluster_second_dimension_up_bound:0][cluster_first_dimension_up_bound:0];
wire [(max_no_port-1):0] node_ready_out_array[(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                     [cluster_second_dimension_up_bound:0][cluster_first_dimension_up_bound:0];
wire [($clog2(no_vc+1)-1):0] node_vc_no_in_array[(no_clusters-1):0][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                     [cluster_second_dimension_up_bound:0][cluster_first_dimension_up_bound:0][(max_no_port-1):0];
                     
wire [(phit_size-1):0] fork_finger_data_out_array [((have_fork==1)?(no_fork-1):0):0] [1:0] [(no_fork_fingers-1):0];
wire [(no_fork_fingers-1):0] fork_finger_sent_req_out_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(no_fork_fingers-1):0] fork_finger_new_out_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(no_fork_fingers-1):0] fork_finger_ready_in_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [($clog2(no_vc+1)-1):0] fork_finger_vc_no_out_array [((have_fork==1)?(no_fork-1):0):0] [1:0] [(no_fork_fingers-1):0];
wire [(phit_size-1):0] fork_finger_data_in_array [((have_fork==1)?(no_fork-1):0):0] [1:0] [(no_fork_fingers-1):0];
wire [(no_fork_fingers-1):0] fork_finger_sent_req_in_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(no_fork_fingers-1):0] fork_finger_new_in_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(no_fork_fingers-1):0] fork_finger_ready_out_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [($clog2(no_vc+1)-1):0] fork_finger_vc_no_in_array [((have_fork==1)?(no_fork-1):0):0] [1:0] [(no_fork_fingers-1):0];

wire [(fork_arm_width*phit_size)-1:0] fork_arm_data_out_array [((have_fork==1)?(no_fork-1):0):0][1:0]; 
wire [(fork_arm_width-1):0] fork_arm_sent_req_out_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(fork_arm_width-1):0] fork_arm_new_out_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(fork_arm_width-1):0] fork_arm_ready_in_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(fork_arm_width*$clog2(no_vc+1))-1:0] fork_arm_vc_no_out_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(fork_arm_width*phit_size)-1:0] fork_arm_data_in_array [((have_fork==1)?(no_fork-1):0):0][1:0]; 
wire [(fork_arm_width-1):0] fork_arm_sent_req_in_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(fork_arm_width-1):0] fork_arm_new_in_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(fork_arm_width-1):0] fork_arm_ready_out_array [((have_fork==1)?(no_fork-1):0):0] [1:0];
wire [(fork_arm_width*$clog2(no_vc+1))-1:0] fork_arm_vc_no_in_array [((have_fork==1)?(no_fork-1):0):0] [1:0];

integer vcd_to_saif_script_file;
integer design_compiler_script_file;                

genvar gen_i,gen_j,gen_k,gen_l,gen_m,gen_n;

generate   for(gen_i=0;gen_i<no_clusters;gen_i++) begin: router_busy_line_cluster_loop
            for(gen_j=0;gen_j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);gen_j++) begin: router_busy_line_third_loop
             for(gen_k=0;gen_k<cluster_second_dimension_up_bound+1;gen_k++) begin: router_busy_line_second_loop
              assign router_busy_line[gen_i][gen_j][gen_k]= |routers_busy[gen_i][gen_j][gen_k][cluster_first_dimension_up_bound:0];
             end
            end
           end
endgenerate

generate   for(gen_i=0;gen_i<no_clusters;gen_i++) begin: router_busy_plan_cluster_loop
            for(gen_j=0;gen_j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);gen_j++) begin: router_busy_plan_third_loop
             assign router_busy_plan[gen_i][gen_j]= |router_busy_line[gen_i][gen_j][cluster_second_dimension_up_bound:0];
            end
           end
endgenerate

generate   for(gen_i=0;gen_i<no_clusters;gen_i++) begin: router_plan_line_cluster_loop  
            assign router_busy_cluster[gen_i]= |router_busy_plan[gen_i][((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0];
           end
endgenerate

generate   for(gen_i=0;gen_i<no_fork;gen_i++) begin: fork_busies_loop
              assign fork_busies[gen_i]= fork_module_busies[gen_i][0] | fork_module_busies[gen_i][1];
           end
endgenerate           

generate   for(gen_i=0;gen_i<no_clusters;gen_i++) begin: link_energy_cluster_loop
            for(gen_j=0;gen_j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);gen_j++) begin: link_energy_third_loop
             for(gen_k=0;gen_k<cluster_second_dimension_up_bound+1;gen_k++) begin: link_energy_second_loop
              for(gen_l=0;gen_l<cluster_first_dimension_up_bound+1;gen_l++) begin: link_energy_first_loop
               for(gen_m=0;gen_m<max_no_port;gen_m++) begin: link_energy_direction_loop                                     
                link_energy #(floorplusone_log2_no_vc,
                              phit_size,
                              link_addr_length,
                              
                              (node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==1)?(cluster_first_dimension_link_type):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==2)?(cluster_second_dimension_link_type):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==3)?(cluster_third_dimension_link_type):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==4)?(express_link_type):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==5)?(fork_finger_link_type):
                              0)))),
                              
                              (node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==1)?(cluster_first_dimension_link_capacitance):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==2)?(cluster_second_dimension_link_capacitance):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==3)?(cluster_third_dimension_link_capacitance):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==4)?(express_link_capacitance):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==5)?(fork_finger_capacitance):
                              0)))),
                              
                              voltage,
                              
                              (node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==1)?(cluster_first_dimension_link_energy_per_bit_for_non_wire):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==2)?(cluster_second_dimension_link_energy_per_bit_for_non_wire):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==3)?(cluster_third_dimension_link_energy_per_bit_for_non_wire):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==4)?(express_link_energy_per_bit_for_non_wire):
                              ((node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==5)?(fork_finger_link_energy_per_bit_for_non_wire):
                              0)))),
                              
                              fork_arm_width,
                              node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0])
                 link_energy (link_energy_consumption,
                              link_class,
                              link_addr[gen_i][gen_j][gen_k][gen_l][gen_m],
                              link_addr_called,
                              node_data_out_array[gen_i][gen_j][gen_k][gen_l][gen_m],
                              node_sent_req_out_array[gen_i][gen_j][gen_k][gen_l][gen_m],
                              node_new_out_array[gen_i][gen_j][gen_k][gen_l][gen_m],
                              node_ready_out_array[gen_i][gen_j][gen_k][gen_l][gen_m],
                              node_vc_no_out_array[gen_i][gen_j][gen_k][gen_l][gen_m],
                              full_rs|report_rs,
                              clk);
               end
              end
             end
            end
           end
endgenerate           
              
generate   for(gen_i=0;gen_i<no_clusters;gen_i++) begin: node_cluster_loop
            for(gen_j=0;gen_j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);gen_j++) begin: node_third_loop
             for(gen_k=0;gen_k<cluster_second_dimension_up_bound+1;gen_k++) begin: node_second_loop
              for(gen_l=0;gen_l<cluster_first_dimension_up_bound+1;gen_l++) begin: node_first_loop
               defparam sv_router_pc.each_cluster_dimension=each_cluster_dimension;
               defparam sv_router_pc.cluster_topology=cluster_topology;
               defparam sv_router_pc.cluster_first_dimension_up_bound=cluster_first_dimension_up_bound;
               defparam sv_router_pc.cluster_second_dimension_up_bound=cluster_second_dimension_up_bound;
               defparam sv_router_pc.cluster_third_dimension_up_bound=cluster_third_dimension_up_bound;
               defparam sv_router_pc.no_clusters=no_clusters;
               defparam sv_router_pc.cluster_first_dimension_no_addr_bits=cluster_first_dimension_no_addr_bits;
               defparam sv_router_pc.cluster_second_dimension_no_addr_bits=cluster_second_dimension_no_addr_bits;
               defparam sv_router_pc.cluster_third_dimension_no_addr_bits=cluster_third_dimension_no_addr_bits;
               defparam sv_router_pc.no_cluster_no_addr_bits=1;
               defparam sv_router_pc.have_fork_port=have_fork & fork_link_parse[gen_i][gen_j][gen_k][gen_l][0];
               defparam sv_router_pc.have_express_port=have_express_link & express_link_parse[gen_i][gen_j][gen_k][gen_l][0];
               defparam sv_router_pc.local_traffic_domain=local_traffic_domain;
               defparam sv_router_pc.percentage_of_locality=percentage_of_locality;
               defparam sv_router_pc.percentage_of_hotspot=percentage_of_hotspot;
               defparam sv_router_pc.injection_rate=injection_rate;
               defparam sv_router_pc.no_outport=node_no_port[gen_i][gen_j][gen_k][gen_l];
               defparam sv_router_pc.no_inport=node_no_port[gen_i][gen_j][gen_k][gen_l];
               defparam sv_router_pc.no_vc=no_vc;
               defparam sv_router_pc.flit_size=flit_size;
               defparam sv_router_pc.phit_size=phit_size;
               defparam sv_router_pc.switching_method=switching_method;
               defparam sv_router_pc.buf_size=buf_size;
               defparam sv_router_pc.addr_length=addr_length;
               defparam sv_router_pc.addr_place_in_header=addr_place_in_header;
               defparam sv_router_pc.my_addr=node_addr[gen_i][gen_j][gen_k][gen_l];
               defparam sv_router_pc.my_type=node_no_port[gen_i][gen_j][gen_k][gen_l]-2;
               defparam sv_router_pc.node_links_directions=node_links_directions_to_nodes[gen_i][gen_j][gen_k][gen_l];
               defparam sv_router_pc.want_vcd_files=want_vcd_files;
               defparam sv_router_pc.want_routers_power_estimation=want_routers_power_estimation;
               defparam sv_router_pc.is_netlist_provided=is_netlist_provided;
               defparam sv_router_pc.no_nodes=no_nodes;
               sv_router_pc sv_router_pc(node_data_out_array[gen_i][gen_j][gen_k][gen_l]
                                                               [(node_no_port[gen_i][gen_j][gen_k][gen_l]-1):0],
                                         node_sent_req_out_array[gen_i][gen_j][gen_k][gen_l]
                                                               [(node_no_port[gen_i][gen_j][gen_k][gen_l]-1):0],                                         
                                         node_new_out_array[gen_i][gen_j][gen_k][gen_l]
                                                               [(node_no_port[gen_i][gen_j][gen_k][gen_l]-1):0],                                         
                                         node_ready_in_array[gen_i][gen_j][gen_k][gen_l]
                                                               [(node_no_port[gen_i][gen_j][gen_k][gen_l]-1):0],                                         
                                         node_vc_no_out_array[gen_i][gen_j][gen_k][gen_l]
                                                               [(node_no_port[gen_i][gen_j][gen_k][gen_l]-1):0],
                                                                                                                      
                                         node_data_in_array[gen_i][gen_j][gen_k][gen_l]
                                                               [(node_no_port[gen_i][gen_j][gen_k][gen_l]-1):0],                                         
                                         node_sent_req_in_array[gen_i][gen_j][gen_k][gen_l]
                                                               [(node_no_port[gen_i][gen_j][gen_k][gen_l]-1):0],                                         
                                         node_new_in_array[gen_i][gen_j][gen_k][gen_l]
                                                               [(node_no_port[gen_i][gen_j][gen_k][gen_l]-1):0],                                         
                                         node_ready_out_array[gen_i][gen_j][gen_k][gen_l]
                                                               [(node_no_port[gen_i][gen_j][gen_k][gen_l]-1):0],                                         
                                         node_vc_no_in_array[gen_i][gen_j][gen_k][gen_l]
                                                               [(node_no_port[gen_i][gen_j][gen_k][gen_l]-1):0],                                         
                     
                                         average_time_of_flies,
                                         no_packet_recieve,
                                         routers_busy[gen_i][gen_j][gen_k][gen_l],
                                         active,
                                         syn_or_real[0],
                                         syn_pattern,
                                         program_active,
                                         pe_addr_called,
                                         inject_dest_addr,
                                         hotspot_addr,
                                         inject_time,
                                         packet_length,
                                         log_file,
                                         pe_id,
                                         pe_report_en,
                                         report_rs,
                                         full_rs,
                                         clk);
              end
             end
            end
           end                              
endgenerate                 

generate if(have_fork==1) for(gen_i=0;gen_i<no_fork;gen_i++) begin:fork_loop

 sv_fork_module#(no_fork,
                 gen_i,
                 fork_arm_width,
                 $clog2(fork_arm_width+1),
                 no_fork_fingers,
                 $clog2(no_fork_fingers+1),
                 0,
                 no_vc,
                 floorplusone_log2_no_vc,
                 flit_size,
                 $clog2(flit_size+1),
                 phit_size,
                 buf_size,
                 $clog2(buf_size+1),
                 switching_method,
                 addr_place_in_header,
                 want_vcd_files,
                 want_routers_power_estimation,
                 is_netlist_provided)
  sv_fork_module_headzero(fork_arm_data_out_array[gen_i][0],
                          fork_arm_sent_req_out_array[gen_i][0],
                          fork_arm_new_out_array[gen_i][0],
                          fork_arm_ready_in_array[gen_i][0],
                          fork_arm_vc_no_out_array[gen_i][0],                      
                       
                          fork_arm_data_in_array[gen_i][0],
                          fork_arm_sent_req_in_array[gen_i][0],
                          fork_arm_new_in_array[gen_i][0],
                          fork_arm_ready_out_array[gen_i][0],
                          fork_arm_vc_no_in_array[gen_i][0],
                                           
                          fork_finger_data_out_array[gen_i][0],
                          fork_finger_sent_req_out_array[gen_i][0],
                          fork_finger_new_out_array[gen_i][0],
                          fork_finger_ready_in_array[gen_i][0],
                          fork_finger_vc_no_out_array[gen_i][0],       
        
                          fork_finger_data_in_array[gen_i][0],
                          fork_finger_sent_req_in_array[gen_i][0],
                          fork_finger_new_in_array[gen_i][0],
                          fork_finger_ready_out_array[gen_i][0],
                          fork_finger_vc_no_in_array[gen_i][0],                     
                      
                          fork_module_busies[gen_i][0],
                          active,
                          full_rs,
                          clk);


 link_energy #(floorplusone_log2_no_vc,
               phit_size,
               link_addr_length,
               fork_arm_link_type,              
               fork_arm_capacitance,
               voltage,
               fork_arm_link_energy_per_bit_for_non_wire,
               fork_arm_width,
               6)                                          
  link_energy_headzero_to_headone(link_energy_consumption,
                                  link_class,
                                  fork_arm_link_addr[gen_i][0],
                                  link_addr_called,
                                  fork_arm_data_out_array[gen_i][0],
                                  fork_arm_sent_req_out_array[gen_i][0],
                                  fork_arm_new_out_array[gen_i][0],
                                  fork_arm_ready_in_array[gen_i][0],
                                  fork_arm_vc_no_out_array[gen_i][0],
                                  full_rs|report_rs,
                                  clk);
                                  

  sv_fork_module#(no_fork,
                 gen_i,
                 fork_arm_width,
                 $clog2(fork_arm_width+1),
                 no_fork_fingers,
                 $clog2(no_fork_fingers+1),
                 1,
                 no_vc,
                 floorplusone_log2_no_vc,
                 flit_size,
                 $clog2(flit_size+1),
                 phit_size,
                 buf_size,
                 $clog2(buf_size+1),
                 switching_method,
                 addr_place_in_header,
                 want_vcd_files,
                 want_routers_power_estimation,
                 is_netlist_provided)
  sv_fork_module_headone(fork_arm_data_out_array[gen_i][1],
                         fork_arm_sent_req_out_array[gen_i][1],
                         fork_arm_new_out_array[gen_i][1],
                         fork_arm_ready_in_array[gen_i][1],
                         fork_arm_vc_no_out_array[gen_i][1],                      
                       
                         fork_arm_data_in_array[gen_i][1],
                         fork_arm_sent_req_in_array[gen_i][1],
                         fork_arm_new_in_array[gen_i][1],
                         fork_arm_ready_out_array[gen_i][1],
                         fork_arm_vc_no_in_array[gen_i][1],
                                           
                         fork_finger_data_out_array[gen_i][1],
                         fork_finger_sent_req_out_array[gen_i][1],
                         fork_finger_new_out_array[gen_i][1],
                         fork_finger_ready_in_array[gen_i][1],
                         fork_finger_vc_no_out_array[gen_i][1],       
        
                         fork_finger_data_in_array[gen_i][1],
                         fork_finger_sent_req_in_array[gen_i][1],
                         fork_finger_new_in_array[gen_i][1],
                         fork_finger_ready_out_array[gen_i][1],
                         fork_finger_vc_no_in_array[gen_i][1],                     
                      
                         fork_module_busies[gen_i][1],
                         active,
                         full_rs,
                         clk);


 link_energy #(floorplusone_log2_no_vc,
               phit_size,
               link_addr_length,
               fork_arm_link_type,              
               fork_arm_capacitance,
               voltage,
               fork_arm_link_energy_per_bit_for_non_wire,
               fork_arm_width,
               6)                                          
  link_energy_headone_to_headzero(link_energy_consumption,
                                  link_class,
                                  fork_arm_link_addr[gen_i][1],
                                  link_addr_called,
                                  fork_arm_data_out_array[gen_i][1],
                                  fork_arm_sent_req_out_array[gen_i][1],
                                  fork_arm_new_out_array[gen_i][1],
                                  fork_arm_ready_in_array[gen_i][1],
                                  fork_arm_vc_no_out_array[gen_i][1],
                                  full_rs|report_rs,
                                  clk);
  assign fork_arm_data_in_array[gen_i][0]=fork_arm_data_out_array[gen_i][1];
  assign fork_arm_data_in_array[gen_i][1]=fork_arm_data_out_array[gen_i][0];
  assign fork_arm_sent_req_in_array[gen_i][0]=fork_arm_sent_req_out_array[gen_i][1];
  assign fork_arm_sent_req_in_array[gen_i][1]=fork_arm_sent_req_out_array[gen_i][0];
  assign fork_arm_new_in_array[gen_i][0]=fork_arm_new_out_array[gen_i][1];
  assign fork_arm_new_in_array[gen_i][1]=fork_arm_new_out_array[gen_i][0];
  assign fork_arm_ready_in_array[gen_i][0]= fork_arm_ready_out_array[gen_i][1];
  assign fork_arm_ready_in_array[gen_i][1]= fork_arm_ready_out_array[gen_i][0];
  assign fork_arm_vc_no_in_array[gen_i][0]=fork_arm_vc_no_out_array[gen_i][1];
  assign fork_arm_vc_no_in_array[gen_i][1]=fork_arm_vc_no_out_array[gen_i][0];
  
 end                                                           
endgenerate

generate if(have_fork==1) begin: fork_fingers_link_energy_condition
          for(gen_i=0;gen_i<no_fork;gen_i++) begin: fork_fingers_link_energy_fork_loop
           for(gen_j=0;gen_j<2;gen_j++) begin: fork_fingers_link_energy_head_loop
            for(gen_k=0;gen_k<no_fork_fingers;gen_k++) begin: fork_fingers_link_energy_finger_loop
            
 defparam link_energy.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
 defparam link_energy.phit_size=phit_size;
 defparam link_energy.link_addr_length=link_addr_length;
 defparam link_energy.link_type=fork_finger_link_type;
 defparam link_energy.capacitance=fork_finger_capacitance;
 defparam link_energy.voltage=voltage;
 defparam link_energy.energy_per_bit_for_non_wire=fork_finger_link_energy_per_bit_for_non_wire;
 defparam link_energy.fork_arm_width=fork_arm_width;
 defparam link_energy.link_class=5;
  link_energy link_energy(link_energy_consumption,
                          link_class,
                          fork_fingers_link_addr[gen_i][gen_j][gen_k],
                          link_addr_called,
                          fork_finger_data_out_array[gen_i][gen_j][gen_k],
                          fork_finger_new_out_array[gen_i][gen_j][gen_k],
                          fork_finger_new_out_array[gen_i][gen_j][gen_k],
                          fork_finger_ready_out_array[gen_i][gen_j][gen_k],
                          fork_finger_vc_no_out_array[gen_i][gen_j][gen_k],
                          report_rs,
                          clk);
            end               
           end
          end
         end
endgenerate                             

generate   for(gen_i=0;gen_i<no_clusters;gen_i++) begin: node_cluster_sewing_loop
            for(gen_j=0;gen_j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);gen_j++) begin: node_third_dimension_sewing_loop
             for(gen_k=0;gen_k<cluster_second_dimension_up_bound+1;gen_k++) begin: node_second_dimension_sewing_loop
              for(gen_l=0;gen_l<cluster_first_dimension_up_bound+1;gen_l++) begin: node_first_dimension_sewing_loop
               for(gen_m=0;gen_m<max_no_port;gen_m++) begin: node_ports_sewing_loop
                if(node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]!=0 && node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]!=5)
                 begin
                  assign node_data_in_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits+1)]]
                                           [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits):(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits+1)]]
                                           [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits):($clog2(max_no_port+1)+cluster_first_dimension_no_addr_bits+1)]]
                                           [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)+cluster_first_dimension_no_addr_bits):($clog2(max_no_port+1)+1)]]
                                           [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1):0]]=                     
                         node_data_out_array[gen_i][gen_j][gen_k][gen_l][gen_m];
                         
                  assign node_sent_req_in_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits+1)]]
                                               [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits):(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits+1)]]
                                               [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits):($clog2(max_no_port+1)+cluster_first_dimension_no_addr_bits+1)]]
                                               [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)+cluster_first_dimension_no_addr_bits):($clog2(max_no_port+1)+1)]]
                                               [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1):0]]=                     
                         node_sent_req_out_array[gen_i][gen_j][gen_k][gen_l][gen_m];
                         
                  assign node_new_in_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits+1)]]
                                          [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits):(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits+1)]]
                                          [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits):($clog2(max_no_port+1)+cluster_first_dimension_no_addr_bits+1)]]
                                          [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)+cluster_first_dimension_no_addr_bits):($clog2(max_no_port+1)+1)]]
                                          [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1):0]]=                     
                         node_new_out_array[gen_i][gen_j][gen_k][gen_l][gen_m];
                         
                  assign node_ready_in_array[gen_i][gen_j][gen_k][gen_l][gen_m]=
                         node_ready_out_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits+1)]]
                                             [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits):(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits+1)]]
                                             [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits):($clog2(max_no_port+1)+cluster_first_dimension_no_addr_bits+1)]]
                                             [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)+cluster_first_dimension_no_addr_bits):($clog2(max_no_port+1)+1)]]
                                             [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1):0]];
                 
                 
                  assign node_vc_no_in_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits+1)]]
                                            [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits):(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits+1)]]
                                            [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits):($clog2(max_no_port+1)+cluster_first_dimension_no_addr_bits+1)]]
                                            [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)+cluster_first_dimension_no_addr_bits):($clog2(max_no_port+1)+1)]]
                                            [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1):0]]=                     
                         node_vc_no_out_array[gen_i][gen_j][gen_k][gen_l][gen_m];                     
                 
                 end
                else if(node_ports_class_direction[gen_i][gen_j][gen_k][gen_l][gen_m][3:0]==5) //Fork fingers sewing
                 begin
                  assign fork_finger_data_in_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]]
                                                  [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1)]]
                                                  [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)-1):0]]=                     
                         node_data_out_array[gen_i][gen_j][gen_k][gen_l][gen_m];
                         
                  assign fork_finger_sent_req_in_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]]
                                                      [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1)]]
                                                      [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)-1):0]]=                     
                         node_sent_req_out_array[gen_i][gen_j][gen_k][gen_l][gen_m];
                         
                  assign fork_finger_new_in_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]]
                                                 [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1)]]
                                                 [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)-1):0]]=                     
                         node_new_out_array[gen_i][gen_j][gen_k][gen_l][gen_m];
                         
                  assign fork_finger_ready_in_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]]
                                                   [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1)]]
                                                   [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)-1):0]]=
                         node_ready_out_array[gen_i][gen_j][gen_k][gen_l][gen_m];
                 
                  assign fork_finger_vc_no_in_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]]
                                                   [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1)]]
                                                   [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)-1):0]]=                     
                         node_vc_no_out_array[gen_i][gen_j][gen_k][gen_l][gen_m];
                  
                          
                  assign node_data_in_array[gen_i][gen_j][gen_k][gen_l][gen_m]=
                         fork_finger_data_out_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]]
                                                   [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1)]]
                                                   [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)-1):0]];                     
                         
                  assign node_sent_req_in_array[gen_i][gen_j][gen_k][gen_l][gen_m]=
                         fork_finger_sent_req_out_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]]
                                                       [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1)]]
                                                       [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)-1):0]];                    
                                
                  assign node_new_in_array[gen_i][gen_j][gen_k][gen_l][gen_m]=
                         fork_finger_new_out_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]]
                                                  [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1)]]
                                                  [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)-1):0]];                     
                         
                  assign node_ready_in_array[gen_i][gen_j][gen_k][gen_l][gen_m]=
                         fork_finger_ready_out_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]]
                                                    [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1)]]
                                                    [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)-1):0]];
                             
                  assign node_vc_no_in_array[gen_i][gen_j][gen_k][gen_l][gen_m]=
                         fork_finger_vc_no_out_array[node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]]
                                                    [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][$clog2(max_no_port+1)]]
                                                    [node_ports_next_router_port[gen_i][gen_j][gen_k][gen_l][gen_m][($clog2(max_no_port+1)-1):0]];                     
                                           
                 end
               end
              end
             end
            end
           end 
endgenerate
           
assign router_busy_all=|router_busy_cluster[(no_clusters-1):0];
assign fork_busy=|fork_busies[(no_fork-1):0];
assign busy= router_busy_all|((have_fork==1)?fork_busy:0);
assign node_no_port_to_manager=node_no_port[pe_addr_called_c_addr_from_manager]
                                           [pe_addr_called_z_addr_from_manager]
                                           [pe_addr_called_y_addr_from_manager]
                                           [pe_addr_called_x_addr_from_manager];
                                           
initial
 begin
  if(want_routers_power_estimation==1 && is_netlist_provided==0) generate_router_files();
  if(have_fork==1)
   begin
    if(want_routers_power_estimation==1 && is_netlist_provided==0) generate_fork_head_file();
   end
 end

function [(no_clusters-1):0] 
         [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
         [cluster_second_dimension_up_bound:0]
         [cluster_first_dimension_up_bound:0]
         [(no_express_link_id_bits+1):0] express_link_generator;  
 
 begin
   
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      express_link_generator[i][j][m][n]=0;
 
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
       for(int k=0;k<no_express_link;k++)
        begin
          
         if(each_cluster_dimension==2 && no_clusters==1)
          begin
           if(express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              express_links_description [k][0][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m)
            begin
             express_link_generator[i][j]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             express_link_generator[i][j]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits:1]=k;
             express_link_generator[i][j]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits+1]=0;                   
            end 
 
           else if(express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              express_links_description [k][1][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m)
            begin
             express_link_generator[i][j]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             express_link_generator[i][j]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits:1]=k;
             express_link_generator[i][j]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits+1]=1;                 
            end
          end
          
         else if(each_cluster_dimension==3 && no_clusters==1)
          begin
           if(express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              express_links_description [k][0]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              express_links_description [k][0]
               [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]==j)
            begin
             express_link_generator[i]
              [express_links_description [k][0]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             express_link_generator[i]
              [express_links_description [k][0]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits:1]=k; 
             express_link_generator[i]
              [express_links_description [k][0]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits+1]=0;
            end 
           else if(express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              express_links_description [k][1]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              express_links_description [k][1]
               [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]==j)
            begin            
             express_link_generator[i]
              [express_links_description [k][1]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             express_link_generator[i]
              [express_links_description [k][1]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits:1]=k; 
             express_link_generator[i]
              [express_links_description [k][1]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits+1]=1;
            end 
          end
          
         else if(each_cluster_dimension==2 && no_clusters>1)
          begin
           if(express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              express_links_description [k][0]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              express_links_description [k][0]
               [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]==i)
            begin
             express_link_generator
              [express_links_description [k][0]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             express_link_generator
              [express_links_description [k][0]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits:1]=k;
             express_link_generator
              [express_links_description [k][0]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits+1]=0;
            end
           else if(express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              express_links_description [k][1]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              express_links_description [k][1]
               [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]==i)
            begin
             express_link_generator
              [express_links_description [k][1]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             express_link_generator
              [express_links_description [k][1]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits:1]=k;
             express_link_generator
              [express_links_description [k][1]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits+1]=1;
            end
          end
          
         else if(each_cluster_dimension==3 && no_clusters>1)
          begin
           if(express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              express_links_description [k][0]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              express_links_description [k][0]
               [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]==j &&
              express_links_description [k][0]
               [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]==i)
            begin 
             express_link_generator
              [express_links_description [k][0]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             express_link_generator
              [express_links_description [k][0]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits:1]=k;
             express_link_generator
              [express_links_description [k][0]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [express_links_description [k][0]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][0][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits+1]=0;
            end
           else if(express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              express_links_description [k][1]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              express_links_description [k][1]
               [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]==j &&
              express_links_description [k][1]
               [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]==i)
            begin 
             express_link_generator
              [express_links_description [k][1]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             express_link_generator
              [express_links_description [k][1]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits:1]=k;
             express_link_generator
              [express_links_description [k][1]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [express_links_description [k][1]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [express_links_description [k][1][(cluster_first_dimension_no_addr_bits-1):0]][no_express_link_id_bits+1]=1;
            end
          end
        end
 end
endfunction

function [(no_clusters-1):0] 
         [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
         [cluster_second_dimension_up_bound:0]
         [cluster_first_dimension_up_bound:0]
         [($clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1):0] fork_link_generator;
 
 begin
   
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      fork_link_generator[i][j][m][n]=0;
 
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      for(int k=0;k<no_fork;k++)
       for(int l=0;l<no_fork_fingers;l++)
        begin
          
         if(each_cluster_dimension==2 && no_clusters==1)
          begin
           if(fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m)
            begin
             fork_link_generator[i][j]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             fork_link_generator[i][j]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork_fingers+1):1]=l;
             fork_link_generator[i][j]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][($clog2(no_fork+1)+$clog2(no_fork_fingers+1)):($clog2(no_fork_fingers+1)+1)]=k;
             fork_link_generator[i][j]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1]=0;                   
            end 
 
           else if(fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m)
            begin
             fork_link_generator[i][j]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             fork_link_generator[i][j]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork_fingers+1):1]=l;
             fork_link_generator[i][j]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][($clog2(no_fork+1)+$clog2(no_fork_fingers+1)):($clog2(no_fork_fingers+1)+1)]=k;
             fork_link_generator[i][j]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1]=1;                   
            end
          end
          
         else if(each_cluster_dimension==3 && no_clusters==1)
          begin
           if(fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              fork_links_description [k][0][l]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              fork_links_description [k][0][l]
               [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]==j)
            begin
             fork_link_generator[i]
              [fork_links_description [k][0][l]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             fork_link_generator[i]
              [fork_links_description [k][0][l]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork_fingers+1):1]=l;
             fork_link_generator[i]
              [fork_links_description [k][0][l]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][($clog2(no_fork+1)+$clog2(no_fork_fingers+1)):($clog2(no_fork_fingers+1)+1)]=k; 
             fork_link_generator[i]
              [fork_links_description [k][0][l]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1]=0;
            end 
           else if(fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              fork_links_description [k][1][l]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              fork_links_description [k][1][l]
               [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]==j)
            begin
             fork_link_generator[i]
              [fork_links_description [k][1][l]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             fork_link_generator[i]
              [fork_links_description [k][1][l]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork_fingers+1):1]=l;           
             fork_link_generator[i]
              [fork_links_description [k][1][l]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][($clog2(no_fork+1)+$clog2(no_fork_fingers+1)):($clog2(no_fork_fingers+1)+1)]=k; 
             fork_link_generator[i]
              [fork_links_description [k][1][l]
              [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1]=1;
            end 
          end
          
         else if(each_cluster_dimension==2 && no_clusters>1)
          begin
           if(fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              fork_links_description [k][0][l]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              fork_links_description [k][0][l]
               [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]==i)
            begin
             fork_link_generator
              [fork_links_description [k][0][l]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             fork_link_generator
              [fork_links_description [k][0][l]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork_fingers+1):1]=l;
             fork_link_generator
              [fork_links_description [k][0][l]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][($clog2(no_fork+1)+$clog2(no_fork_fingers+1)):($clog2(no_fork_fingers+1)+1)]=k;
             fork_link_generator
              [fork_links_description [k][0][l]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1]=0;
            end
           else if(fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              fork_links_description [k][1][l]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              fork_links_description [k][1][l]
               [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]==i)
            begin
             fork_link_generator
              [fork_links_description [k][1][l]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             fork_link_generator
              [fork_links_description [k][1][l]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork_fingers+1):1]=l;          
             fork_link_generator
              [fork_links_description [k][1][l]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][($clog2(no_fork+1)+$clog2(no_fork_fingers+1)):($clog2(no_fork_fingers+1)+1)]=k;
             fork_link_generator
              [fork_links_description [k][1][l]
              [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
              [j]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1]=1;
            end
          end
          
         else if(each_cluster_dimension==3 && no_clusters>1)
          begin
           if(fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              fork_links_description [k][0][l]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              fork_links_description [k][0][l]
               [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]==j &&
              fork_links_description [k][0][l]
               [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]==i)
            begin 
             fork_link_generator
              [fork_links_description [k][0][l]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             fork_link_generator
              [fork_links_description [k][0][l]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork_fingers+1):1]=l;          
             fork_link_generator
              [fork_links_description [k][0][l]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][($clog2(no_fork+1)+$clog2(no_fork_fingers+1)):($clog2(no_fork_fingers+1)+1)]=k;
             fork_link_generator
              [fork_links_description [k][0][l]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [fork_links_description [k][0][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][0][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1]=0;
            end
           else if(fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]==n &&
              fork_links_description [k][1][l]
               [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]==m &&
              fork_links_description [k][1][l]
               [(addr_length-no_cluster_no_addr_bits-1):(addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]==j &&
              fork_links_description [k][1][l]
               [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]==i)
            begin 
             fork_link_generator
              [fork_links_description [k][1][l]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][0]=1;
             fork_link_generator
              [fork_links_description [k][1][l]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork_fingers+1):1]=l;             
             fork_link_generator
              [fork_links_description [k][1][l]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][($clog2(no_fork+1)+$clog2(no_fork_fingers+1)):($clog2(no_fork_fingers+1)+1)]=k;
             fork_link_generator
              [fork_links_description [k][1][l]
              [(addr_length-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                                              cluster_third_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_third_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
              [fork_links_description [k][1][l]
              [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
              [fork_links_description [k][1][l][(cluster_first_dimension_no_addr_bits-1):0]][$clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1]=1;
            end
          end
        end
 end
endfunction

function [(no_clusters-1):0] 
         [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
         [cluster_second_dimension_up_bound:0]
         [cluster_first_dimension_up_bound:0]
         [(addr_length-1):0] node_addr_generator(); 
         
  for(int i=0;i<no_clusters;i++)
   begin
    for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
     begin
      for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
       begin
        for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
         begin
          node_addr_generator[i][j][m][n][(addr_length-1):(addr_length-no_cluster_no_addr_bits)]=i;
          node_addr_generator[i][j][m][n][(addr_length-no_cluster_no_addr_bits-1):
                  (addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]=j;
          node_addr_generator[i][j][m][n][(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                      (cluster_first_dimension_no_addr_bits)]=m;
          node_addr_generator[i][j][m][n][(cluster_first_dimension_no_addr_bits-1):0]=n;
         end
       end
     end
   end
      
endfunction

function [(no_clusters-1):0] 
         [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
         [cluster_second_dimension_up_bound:0]
         [cluster_first_dimension_up_bound:0]
         [7:0]
         [(link_addr_length-1):0] link_addr_generator();         
                  
 begin
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      for(int l=0;l<8;l++)
       begin
        link_addr_generator[i][j][m][n][l][(link_addr_length-1):(link_addr_length-no_cluster_no_addr_bits)]=i;
        link_addr_generator[i][j][m][n][l][(link_addr_length-no_cluster_no_addr_bits-1):
                           (link_addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits)]=j;
        link_addr_generator[i][j][m][n][l][(link_addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits-1):
                           (link_addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits-cluster_second_dimension_no_addr_bits)]=m;
        link_addr_generator[i][j][m][n][l][(link_addr_length-no_cluster_no_addr_bits-cluster_third_dimension_no_addr_bits-cluster_second_dimension_no_addr_bits-1):
                                                                            (link_addr_length-addr_length)]=n;                   
        link_addr_generator[i][j][m][n][l][(link_addr_length-addr_length-1):4]=0;
        link_addr_generator[i][j][m][n][l][3:0]=l;
       end
 end
endfunction

function [(no_clusters-1):0] 
         [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
         [cluster_second_dimension_up_bound:0]
         [cluster_first_dimension_up_bound:0]
         [3:0] node_no_port_generator();
 begin
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++) node_no_port_generator[i][j][m][n]=0;
     
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      begin
       if(express_link_parse[i][j][m][n][0] & (have_express_link==1)) node_no_port_generator[i][j][m][n]=node_no_port_generator[i][j][m][n]+1;
       if(fork_link_parse[i][j][m][n][0] & (have_fork==1)) node_no_port_generator[i][j][m][n]=node_no_port_generator[i][j][m][n]+1;
       if(cluster_topology==0)
        begin
         if(n!=0 && n!=cluster_first_dimension_up_bound)node_no_port_generator[i][j][m][n]=node_no_port_generator[i][j][m][n]+2;
         else if(n==0 || n==cluster_first_dimension_up_bound) node_no_port_generator[i][j][m][n]=node_no_port_generator[i][j][m][n]+1;
         if(m!=0 && m!=cluster_second_dimension_up_bound)node_no_port_generator[i][j][m][n]=node_no_port_generator[i][j][m][n]+2;
         else if(m==0 || m==cluster_second_dimension_up_bound) node_no_port_generator[i][j][m][n]=node_no_port_generator[i][j][m][n]+1; 
         if(each_cluster_dimension>2)
          begin
           if(j!=0 && j!=cluster_third_dimension_up_bound)node_no_port_generator[i][j][m][n]=node_no_port_generator[i][j][m][n]+2;
           else if(j==0 || j==cluster_third_dimension_up_bound) node_no_port_generator[i][j][m][n]=node_no_port_generator[i][j][m][n]+1; 
          end
        end
       else if(cluster_topology==1) node_no_port_generator[i][j][m][n]=node_no_port_generator[i][j][m][n]+(2*each_cluster_dimension);
      end
 end
endfunction

function [3:0] tmp_max_no_port_generator();
 begin
  tmp_max_no_port_generator=0;
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
       if(tmp_max_no_port_generator<node_no_port[i][j][m][n])
        tmp_max_no_port_generator=node_no_port[i][j][m][n];
 end
endfunction

function [3:0] max_no_port_generator();
 begin
  max_no_port_generator=0;
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
       if(max_no_port_generator<node_no_port[i][j][m][n])
        max_no_port_generator=node_no_port[i][j][m][n];
  if(have_fork==1 && no_fork_fingers > max_no_port_generator) max_no_port_generator= no_fork_fingers;
 end
endfunction

function [3:0] min_no_port_generator();
 begin
  min_no_port_generator=4'b1111;
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
       if(min_no_port_generator>node_no_port[i][j][m][n])
        min_no_port_generator=node_no_port[i][j][m][n];
 end
endfunction

function [(no_clusters-1):0] 
         [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
         [cluster_second_dimension_up_bound:0]
         [cluster_first_dimension_up_bound:0]
         [3:0] node_express_port_no_generator();
 begin
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      begin
       if((express_link_parse[i][j][m][n][0]&(have_express_link==1)) & (fork_link_parse[i][j][m][n][0]&(have_fork==1)))
        node_express_port_no_generator[i][j][m][n]= node_no_port_generator[i][j][m][n]-2;  
       else if((express_link_parse[i][j][m][n][0]&(have_express_link==1)) & ~(fork_link_parse[i][j][m][n][0]&(have_fork==1)))
        node_express_port_no_generator[i][j][m][n]= node_no_port_generator[i][j][m][n]-1;
       else
        node_express_port_no_generator[i][j][m][n]= 0;
      end
 end
endfunction

function [(no_clusters-1):0] 
         [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
         [cluster_second_dimension_up_bound:0]
         [cluster_first_dimension_up_bound:0]
         [3:0] node_fork_port_no_generator();
 begin  
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      begin
       if((fork_link_parse[i][j][m][n][0]&(have_fork==1)))
        node_fork_port_no_generator[i][j][m][n]= node_no_port_generator[i][j][m][n]-1;  
       else
        node_fork_port_no_generator[i][j][m][n]= 0;
      end
 end
endfunction

function    [(no_clusters-1):0] 
            [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
            [cluster_second_dimension_up_bound:0]
            [cluster_first_dimension_up_bound:0]
            [(max_no_port-1):0] 
            [4:0] node_ports_class_direction_generator();
 begin
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      for(int p=0;p<max_no_port;p++) node_ports_class_direction_generator[i][j][m][n][p]=0;
      
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      for(int p=0;p<max_no_port;p++)
       begin
        if(cluster_topology==0) //Mesh
         begin
          case(p)
           0:
            begin
             if(n!=cluster_first_dimension_up_bound)
              begin
               node_ports_class_direction_generator[i][j][m][n][p][3:0]=1;
               node_ports_class_direction_generator[i][j][m][n][p][4]=1;  //1:plus direction, 0:minus direction
              end
             else
              begin
               node_ports_class_direction_generator[i][j][m][n][p][3:0]=1;
               node_ports_class_direction_generator[i][j][m][n][p][4]=0;  
              end
            end
            
           1:
            begin
             if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b10001)
              begin
               if(n!=0)
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=1;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else
                begin
                 if(m!=cluster_second_dimension_up_bound) 
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=2;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=1;
                  end
                 else
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=2;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0;  
                  end
                end
              end
             else if(node_ports_class_direction_generator[i][j][m][n][0]==5'b00001)
              begin
               if(m!=cluster_second_dimension_up_bound) 
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=2;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=1;
                end
               else
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=2;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;  
                end 
              end
            end
            
           2:
            begin
             if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00001)
              begin
               if(m!=cluster_second_dimension_up_bound) 
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=2;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=1;
                end
               else
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=2;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;  
                end 
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b10010)
              begin
               if(m!=0)
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=2;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end 
               else
                begin
                 if(each_cluster_dimension>2)
                  begin
                   if(j!=cluster_third_dimension_up_bound)
                    begin
                     node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                     node_ports_class_direction_generator[i][j][m][n][p][4]=1; 
                    end
                   else
                    begin
                     node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                     node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                    end
                  end   
                 else if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                  end
                 else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                  end
                 else node_ports_class_direction_generator[i][j][m][n][p]=0;
                end
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00010)
              begin
               if(each_cluster_dimension>2)
                begin
                 if(j!=cluster_third_dimension_up_bound)
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=1; 
                  end
                 else
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                  end
                end   
               else if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0;
              end 
            end
            
           3:
            begin
             if(node_ports_class_direction_generator[i][j][m][n][p-1]==0)
                              node_ports_class_direction_generator[i][j][m][n][p]=0;
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b10010)
              begin
               if(m!=0)
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=2;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else
                begin
                 if(each_cluster_dimension>2)
                  begin
                   if(j!=cluster_third_dimension_up_bound)
                    begin
                     node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                     node_ports_class_direction_generator[i][j][m][n][p][4]=1; 
                    end
                   else
                    begin
                     node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                     node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                    end
                  end   
                 else if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                  end
                 else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                  end
                 else node_ports_class_direction_generator[i][j][m][n][p]=0; 
                end 
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00010)
              begin 
               if(each_cluster_dimension>2)
                begin
                 if(j!=cluster_third_dimension_up_bound)
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=1; 
                  end
                 else
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                  end
                end   
               else if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0; 
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b10011)
              begin
               if(j!=0)
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0;  
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00011)
              begin
               if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0;  
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00100)
              begin
               if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0;  
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00101)
              begin
               node_ports_class_direction_generator[i][j][m][n][p]=0; 
              end
            end
            
           4:
            begin
             if(node_ports_class_direction_generator[i][j][m][n][p-1]==0)
                                node_ports_class_direction_generator[i][j][m][n][p]=0;
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00010)
              begin
               if(each_cluster_dimension>2)
                begin
                 if(j!=cluster_third_dimension_up_bound)
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=1; 
                  end
                 else
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                  end
                end
               else if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0;    
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b10011)
              begin
               if(j!=0)
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else
                begin
                 if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                  end
                 else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                  end
                 else node_ports_class_direction_generator[i][j][m][n][p]=0;  
                end
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00011)
              begin
               if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0; 
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00100)
              begin
               if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0;
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00101)
              begin
               node_ports_class_direction_generator[i][j][m][n][p]=0; 
              end
            end
            
           5:
            begin
             if(node_ports_class_direction_generator[i][j][m][n][p-1]==0)
                              node_ports_class_direction_generator[i][j][m][n][p]=0;
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b10011)
              begin
               if(j!=0)
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else
                begin
                 if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                  end
                 else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                  end
                 else node_ports_class_direction_generator[i][j][m][n][p]=0;  
                end 
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00011)
              begin
               if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0; 
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00100)
              begin
               if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0;  
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00101)
              begin
               node_ports_class_direction_generator[i][j][m][n][p]=0; 
              end
            end
            
           6:
            begin
             if(node_ports_class_direction_generator[i][j][m][n][p-1]==0)
                              node_ports_class_direction_generator[i][j][m][n][p]=0;
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00011)
              begin
               if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0; 
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00100)
              begin
               if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0; 
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00101)
              begin
               node_ports_class_direction_generator[i][j][m][n][p]=0; 
              end
            end
            
           7:
            begin
             if(node_ports_class_direction_generator[i][j][m][n][p-1]==0)
                              node_ports_class_direction_generator[i][j][m][n][p]=0;
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00100)
              begin
               if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end 
              end
             else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00101)
              begin
               node_ports_class_direction_generator[i][j][m][n][p]=0; 
              end
            end
            
          endcase  
         end
        else if(cluster_topology==1) //Torus
         begin
          case(p)
           0:
            begin
             node_ports_class_direction_generator[i][j][m][n][p][3:0]=1;
             node_ports_class_direction_generator[i][j][m][n][p][4]=1;  
            end
            
           1:
            begin
             node_ports_class_direction_generator[i][j][m][n][p][3:0]=1;
             node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
            end
            
           2:
            begin
             node_ports_class_direction_generator[i][j][m][n][p][3:0]=2;
             node_ports_class_direction_generator[i][j][m][n][p][4]=1;  
            end
            
           3:
            begin
             node_ports_class_direction_generator[i][j][m][n][p][3:0]=2;
             node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
            end
            
           4:
            begin
             if(each_cluster_dimension>2)
              begin
               node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
               node_ports_class_direction_generator[i][j][m][n][p][4]=1; 
              end
             else if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
              begin
               node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
               node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
              end
             else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
              begin
               node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
               node_ports_class_direction_generator[i][j][m][n][p][4]=0;
              end
             else node_ports_class_direction_generator[i][j][m][n][p]=0; 
            end
            
           5:
            begin
             if(each_cluster_dimension>2)
              begin
               node_ports_class_direction_generator[i][j][m][n][p][3:0]=3;
               node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
              end
             else
              begin
               if(node_ports_class_direction_generator[i][j][m][n][p-1]==0) 
                       node_ports_class_direction_generator[i][j][m][n][p]=0;
               else if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00100)
                begin
                 if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                  end
                 else node_ports_class_direction_generator[i][j][m][n][p]=0;
                end
              end
            end
            
           6:
            begin
             if(node_ports_class_direction_generator[i][j][m][n][p-1]==0) 
                       node_ports_class_direction_generator[i][j][m][n][p]=0;
             else if(each_cluster_dimension>2)
              begin
               if(express_link_parse[i][j][m][n][0] & (have_express_link==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=4;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0; 
                end
               else if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                begin
                 node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                 node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                end
               else node_ports_class_direction_generator[i][j][m][n][p]=0;
              end
             else node_ports_class_direction_generator[i][j][m][n][p]=0;
            end
           7:
            begin
             if(node_ports_class_direction_generator[i][j][m][n][p-1]==0) 
                       node_ports_class_direction_generator[i][j][m][n][p]=0;
             else if(each_cluster_dimension>2)
              begin
               if(node_ports_class_direction_generator[i][j][m][n][p-1]==5'b00100)
                begin
                 if(fork_link_parse[i][j][m][n][0] & (have_fork==1))
                  begin
                   node_ports_class_direction_generator[i][j][m][n][p][3:0]=5;
                   node_ports_class_direction_generator[i][j][m][n][p][4]=0;
                  end
                 else node_ports_class_direction_generator[i][j][m][n][p]=0; 
                end  
              end
             else node_ports_class_direction_generator[i][j][m][n][p]=0; 
            end  
          endcase
         end
       end
 end
endfunction
            
function [(no_clusters-1):0] 
         [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
         [cluster_second_dimension_up_bound:0]
         [cluster_first_dimension_up_bound:0]
         [(max_no_port-1):0]
         [(addr_length+$clog2(max_no_port+1)):0] node_ports_next_router_port_generator();
 
 begin
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      for(int p=0;p<max_no_port;p++) node_ports_next_router_port_generator[i][j][m][n][p]=0;
      
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      for(int p=0;p<max_no_port;p++)
       begin
        case(node_ports_class_direction[i][j][m][n][p])
         5'b10001:
          begin
           for(int k=0;k<max_no_port;k++)
            begin
             if(node_ports_class_direction[i][j][m][((n+1)%(cluster_first_dimension_up_bound+1))][k]==5'b00001)
              begin
               node_ports_next_router_port_generator[i][j][m][n][p][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]
                                                                     = node_addr[i][j][m][((n+1)%(cluster_first_dimension_up_bound+1))];      
               node_ports_next_router_port_generator[i][j][m][n][p][$clog2(max_no_port+1):0]=k;                                                                       
              end
            end
          end
         5'b00001:
          begin
           for(int k=0;k<max_no_port;k++)
            begin
             if(node_ports_class_direction[i][j][m][((n>0)?(n-1):cluster_first_dimension_up_bound)][k]==5'b10001)
              begin
               node_ports_next_router_port_generator[i][j][m][n][p][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]
                                                                     = node_addr[i][j][m][((n>0)?(n-1):cluster_first_dimension_up_bound)];
               node_ports_next_router_port_generator[i][j][m][n][p][$clog2(max_no_port+1):0]=k;                                                                       
              end
            end
          end
         5'b10010:
          begin
           for(int k=0;k<max_no_port;k++)
            begin
             if(node_ports_class_direction[i][j][((m+1)%(cluster_second_dimension_up_bound+1))][n][k]==5'b00010)
              begin
               node_ports_next_router_port_generator[i][j][m][n][p][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]
                                                                     = node_addr[i][j][((m+1)%(cluster_second_dimension_up_bound+1))][n];
               node_ports_next_router_port_generator[i][j][m][n][p][$clog2(max_no_port+1):0]=k;                                                                       
              end
            end
          end
         5'b00010:
          begin
           for(int k=0;k<max_no_port;k++)
            begin
             if(node_ports_class_direction[i][j][((m>0)?(m-1):cluster_second_dimension_up_bound)][n][k]==5'b10010)
              begin
               node_ports_next_router_port_generator[i][j][m][n][p][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]
                                                                     = node_addr[i][j][((m>0)?(m-1):cluster_second_dimension_up_bound)][n];  
               node_ports_next_router_port_generator[i][j][m][n][p][$clog2(max_no_port+1):0]=k;                                                                       
              end
            end
          end
         5'b10011:
          begin
           for(int k=0;k<max_no_port;k++)
            begin
             if(node_ports_class_direction[i][((j+1)%(cluster_third_dimension_up_bound+1))][m][n][k]==5'b00011)
              begin
               node_ports_next_router_port_generator[i][j][m][n][p][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]
                                                                     = node_addr[i][((j+1)%(cluster_third_dimension_up_bound+1))][m][n];  
               node_ports_next_router_port_generator[i][j][m][n][p][$clog2(max_no_port+1):0]=k;                                                                       
              end
            end
          end
         5'b00011:
          begin
           for(int k=0;k<max_no_port;k++)
            begin
             if(node_ports_class_direction[i][((j>0)?(j-1):cluster_third_dimension_up_bound)][m][n][k]==5'b10011)
              begin
               node_ports_next_router_port_generator[i][j][m][n][p][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]
                                                                     = node_addr[i][((j>0)?(j-1):cluster_third_dimension_up_bound)][m][n];  
               node_ports_next_router_port_generator[i][j][m][n][p][$clog2(max_no_port+1):0]=k;                                                                       
              end
            end
          end 
         5'b00100:
          begin
           node_ports_next_router_port_generator[i][j][m][n][p][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]=
           express_links_description[express_link_parse[i][j][m][n][no_express_link_id_bits:1]]
                                          [~express_link_parse[i][j][m][n][no_express_link_id_bits+1]];
           node_ports_next_router_port_generator[i][j][m][n][p][$clog2(max_no_port+1):0]=
            node_express_port_no[express_links_description[express_link_parse[i][j][m][n][no_express_link_id_bits:1]]
                                           [~express_link_parse[i][j][m][n][no_express_link_id_bits+1]]
                                           [(addr_length-1):(addr_length-no_cluster_no_addr_bits)]]
                                      [express_links_description[express_link_parse[i][j][m][n][no_express_link_id_bits:1]]
                                           [~express_link_parse[i][j][m][n][no_express_link_id_bits+1]]
                                           [(addr_length-no_cluster_no_addr_bits-1):(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits)]]
                                      [express_links_description[express_link_parse[i][j][m][n][no_express_link_id_bits:1]]
                                           [~express_link_parse[i][j][m][n][no_express_link_id_bits+1]]
                                           [(cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits-1):cluster_first_dimension_no_addr_bits]]
                                      [express_links_description[express_link_parse[i][j][m][n][no_express_link_id_bits:1]]
                                           [~express_link_parse[i][j][m][n][no_express_link_id_bits+1]]
                                           [(cluster_first_dimension_no_addr_bits-1):0]];                                                    
          end
         5'b00101:
          begin
           for(int k=0;k<max_no_port;k++)
            begin
             node_ports_next_router_port_generator[i][j][m][n][p][(addr_length+$clog2(max_no_port+1)):($clog2(max_no_port+1)+1)]=
              fork_link_parse[i][j][m][n][($clog2(no_fork+1)+$clog2(no_fork_fingers+1)):($clog2(no_fork_fingers+1)+1)];
             node_ports_next_router_port_generator[i][j][m][n][p][$clog2(max_no_port+1)]=
              fork_link_parse[i][j][m][n][$clog2(no_fork+1)+$clog2(no_fork_fingers+1)+1];
             node_ports_next_router_port_generator[i][j][m][n][p][($clog2(max_no_port+1)-1):0]=
              fork_link_parse[i][j][m][n][$clog2(no_fork_fingers+1):1];
            end 
          end
        endcase  
       end
 end
endfunction
          
function [(no_fork-1):0]
         [1:0]
         [(link_addr_length-1):0] fork_arm_link_addr_generator();
         
 begin
  for(int i=0;i<no_fork;i++)
   for(int j=0;j<2;j++)
    begin
     fork_arm_link_addr_generator[i][j][(link_addr_length-1):have_fork*(link_addr_length-no_fork_id_bits)]=i;
     fork_arm_link_addr_generator[i][j][(link_addr_length-no_fork_id_bits)-1:1]= {100{1'b1}};
     fork_arm_link_addr_generator[i][j][0]=j;
    end 
 end
endfunction

function [(no_fork-1):0]
         [1:0]
         [(no_fork_fingers-1):0]
         [(link_addr_length-1):0] fork_fingers_link_addr_generator();
 
 begin
  for(int i=0;i<no_fork;i++)
   for(int j=0;j<2;j++)
    for(int m=0;m<no_fork_fingers;m++)
     begin
      fork_fingers_link_addr_generator[i][j][m][(link_addr_length-1):have_fork*(link_addr_length-no_fork_id_bits)]=i;
      fork_fingers_link_addr_generator[i][j][m][(link_addr_length-no_fork_id_bits)-1:no_fork_links_id_bits+1]= {100{1'b1}};
      fork_fingers_link_addr_generator[i][j][m][no_fork_links_id_bits:((have_fork==1)?1:0)]= m;
      fork_fingers_link_addr_generator[i][j][m][0]=j;
     end      
 end
endfunction

function [(no_clusters-1):0] 
         [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
         [cluster_second_dimension_up_bound:0]
         [cluster_first_dimension_up_bound:0]
         [7:0]
         [3:0] node_links_directions_generator();

 begin
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      for(int p=0;p<8;p++) node_links_directions_generator[i][j][m][n][p]=0;
     
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      for(int p=0;p<8;p++)
       begin
        case(p)
         0:
          begin
           for(int q=0;q<max_no_port;q++)
            begin
             if(node_ports_class_direction[i][j][m][n][q]==5'b10001) node_links_directions_generator[i][j][m][n][p]=q+1;
            end 
          end
         1:
          begin
           for(int q=0;q<max_no_port;q++)
            begin
             if(node_ports_class_direction[i][j][m][n][q]==5'b00001) node_links_directions_generator[i][j][m][n][p]=q+1;
            end 
          end
         2:
          begin
           for(int q=0;q<max_no_port;q++)
            begin
             if(node_ports_class_direction[i][j][m][n][q]==5'b10010) node_links_directions_generator[i][j][m][n][p]=q+1;
            end 
          end
         3:
          begin
           for(int q=0;q<max_no_port;q++)
            begin
             if(node_ports_class_direction[i][j][m][n][q]==5'b00010) node_links_directions_generator[i][j][m][n][p]=q+1;
            end 
          end
         4:
          begin
           for(int q=0;q<max_no_port;q++)
            begin
             if(node_ports_class_direction[i][j][m][n][q]==5'b10011) node_links_directions_generator[i][j][m][n][p]=q+1;
            end 
          end
         5:
          begin
           for(int q=0;q<max_no_port;q++)
            begin
             if(node_ports_class_direction[i][j][m][n][q]==5'b00011) node_links_directions_generator[i][j][m][n][p]=q+1;
            end 
          end
         6:
          begin
           for(int q=0;q<max_no_port;q++)
            begin
             if(node_ports_class_direction[i][j][m][n][q]==5'b00100) node_links_directions_generator[i][j][m][n][p]=q+1;
            end 
          end
         7:
          begin
           for(int q=0;q<max_no_port;q++)
            begin
             if(node_ports_class_direction[i][j][m][n][q]==5'b00101) node_links_directions_generator[i][j][m][n][p]=q+1;
            end 
          end
        endcase 
       end
 end
endfunction

function [(no_clusters-1):0] 
         [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
         [cluster_second_dimension_up_bound:0]
         [cluster_first_dimension_up_bound:0]
         [31:0] node_links_directions_to_nodes_generator();
 
 begin
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++)
      node_links_directions_to_nodes_generator[i][j][m][n]={node_links_directions[i][j][m][n][7],
                                                            node_links_directions[i][j][m][n][6],
                                                            node_links_directions[i][j][m][n][5],
                                                            node_links_directions[i][j][m][n][4],
                                                            node_links_directions[i][j][m][n][3],
                                                            node_links_directions[i][j][m][n][2],
                                                            node_links_directions[i][j][m][n][1],
                                                            node_links_directions[i][j][m][n][0]};
                                                            
 end
endfunction
    
task generate_router_files();
 integer router_netlist [(max_no_port-min_no_port):0];
 integer router [(max_no_port-min_no_port):0];
 integer counter_on_ones [(max_no_port-min_no_port):0];
 integer decoder [(max_no_port-min_no_port):0];
 integer encoder [(max_no_port-min_no_port):0];
 integer inport [(max_no_port-min_no_port):0];
 integer inport_in_interface [(max_no_port-min_no_port):0];
 integer inport_in_interface_buf [(max_no_port-min_no_port):0];
 integer inport_in_interface_leftside [(max_no_port-min_no_port):0];
 integer inport_in_interface_rightside [(max_no_port-min_no_port):0];
 integer inport_in_interface_rightside_counter [(max_no_port-min_no_port):0];
 integer inport_in_interface_state [(max_no_port-min_no_port):0];
 integer inport_in_interface_updater [(max_no_port-min_no_port):0];
 integer inport_out_interface [(max_no_port-min_no_port):0];
 integer ones_counter [(max_no_port-min_no_port):0];
 integer outport [(max_no_port-min_no_port):0];
 integer outport_mux [(max_no_port-min_no_port):0];
 integer outport_table [(max_no_port-min_no_port):0];
 integer phit_rec [(max_no_port-min_no_port):0];
 integer priority_encoder [(max_no_port-min_no_port):0];
 integer rcvc_arbiter [(max_no_port-min_no_port):0];
 integer routing_computation [(max_no_port-min_no_port):0];
 integer update_release [(max_no_port-min_no_port):0];
 
 integer tmp_integer; 
 string tmp_string,tmp_itoa;

 for(int i=0;i<=(tmp_max_no_port-min_no_port);i++)
  begin
   router_netlist[i]= $fopen($sformatf("./output_files/verilog_files/router_type_%g.v",(i+min_no_port-2)));
   if(router_netlist[i]==0) $display("Can't create router code file in output_files folder");
   else
    begin
     router[i]=$fopen("./router.v","r");
     if(router[i]==0)  $display("Can't open router.v file");
     else
      begin
       while(!$feof(router[i]))
        begin
         tmp_integer=$fgets(tmp_string,router[i]);
         if(tmp_string.substr(0,25)=="module router(outdata_vec,")
          begin
           tmp_itoa.itoa(i+min_no_port-2);
           tmp_string={"module router_type_",tmp_itoa,"_netlist(outdata_vec,\n"};
          end 
         if(tmp_string.substr(0,31)=="parameter each_cluster_dimension")
          begin
           tmp_itoa.itoa(each_cluster_dimension);
           tmp_string={"parameter each_cluster_dimension=",tmp_itoa,";\n"};
          end        
         if(tmp_string.substr(0,25)=="parameter cluster_topology")
          begin
           tmp_itoa.itoa(cluster_topology);
           tmp_string={"parameter cluster_topology=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,41)=="parameter cluster_first_dimension_up_bound")
          begin
           tmp_itoa.itoa(cluster_first_dimension_up_bound);
           tmp_string={"parameter cluster_first_dimension_up_bound=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,42)=="parameter cluster_second_dimension_up_bound")
          begin
           tmp_itoa.itoa(cluster_second_dimension_up_bound);
           tmp_string={"parameter cluster_second_dimension_up_bound=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,41)=="parameter cluster_third_dimension_up_bound")
          begin
           tmp_itoa.itoa(cluster_third_dimension_up_bound);
           tmp_string={"parameter cluster_third_dimension_up_bound=",tmp_itoa,";\n"};
          end     
         if(tmp_string.substr(0,20)=="parameter no_clusters")
          begin
           tmp_itoa.itoa(no_clusters);
           tmp_string={"parameter no_clusters=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,45)=="parameter cluster_first_dimension_no_addr_bits")
          begin
           tmp_itoa.itoa(cluster_first_dimension_no_addr_bits);
           tmp_string={"parameter cluster_first_dimension_no_addr_bits=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,46)=="parameter cluster_second_dimension_no_addr_bits")
          begin
           tmp_itoa.itoa(cluster_second_dimension_no_addr_bits);
           tmp_string={"parameter cluster_second_dimension_no_addr_bits=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,45)=="parameter cluster_third_dimension_no_addr_bits")
          begin
           tmp_itoa.itoa(cluster_third_dimension_no_addr_bits);
           tmp_string={"parameter cluster_third_dimension_no_addr_bits=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,32)=="parameter no_cluster_no_addr_bits")
          begin
           tmp_itoa.itoa(no_cluster_no_addr_bits);
           tmp_string={"parameter no_cluster_no_addr_bits=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,19)=="parameter no_outport")
          begin
           tmp_itoa.itoa(i+min_no_port+1);
           tmp_string={"parameter no_outport=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,37)=="parameter floorplusone_log2_no_outport")
          begin
           tmp_itoa.itoa($clog2(i+min_no_port+2));
           tmp_string={"parameter floorplusone_log2_no_outport=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,18)=="parameter no_inport")
          begin
           tmp_itoa.itoa(i+min_no_port+1);
           tmp_string={"parameter no_inport=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,36)=="parameter floorplusone_log2_no_inport")
          begin
           tmp_itoa.itoa($clog2(i+min_no_port+2));
           tmp_string={"parameter floorplusone_log2_no_inport=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,14)=="parameter no_vc")
          begin
           tmp_itoa.itoa(no_vc);
           tmp_string={"parameter no_vc=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,32)=="parameter floorplusone_log2_no_vc")
          begin
           tmp_itoa.itoa(floorplusone_log2_no_vc);
           tmp_string={"parameter floorplusone_log2_no_vc=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,18)=="parameter flit_size")
          begin
           tmp_itoa.itoa(flit_size);
           tmp_string={"parameter flit_size=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,36)=="parameter floorplusone_log2_flit_size")
          begin
           tmp_itoa.itoa($clog2(flit_size+1));
           tmp_string={"parameter floorplusone_log2_flit_size=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,18)=="parameter phit_size")
          begin
           tmp_itoa.itoa(phit_size);
           tmp_string={"parameter phit_size=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,17)=="parameter buf_size")
          begin
           tmp_itoa.itoa(buf_size);
           tmp_string={"parameter buf_size=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,35)=="parameter floorplusone_log2_buf_size")
          begin
           tmp_itoa.itoa($clog2(buf_size+1));
           tmp_string={"parameter floorplusone_log2_buf_size=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,25)=="parameter switching_method")
          begin
           tmp_itoa.itoa(switching_method);
           tmp_string={"parameter switching_method=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,20)=="parameter addr_length")
          begin
           tmp_itoa.itoa(addr_length);
           tmp_string={"parameter addr_length=",tmp_itoa,";\n"};
          end
         if(tmp_string.substr(0,29)=="parameter addr_place_in_header")
          begin
           tmp_itoa.itoa(addr_place_in_header);
           tmp_string={"parameter addr_place_in_header=",tmp_itoa,";\n"};
          end        
         if(tmp_integer!=0)$fwrite(router_netlist[i],tmp_string);
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(router[i]);
     counter_on_ones[i]=$fopen("./counter_on_ones.v","r");
     if(counter_on_ones[i]==0)  $display("Can't open counter_on_ones.v file");
     else
      begin
       while(!$feof(counter_on_ones[i]))
        begin
         tmp_integer=$fgets(tmp_string,counter_on_ones[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(counter_on_ones[i]);
     decoder[i]=$fopen("./decoder.v","r");
     if(decoder[i]==0)  $display("Can't open decoder.v file");
     else
      begin
       while(!$feof(decoder[i]))
        begin
         tmp_integer=$fgets(tmp_string,decoder[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(decoder[i]);
     encoder[i]=$fopen("./encoder.v","r");
     if(encoder[i]==0)  $display("Can't open encoder.v file");
     else
      begin
       while(!$feof(encoder[i]))
        begin
         tmp_integer=$fgets(tmp_string,encoder[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(encoder[i]);
     inport[i]=$fopen("./inport.v","r");
     if(inport[i]==0)  $display("Can't open inport.v file");
     else
      begin
       while(!$feof(inport[i]))
        begin
         tmp_integer=$fgets(tmp_string,inport[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(inport[i]);
     inport_in_interface[i]=$fopen("./inport_in_interface.v","r");
     if(inport_in_interface[i]==0)  $display("Can't open inport_in_interface.v file");
     else
      begin
       while(!$feof(inport_in_interface[i]))
        begin
         tmp_integer=$fgets(tmp_string,inport_in_interface[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(inport_in_interface[i]);
     inport_in_interface_buf[i]=$fopen("./inport_in_interface_buf.v","r");
     if(inport_in_interface_buf[i]==0)  $display("Can't open inport_in_interface_buf.v file");
     else
      begin
       while(!$feof(inport_in_interface_buf[i]))
        begin
         tmp_integer=$fgets(tmp_string,inport_in_interface_buf[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(inport_in_interface_buf[i]);
     inport_in_interface_leftside[i]=$fopen("./inport_in_interface_leftside.v","r");
     if(inport_in_interface_leftside[i]==0)  $display("Can't open inport_in_interface_leftside.v file");
     else
      begin
       while(!$feof(inport_in_interface_leftside[i]))
        begin
         tmp_integer=$fgets(tmp_string,inport_in_interface_leftside[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(inport_in_interface_leftside[i]);
     inport_in_interface_rightside[i]=$fopen("./inport_in_interface_rightside.v","r");
     if(inport_in_interface_rightside[i]==0)  $display("Can't open inport_in_interface_rightside.v file");
     else
      begin
       while(!$feof(inport_in_interface_rightside[i]))
        begin
         tmp_integer=$fgets(tmp_string,inport_in_interface_rightside[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(inport_in_interface_rightside[i]);
     inport_in_interface_rightside_counter[i]=$fopen("./inport_in_interface_rightside_counter.v","r");
     if(inport_in_interface_rightside_counter[i]==0)  $display("Can't open inport_in_interface_rightside_counter.v file");
     else
      begin
       while(!$feof(inport_in_interface_rightside_counter[i]))
        begin
         tmp_integer=$fgets(tmp_string,inport_in_interface_rightside_counter[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(inport_in_interface_rightside_counter[i]);
     inport_in_interface_state[i]=$fopen("./inport_in_interface_state.v","r");
     if(inport_in_interface_state[i]==0)  $display("Can't open inport_in_interface_state.v file");
     else
      begin
       while(!$feof(inport_in_interface_state[i]))
        begin
         tmp_integer=$fgets(tmp_string,inport_in_interface_state[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(inport_in_interface_state[i]);
     inport_in_interface_updater[i]=$fopen("./inport_in_interface_updater.v","r");
     if(inport_in_interface_updater[i]==0)  $display("Can't open inport_in_interface_updater.v file");
     else
      begin
       while(!$feof(inport_in_interface_updater[i]))
        begin
         tmp_integer=$fgets(tmp_string,inport_in_interface_updater[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(inport_in_interface_updater[i]);
     inport_out_interface[i]=$fopen("./inport_out_interface.v","r");
     if(inport_out_interface[i]==0)  $display("Can't open inport_out_interface.v file");
     else
      begin
       while(!$feof(inport_out_interface[i]))
        begin
         tmp_integer=$fgets(tmp_string,inport_out_interface[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(inport_out_interface[i]);
     ones_counter[i]=$fopen("./ones_counter.v","r");
     if(ones_counter[i]==0)  $display("Can't open ones_counter.v file");
     else
      begin
       while(!$feof(ones_counter[i]))
        begin
         tmp_integer=$fgets(tmp_string,ones_counter[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(ones_counter[i]);
     outport[i]=$fopen("./outport.v","r");
     if(outport[i]==0)  $display("Can't open outport.v file");
     else
      begin
       while(!$feof(outport[i]))
        begin
         tmp_integer=$fgets(tmp_string,outport[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(outport[i]);
     outport_mux[i]=$fopen("./outport_mux.v","r");
     if(outport_mux[i]==0)  $display("Can't open outport_mux.v file");
     else
      begin
       while(!$feof(outport_mux[i]))
        begin
         tmp_integer=$fgets(tmp_string,outport_mux[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(outport_mux[i]);
     outport_table[i]=$fopen("./outport_table.v","r");
     if(outport_table[i]==0)  $display("Can't open outport_table.v file");
     else
      begin
       while(!$feof(outport_table[i]))
        begin
         tmp_integer=$fgets(tmp_string,outport_table[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(outport_table[i]);
     phit_rec[i]=$fopen("./phit_rec.v","r");
     if(phit_rec[i]==0)  $display("Can't open phit_rec.v file");
     else
      begin
       while(!$feof(phit_rec[i]))
        begin
         tmp_integer=$fgets(tmp_string,phit_rec[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(phit_rec[i]);
     priority_encoder[i]=$fopen("./priority_encoder.v","r");
     if(priority_encoder[i]==0)  $display("Can't open priority_encoder.v file");
     else
      begin
       while(!$feof(priority_encoder[i]))
        begin
         tmp_integer=$fgets(tmp_string,priority_encoder[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(priority_encoder[i]);
     rcvc_arbiter[i]=$fopen("./rcvc_arbiter.v","r");
     if(rcvc_arbiter[i]==0)  $display("Can't open rcvc_arbiter.v file");
     else
      begin
       while(!$feof(rcvc_arbiter[i]))
        begin
         tmp_integer=$fgets(tmp_string,rcvc_arbiter[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(rcvc_arbiter[i]);
     routing_computation[i]=$fopen("./routing_computation.v","r");
     if(routing_computation[i]==0)  $display("Can't open routing_computation.v file");
     else
      begin
       while(!$feof(routing_computation[i]))
        begin
         tmp_integer=$fgets(tmp_string,routing_computation[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end
       $fwrite(router_netlist[i],"\n/*Next Module*/\n"); 
      end
     $fclose(routing_computation[i]);
     update_release[i]=$fopen("./update_release.v","r");
     if(update_release[i]==0)  $display("Can't open update_release.v file");
     else
      begin
       while(!$feof(update_release[i]))
        begin
         tmp_integer=$fgets(tmp_string,update_release[i]);
         if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(router_netlist[i],tmp_string); 
        end 
      end
     $fclose(update_release[i]);
    end
   $fclose(router_netlist[i]);
  end
endtask

task generate_fork_head_file();
 integer fork_module_for_netlist;
 integer fork_module;
 integer counter_on_ones;
 integer decoder;
 integer encoder;
 integer fork_inport;
 integer fork_router;
 integer fork_routing_computation;
 integer inport_in_interface;
 integer inport_in_interface_buf;
 integer inport_in_interface_leftside;
 integer inport_in_interface_rightside;
 integer inport_in_interface_rightside_counter;
 integer inport_in_interface_state;
 integer inport_in_interface_updater;
 integer inport_out_interface;
 integer ones_counter;
 integer outport;
 integer outport_mux;
 integer outport_table;
 integer phit_rec;
 integer priority_encoder;
 integer rcvc_arbiter;
 integer update_release;

 integer tmp_integer;
 string tmp_string,tmp_itoa;
 
 fork_module_for_netlist= $fopen("./output_files/verilog_files/fork_module.v");
 if(fork_module_for_netlist==0) $display("Can't create fork_module.v file in output_files folder");
 else
  begin
   fork_module=$fopen("./fork_module.v","r");
   if(fork_module==0)  $display("Can't open fork_module.v file");
   else
    begin
     while(!$feof(fork_module))
      begin
       tmp_integer=$fgets(tmp_string,fork_module);
       if(tmp_string.substr(0,36)=="module fork_module(fork_arm_data_out,")
        begin
         tmp_string={"module fork_module_netlist(fork_arm_data_out,\n"};
        end        
       if(tmp_string.substr(0,23)=="parameter fork_arm_width")
        begin
         tmp_itoa.itoa(fork_arm_width);
         tmp_string={"parameter fork_arm_width=",tmp_itoa,";\n"};
        end         
       if(tmp_string.substr(0,41)=="parameter floorplusone_log2_fork_arm_width")
        begin
         tmp_itoa.itoa($clog2(fork_arm_width+1));
         tmp_string={"parameter floorplusone_log2_fork_arm_width=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,19)=="parameter no_fingers")
        begin
         tmp_itoa.itoa(no_fork_fingers);
         tmp_string={"parameter no_fingers=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,37)=="parameter floorplusone_log2_no_fingers")
        begin
         tmp_itoa.itoa($clog2(no_fork_fingers+1));
         tmp_string={"parameter floorplusone_log2_no_fingers=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,14)=="parameter no_vc")
        begin
         tmp_itoa.itoa(no_vc);
         tmp_string={"parameter no_vc=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,32)=="parameter floorplusone_log2_no_vc")
        begin
         tmp_itoa.itoa($clog2(no_vc+1));
         tmp_string={"parameter floorplusone_log2_no_vc=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,18)=="parameter flit_size")
        begin
         tmp_itoa.itoa(flit_size);
           tmp_string={"parameter flit_size=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,36)=="parameter floorplusone_log2_flit_size")
        begin
         tmp_itoa.itoa($clog2(flit_size+1));
         tmp_string={"parameter floorplusone_log2_flit_size=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,18)=="parameter phit_size")
        begin
         tmp_itoa.itoa(phit_size);
         tmp_string={"parameter phit_size=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,17)=="parameter buf_size")
        begin
         tmp_itoa.itoa(buf_size);
         tmp_string={"parameter buf_size=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,35)=="parameter floorplusone_log2_buf_size")
        begin
         tmp_itoa.itoa($clog2(buf_size+1));
         tmp_string={"parameter floorplusone_log2_buf_size=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,25)=="parameter switching_method")
        begin
         tmp_itoa.itoa(switching_method);
         tmp_string={"parameter switching_method=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,20)=="parameter addr_length")
        begin
         tmp_itoa.itoa($clog2(no_fork+1));
         tmp_string={"parameter addr_length=",tmp_itoa,";\n"};
        end
       if(tmp_string.substr(0,29)=="parameter addr_place_in_header")
        begin
         tmp_itoa.itoa(addr_place_in_header);
         tmp_string={"parameter addr_place_in_header=",tmp_itoa,";\n"};
        end
       if(tmp_integer!=0)$fwrite(fork_module_for_netlist,tmp_string);
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(fork_module);
   counter_on_ones=$fopen("./counter_on_ones.v","r");
   if(counter_on_ones==0)  $display("Can't open counter_on_ones.v file");
   else
    begin
     while(!$feof(counter_on_ones))
      begin
       tmp_integer=$fgets(tmp_string,counter_on_ones);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(counter_on_ones);
   decoder=$fopen("./decoder.v","r");
   if(decoder==0)  $display("Can't open decoder.v file");
   else
    begin
     while(!$feof(decoder))
      begin
       tmp_integer=$fgets(tmp_string,decoder);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(decoder);
   encoder=$fopen("./encoder.v","r");
   if(encoder==0)  $display("Can't open encoder.v file");
   else
    begin
     while(!$feof(encoder))
      begin
       tmp_integer=$fgets(tmp_string,encoder);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(encoder);
   fork_inport=$fopen("./fork_inport.v","r");
   if(fork_inport==0)  $display("Can't open fork_inport.v file");
   else
    begin
     while(!$feof(fork_inport))
      begin
       tmp_integer=$fgets(tmp_string,fork_inport);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(fork_inport);
   fork_router=$fopen("./fork_router.v","r");
   if(fork_router==0)  $display("Can't open fork_router.v file");
   else
    begin
     while(!$feof(fork_router))
      begin
       tmp_integer=$fgets(tmp_string,fork_router);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(fork_router);
   fork_routing_computation=$fopen("./fork_routing_computation.v","r");
   if(fork_routing_computation==0)  $display("Can't open fork_routing_computation.v file");
   else
    begin
     while(!$feof(fork_routing_computation))
      begin
       tmp_integer=$fgets(tmp_string,fork_routing_computation);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(fork_routing_computation);
   inport_in_interface=$fopen("./inport_in_interface.v","r");
   if(inport_in_interface==0)  $display("Can't open inport_in_interface.v file");
   else
    begin
     while(!$feof(inport_in_interface))
      begin
       tmp_integer=$fgets(tmp_string,inport_in_interface);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(inport_in_interface);
   inport_in_interface_buf=$fopen("./inport_in_interface_buf.v","r");
   if(inport_in_interface_buf==0)  $display("Can't open inport_in_interface_buf.v file");
   else
    begin
     while(!$feof(inport_in_interface_buf))
      begin
       tmp_integer=$fgets(tmp_string,inport_in_interface_buf);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(inport_in_interface_buf);
   inport_in_interface_leftside=$fopen("./inport_in_interface_leftside.v","r");
   if(inport_in_interface_leftside==0)  $display("Can't open inport_in_interface_leftside.v file");
   else
    begin
     while(!$feof(inport_in_interface_leftside))
      begin
       tmp_integer=$fgets(tmp_string,inport_in_interface_leftside);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(inport_in_interface_leftside);
   inport_in_interface_rightside=$fopen("./inport_in_interface_rightside.v","r");
   if(inport_in_interface_rightside==0)  $display("Can't open inport_in_interface_rightside.v file");
   else
    begin
     while(!$feof(inport_in_interface_rightside))
      begin
       tmp_integer=$fgets(tmp_string,inport_in_interface_rightside);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(inport_in_interface_rightside);
   inport_in_interface_rightside_counter=$fopen("./inport_in_interface_rightside_counter.v","r");
   if(inport_in_interface_rightside_counter==0)  $display("Can't open inport_in_interface_rightside_counter.v file");
   else
    begin
     while(!$feof(inport_in_interface_rightside_counter))
      begin
       tmp_integer=$fgets(tmp_string,inport_in_interface_rightside_counter);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(inport_in_interface_rightside_counter);
   inport_in_interface_state=$fopen("./inport_in_interface_state.v","r");
   if(inport_in_interface_state==0)  $display("Can't open inport_in_interface_state.v file");
   else
    begin
     while(!$feof(inport_in_interface_state))
      begin
       tmp_integer=$fgets(tmp_string,inport_in_interface_state);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(inport_in_interface_state);
   inport_in_interface_updater=$fopen("./inport_in_interface_updater.v","r");
   if(inport_in_interface_updater==0)  $display("Can't open inport_in_interface_updater.v file");
   else
    begin
     while(!$feof(inport_in_interface_updater))
      begin
       tmp_integer=$fgets(tmp_string,inport_in_interface_updater);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(inport_in_interface_updater);
   inport_out_interface=$fopen("./inport_out_interface.v","r");
   if(inport_out_interface==0)  $display("Can't open inport_out_interface.v file");
   else
    begin
     while(!$feof(inport_out_interface))
      begin
       tmp_integer=$fgets(tmp_string,inport_out_interface);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(inport_out_interface);
   ones_counter=$fopen("./ones_counter.v","r");
   if(ones_counter==0)  $display("Can't open ones_counter.v file");
   else
    begin
     while(!$feof(ones_counter))
      begin
       tmp_integer=$fgets(tmp_string,ones_counter);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(ones_counter);
   outport=$fopen("./outport.v","r");
   if(outport==0)  $display("Can't open outport.v file");
   else
    begin
     while(!$feof(outport))
      begin
       tmp_integer=$fgets(tmp_string,outport);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(outport);
   outport_mux=$fopen("./outport_mux.v","r");
   if(outport_mux==0)  $display("Can't open outport_mux.v file");
   else
    begin
     while(!$feof(outport_mux))
      begin
       tmp_integer=$fgets(tmp_string,outport_mux);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(outport_mux);
   outport_table=$fopen("./outport_table.v","r");
   if(outport_table==0)  $display("Can't open outport_table.v file");
   else
    begin
     while(!$feof(outport_table))
      begin
       tmp_integer=$fgets(tmp_string,outport_table);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(outport_table);
   phit_rec=$fopen("./phit_rec.v","r");
   if(phit_rec==0)  $display("Can't open phit_rec.v file");
   else
    begin
     while(!$feof(phit_rec))
      begin
       tmp_integer=$fgets(tmp_string,phit_rec);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(phit_rec);
   priority_encoder=$fopen("./priority_encoder.v","r");
   if(priority_encoder==0)  $display("Can't open priority_encoder.v file");
   else
    begin
     while(!$feof(priority_encoder))
      begin
       tmp_integer=$fgets(tmp_string,priority_encoder);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(priority_encoder);
   rcvc_arbiter=$fopen("./rcvc_arbiter.v","r");
   if(rcvc_arbiter==0)  $display("Can't open rcvc_arbiter.v file");
   else
    begin
     while(!$feof(rcvc_arbiter))
      begin
       tmp_integer=$fgets(tmp_string,rcvc_arbiter);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end
     $fwrite(fork_module_for_netlist,"\n/*Next Module*/\n"); 
    end
   $fclose(rcvc_arbiter);
   update_release=$fopen("./update_release.v","r");
   if(update_release==0)  $display("Can't open update_release.v file");
   else
    begin
     while(!$feof(update_release))
      begin
       tmp_integer=$fgets(tmp_string,update_release);
       if(tmp_integer!=0 && tmp_string.substr(1,9)!="timescale")$fwrite(fork_module_for_netlist,tmp_string); 
      end 
    end
   $fclose(update_release);
  end 
 $fclose(fork_module_for_netlist);  
endtask
           
endmodule