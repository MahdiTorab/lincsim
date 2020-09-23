`timescale 1ns/10ps
module manager(inject_dest_addr,
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
               averge_latency,
               no_packet_recieve,
               link_energy_consumption,
               link_class,
               node_no_port_from_network,
               busy);


parameter each_cluster_dimension=2;
parameter cluster_topology=0;           //0:Mesh, 1:Torus
parameter cluster_first_dimension_up_bound=8;
parameter cluster_second_dimension_up_bound=8;
parameter cluster_third_dimension_up_bound=5;
parameter no_clusters=5;
parameter cluster_first_dimension_no_addr_bits=4;
parameter cluster_second_dimension_no_addr_bits=4;
parameter cluster_third_dimension_no_addr_bits=3;
parameter no_cluster_no_addr_bits=3;
parameter have_fork=1;                  //0: there is no fork, 1: there is fork(s)
parameter no_fork=5;                    //number of forks between clusters
parameter no_fork_fingers=4;            //number of fingers that every fork have
parameter have_express_link=1;          //0: there is no express_link, 1: there is express_link(s)
parameter no_express_link=10;           //number of express_link(s)
parameter mapping_strategy= 2;          //0:import mapfile, 1:Sequential Mapping, 2: Random Mapping
parameter frequency=1;                  //in Mega Hertz
parameter injection_rate= 0.1;
parameter simulation_time=100000;       //Just for synthetic
parameter warm_up_time=10000;
parameter syn_or_real=0;
parameter [2:0] syn_pattern=3'b000;
parameter hotspot_id=10;
parameter syn_packet_length= 10;        //This parameter determine synthetic traffic packet_length
parameter traffic_extension= 1;         //Extending real traffic, means lower injection rate (only for real traffic!)
parameter string trace_file_name="trace.txt";
parameter traffic_real_no_packet= 300;
parameter seed=10;                         //if random mapping, change the seed for every new mapping
parameter want_routers_power_estimation= 1;//0: If you don't want to run Design Compiler flow to estimate routers power, 1:If you want routers power estimation (guide for more details)
parameter is_netlist_provided= 1;          //0: If you want estimate routers power and provide netlists set it to 1, else 0 (guide for more details)
parameter string design_compiler_project_path="/home/noc_simulation"; //If you want to estimate power by Design Compiler, define Design Compiler project path
parameter string library_name="osu025_stdcells.db";                   //If you want to estimate power by Design Compiler, define your desirable .db name(guide for more details)
parameter flit_size= 2;                    //In number of phits
parameter phit_size= 32;                   //In number of bits

localparam addr_length= cluster_first_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                        cluster_third_dimension_no_addr_bits+no_cluster_no_addr_bits;   
localparam no_fork_id_bits= have_fork?$clog2(no_fork+1):0;
localparam no_fork_links_id_bits= have_fork?$clog2(no_fork_fingers+1):0;
localparam cycle_period= (10**3) / (2*frequency);
localparam integer no_nodes=(each_cluster_dimension==2 && no_clusters==1)?
                             (cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1):
             ((each_cluster_dimension==3 && no_clusters==1)?
              ((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)*(cluster_third_dimension_up_bound+1)):
                ((each_cluster_dimension==2 && no_clusters>1)?
                 ((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)*no_clusters):
                  ((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)*
                                     (cluster_third_dimension_up_bound+1)*no_clusters)));
                                  
localparam link_addr_length=addr_length+no_fork_links_id_bits+5;

output reg [(addr_length-1):0] inject_dest_addr;
output integer packet_length,inject_time,log_file,pe_id;
output reg [(addr_length-1):0] pe_addr_called;
output integer pe_addr_called_x_addr,pe_addr_called_y_addr,pe_addr_called_z_addr,pe_addr_called_c_addr;
output reg [(link_addr_length-1):0] link_addr_called;
output reg [(addr_length-1):0] hotspot_addr;
output reg pe_report_en;
output reg program_active,active;
output reg full_rs,report_rs,clk;
input [31:0] averge_latency,no_packet_recieve;
input [63:0] link_energy_consumption;
input [3:0] link_class;
input [3:0] node_no_port_from_network;
input busy;

reg [(cluster_first_dimension_no_addr_bits-1):0]  x_addr [(no_nodes-1):0];
reg [(cluster_second_dimension_no_addr_bits-1):0] y_addr [(no_nodes-1):0];
reg [(cluster_third_dimension_no_addr_bits-1):0]  z_addr [(no_nodes-1):0];
reg [(no_cluster_no_addr_bits-1):0] c_addr [(no_nodes-1):0];
reg [(cluster_first_dimension_no_addr_bits-1):0] tmp_x_addr;
reg [(cluster_second_dimension_no_addr_bits-1):0] tmp_y_addr;
reg [(cluster_third_dimension_no_addr_bits-1):0] tmp_z_addr;
reg [(no_cluster_no_addr_bits-1):0] tmp_c_addr;
reg [127:0] total_Latencies;
reg [63:0] total_number_of_received_packets;
reg [63:0] total_first_dimension_link_energy_consumption;
reg [63:0] total_second_dimension_link_energy_consumption;
reg [63:0] total_third_dimension_link_energy_consumption;
reg [63:0] total_type_express_link_energy_consumption;
reg [63:0] total_type_fork_energy_consumption;
reg [63:0] total_link_energy_consumption;
reg [3:0] link_direction_counter;
reg [63:0] node_links_energy_consumption [(no_nodes-1):0];
reg [63:0] fork_head_links_power_consumption [(no_fork-1):0][1:0];
reg [6:0] router_compile;
reg random_mapping_tags [(no_clusters-1):0] 
                        [((each_cluster_dimension>2)?(cluster_third_dimension_up_bound):0):0]
                        [cluster_second_dimension_up_bound:0]
                        [cluster_first_dimension_up_bound:0];
reg real_traffic_end_point=0;                        
integer trace_file,trace_file_status,dest_id,node_counter,timer,inject_time_tmp,manyclocks;
integer report_file,simulation_duration,no_packet_read,tmp_seed,packet_length_NoHeader;
integer vcd_to_saif_script_file,design_compiler_script_file_for_compilation,design_compiler_script_file_for_power_estimation;
    
initial
 begin
  if(syn_or_real==0)
   log_file=$fopen($sformatf("./reports/injection_rate_%f_recieved_packets_log.txt",injection_rate));
  if(syn_or_real==1)
   log_file=$fopen($sformatf("./reports/%f_RealisticTraffic_recieved_packets_log.txt",trace_file_name));
  node_counter=0;
  tmp_seed=seed;
  for(int i=0;i<no_clusters;i++)
   for(int j=0;j<((each_cluster_dimension>2)?(cluster_third_dimension_up_bound+1):1);j++)
    for(int m=0;m<cluster_second_dimension_up_bound+1;m++)
     for(int n=0;n<cluster_first_dimension_up_bound+1;n++) random_mapping_tags[i][j][m][n]=0;
  if(mapping_strategy==0) reading_map_file();  
  else if(mapping_strategy==1)
   begin
    for(int i=0;i<no_nodes;i++)
     begin       
      if(each_cluster_dimension==2 && no_clusters==1)
       begin
        x_addr[i]= i%(cluster_first_dimension_up_bound+1);
        y_addr[i]= ((i%((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)))-
                                            (i%(cluster_first_dimension_up_bound+1)))/(cluster_first_dimension_up_bound+1); 
       end
      else if(each_cluster_dimension==2 && no_clusters>1)
       begin
        x_addr[i]= i%(cluster_first_dimension_up_bound+1);
        y_addr[i]= ((i%((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)))-
                                            (i%(cluster_first_dimension_up_bound+1)))/(cluster_first_dimension_up_bound+1);
        z_addr[i]=0;
        c_addr[i]= (i-(i%((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1))))/
                                              ((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1));
       end
      else if(each_cluster_dimension==3 && no_clusters==1)
       begin
        x_addr[i]= i%(cluster_first_dimension_up_bound+1);
        y_addr[i]= ((i%((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)))-
                                                (i%(cluster_first_dimension_up_bound+1)))/(cluster_first_dimension_up_bound+1);
        z_addr[i]= (i-(i%((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1))))/
                                                  ((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1));
        c_addr[i]=0;
       end
      else if(each_cluster_dimension==3 && no_clusters>1)
       begin
        x_addr[i]= i%(cluster_first_dimension_up_bound+1);
        y_addr[i]= ((i%((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)))-
                                                (i%(cluster_first_dimension_up_bound+1)))/(cluster_first_dimension_up_bound+1);
        z_addr[i]= ((i%((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)*(cluster_third_dimension_up_bound+1)))-
                        (i%((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1))))/
                                                  ((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1));
        c_addr[i]= (i-(i%((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)*
                     (cluster_third_dimension_up_bound+1))))/
                     ((cluster_first_dimension_up_bound+1)*(cluster_second_dimension_up_bound+1)*(cluster_third_dimension_up_bound+1));
       end
     end
   end
  else if(mapping_strategy==2)
   begin
    while(node_counter<no_nodes)
     begin
      tmp_c_addr=($urandom(tmp_seed)/($urandom(tmp_seed)%100))%no_clusters;
      tmp_seed++;
      tmp_z_addr=(each_cluster_dimension>2)?($urandom(tmp_seed)/($urandom(tmp_seed)%100))%(cluster_third_dimension_up_bound+1):0;
      tmp_seed++;
      tmp_y_addr=($urandom(tmp_seed)/($urandom(tmp_seed)%100))%(cluster_second_dimension_up_bound+1);
      tmp_seed++;
      tmp_x_addr=($urandom(tmp_seed)/($urandom(tmp_seed)%100))%(cluster_first_dimension_up_bound+1);
      tmp_seed++;
      if(~random_mapping_tags[tmp_c_addr][tmp_z_addr][tmp_y_addr][tmp_x_addr])
       begin
        c_addr[node_counter]= tmp_c_addr;
        z_addr[node_counter]= tmp_z_addr;
        y_addr[node_counter]= tmp_y_addr;
        x_addr[node_counter]= tmp_x_addr;
        random_mapping_tags[tmp_c_addr][tmp_z_addr][tmp_y_addr][tmp_x_addr]=1;
        node_counter++;
       end
     end
   end
  inject_dest_addr=0;
  no_packet_read=0;
  packet_length=0;
  inject_time=0;
  pe_id=0;
  pe_addr_called=0;
  pe_addr_called_x_addr=0;
  pe_addr_called_y_addr=0;
  pe_addr_called_z_addr=0;
  pe_addr_called_c_addr=0;
  link_addr_called=0;
  pe_report_en=0;
  program_active=0;
  active=0;
  report_rs=0;
  clk=0;
  for(int i=0;i<no_nodes;i++) node_links_energy_consumption[i]=0;
  if(have_fork)
   for(int i=0;i<no_fork;i++)
    for(int j=0;j<2;j++)
     fork_head_links_power_consumption[i][j]=0;
  full_rs=1;
  report_rs=1;
  #(cycle_period)clk=1;
  #(cycle_period)clk=0;
  #(cycle_period)clk=1; 
  full_rs=0;
  report_rs=0;
  if(syn_pattern==3'b010)
   begin       
    if(each_cluster_dimension==2 && no_clusters==1) hotspot_addr={1'b0,1'b0,y_addr[hotspot_id],x_addr[hotspot_id]};
    else if(each_cluster_dimension==2 && no_clusters>1) hotspot_addr=
                                                   {c_addr[hotspot_id],1'b0,y_addr[hotspot_id],x_addr[hotspot_id]};
    else if(each_cluster_dimension==3 && no_clusters==1) hotspot_addr=
                                                   {1'b0,z_addr[hotspot_id],y_addr[hotspot_id],x_addr[hotspot_id]};                                                    
    else if(each_cluster_dimension==3 && no_clusters>1) hotspot_addr=
                                     {c_addr[hotspot_id],z_addr[hotspot_id],y_addr[hotspot_id],x_addr[hotspot_id]};
   end
  else hotspot_addr=0;  
  for(int i=0;i<no_nodes;i++)
   begin
    #(cycle_period)clk=0;
    program_active=1;
    pe_id=i;
    if(each_cluster_dimension==2 && no_clusters==1)
     begin
      pe_addr_called={1'b0,1'b0,y_addr[i],x_addr[i]};
      pe_addr_called_x_addr=x_addr[i];
      pe_addr_called_y_addr=y_addr[i];
      pe_addr_called_z_addr=0;
      pe_addr_called_c_addr=0;
     end
    else if(each_cluster_dimension==2 && no_clusters>1) 
     begin
      pe_addr_called={c_addr[i],1'b0,y_addr[i],x_addr[i]};
      pe_addr_called_x_addr=x_addr[i];
      pe_addr_called_y_addr=y_addr[i];
      pe_addr_called_z_addr=0;
      pe_addr_called_c_addr=c_addr[i];       
     end
    else if(each_cluster_dimension==3 && no_clusters==1)                                                    
     begin
      pe_addr_called={1'b0,z_addr[i],y_addr[i],x_addr[i]};
      pe_addr_called_x_addr=x_addr[i];
      pe_addr_called_y_addr=y_addr[i];
      pe_addr_called_z_addr=z_addr[i];
      pe_addr_called_c_addr=0;      
     end 
    else if(each_cluster_dimension==3 && no_clusters>1)
     begin
      pe_addr_called={c_addr[i],z_addr[i],y_addr[i],x_addr[i]};
      pe_addr_called_x_addr=x_addr[i];
      pe_addr_called_y_addr=y_addr[i];
      pe_addr_called_z_addr=z_addr[i];
      pe_addr_called_c_addr=c_addr[i];      
     end
    #(cycle_period)clk=1;
   end
  #(cycle_period)clk=0;
  #(cycle_period)clk=1;

  if(want_routers_power_estimation==1 && is_netlist_provided==0)
   begin
    $display("The synthesizable RTL code of router and fork_head is now available in output_files folder use them to generate netlists verilog codes(guide for more details)");
    $exit;
   end
  if(syn_or_real==1)
   begin
    trace_file=$fopen({"./input_files/",trace_file_name},"r");
    if(trace_file==0) $display("error in reading trace_file!");
    else
     begin
      while(!($feof(trace_file)||(traffic_real_no_packet!=0 && no_packet_read>=traffic_real_no_packet)))
       begin
        #(cycle_period)clk=0;
        program_active=1;
        trace_file_status=$fscanf(trace_file,"%d %d %d %d\n",inject_time_tmp,pe_id,dest_id,packet_length_NoHeader);
        inject_time=inject_time_tmp*traffic_extension;
        if(packet_length_NoHeader==1) packet_length_NoHeader=2;
        packet_length=packet_length_NoHeader+1;
        if(each_cluster_dimension==2 && no_clusters==1) inject_dest_addr={1'b0,1'b0,y_addr[dest_id],x_addr[dest_id]};
        else if(each_cluster_dimension==2 && no_clusters>1) inject_dest_addr={c_addr[dest_id],1'b0,y_addr[dest_id],x_addr[dest_id]};
        else if(each_cluster_dimension==3 && no_clusters==1) inject_dest_addr={1'b0,z_addr[dest_id],y_addr[dest_id],x_addr[dest_id]};                                                    
        else if(each_cluster_dimension==3 && no_clusters>1) inject_dest_addr={c_addr[dest_id],z_addr[dest_id],y_addr[dest_id],x_addr[dest_id]};
        
            if(each_cluster_dimension==2 && no_clusters==1)
              begin
               pe_addr_called={1'b0,1'b0,y_addr[pe_id],x_addr[pe_id]};
               pe_addr_called_x_addr=x_addr[pe_id];
               pe_addr_called_y_addr=y_addr[pe_id];
               pe_addr_called_z_addr=0;
               pe_addr_called_c_addr=0;
              end
             else if(each_cluster_dimension==2 && no_clusters>1) 
              begin
               pe_addr_called={c_addr[pe_id],1'b0,y_addr[pe_id],x_addr[pe_id]};
               pe_addr_called_x_addr=x_addr[pe_id];
               pe_addr_called_y_addr=y_addr[pe_id];
               pe_addr_called_z_addr=0;
               pe_addr_called_c_addr=c_addr[pe_id];       
              end
             else if(each_cluster_dimension==3 && no_clusters==1)                                                    
              begin
               pe_addr_called={1'b0,z_addr[pe_id],y_addr[pe_id],x_addr[pe_id]};
               pe_addr_called_x_addr=x_addr[pe_id];
               pe_addr_called_y_addr=y_addr[pe_id];
               pe_addr_called_z_addr=z_addr[pe_id];
               pe_addr_called_c_addr=0;      
              end 
             else if(each_cluster_dimension==3 && no_clusters>1)
              begin
               pe_addr_called={c_addr[pe_id],z_addr[pe_id],y_addr[pe_id],x_addr[pe_id]};
               pe_addr_called_x_addr=x_addr[pe_id];
               pe_addr_called_y_addr=y_addr[pe_id];
               pe_addr_called_z_addr=z_addr[pe_id];
               pe_addr_called_c_addr=c_addr[pe_id];      
              end                                       
        #(cycle_period)clk=1;
        no_packet_read++;
       end
     end  
     $fclose(trace_file);
   end
  if(syn_or_real==0)packet_length=syn_packet_length+1; //+1 for the header flit
  #(cycle_period)clk=0;
  program_active=0;
  #(cycle_period)clk=1;
  if(syn_or_real==0)
   report_file= $fopen($sformatf("./reports/injection_rate_%f_report.txt",injection_rate));
  if(syn_or_real==1)
   report_file= $fopen($sformatf("./reports/%f_RealisticTraffic_report.txt",trace_file_name));
  active=1;
  if(syn_or_real==0)
   begin
    simulation_duration= simulation_time-warm_up_time;
    for(int j=0;j<warm_up_time;j++)
     begin
      #(cycle_period)clk=0;
      #(cycle_period)clk=1;
     end
    report_rs=1;
    #(cycle_period)clk=0;
    #(cycle_period)clk=1;
    report_rs=0;
    for(int j=0;j<(simulation_time-warm_up_time);j++)
    begin
     #(cycle_period)clk=0;
     #(cycle_period)clk=1;
    end
   end
  else
   begin
    simulation_duration=0;
    while(busy==1 && !(real_traffic_end_point&syn_or_real))
     begin
      #(cycle_period)clk=0;
      #(cycle_period)clk=1;
      if(simulation_duration==warm_up_time)
       begin
        report_rs=1;
        #(cycle_period)clk=0;
        #(cycle_period)clk=1;
        simulation_duration++;
        report_rs=0; 
       end
      simulation_duration++;
     end
    if(simulation_duration>warm_up_time)simulation_duration=simulation_duration-warm_up_time;
   end
  active=0;
  #(cycle_period)clk=0;
  #(cycle_period)clk=1;
  total_Latencies=0;
  total_first_dimension_link_energy_consumption=0;
  total_second_dimension_link_energy_consumption=0;
  total_third_dimension_link_energy_consumption=0;
  total_type_express_link_energy_consumption=0;
  total_type_fork_energy_consumption=0;
  total_link_energy_consumption=0;
  for(int j=0;j<no_nodes;j++)
   begin
    pe_report_en=1;
    if(each_cluster_dimension==2 && no_clusters==1)
     begin
      pe_addr_called={1'b0,1'b0,y_addr[j],x_addr[j]};
      pe_addr_called_x_addr=x_addr[j];
      pe_addr_called_y_addr=y_addr[j];
      pe_addr_called_z_addr=0;
      pe_addr_called_c_addr=0;
     end
    else if(each_cluster_dimension==2 && no_clusters>1) 
     begin
      pe_addr_called={c_addr[j],1'b0,y_addr[j],x_addr[j]};
      pe_addr_called_x_addr=x_addr[j];
      pe_addr_called_y_addr=y_addr[j];
      pe_addr_called_z_addr=0;
      pe_addr_called_c_addr=c_addr[j];       
     end
    else if(each_cluster_dimension==3 && no_clusters==1)                                                    
     begin
      pe_addr_called={1'b0,z_addr[j],y_addr[j],x_addr[j]};
      pe_addr_called_x_addr=x_addr[j];
      pe_addr_called_y_addr=y_addr[j];
      pe_addr_called_z_addr=z_addr[j];
      pe_addr_called_c_addr=0;      
     end 
    else if(each_cluster_dimension==3 && no_clusters>1)
     begin
      pe_addr_called={c_addr[j],z_addr[j],y_addr[j],x_addr[j]};
      pe_addr_called_x_addr=x_addr[j];
      pe_addr_called_y_addr=y_addr[j];
      pe_addr_called_z_addr=z_addr[j];
      pe_addr_called_c_addr=c_addr[j];      
     end 
    #(cycle_period);                                    
    if(|averge_latency==1)
     begin
      total_Latencies= total_Latencies + (no_packet_recieve*averge_latency);
     end
    pe_report_en=0;
    for(link_direction_counter=4'b0000;link_direction_counter<8;link_direction_counter++)
     begin     
      if(each_cluster_dimension==2 && no_clusters==1)
                                                 link_addr_called={1'b0,1'b0,y_addr[j],x_addr[j],{(link_addr_length-addr_length-4){1'b0}},link_direction_counter};
      else if(each_cluster_dimension==2 && no_clusters>1)
                                       link_addr_called={c_addr[j],1'b0,y_addr[j],x_addr[j],{(link_addr_length-addr_length-4){1'b0}},link_direction_counter};
      else if(each_cluster_dimension==3 && no_clusters==1)
                                       link_addr_called={1'b0,z_addr[j],y_addr[j],x_addr[j],{(link_addr_length-addr_length-4){1'b0}},link_direction_counter};
      else if(each_cluster_dimension==3 && no_clusters>1) 
                             link_addr_called={c_addr[j],z_addr[j],y_addr[j],x_addr[j],{(link_addr_length-addr_length-4){1'b0}},link_direction_counter};
      #(cycle_period);
      if(|link_energy_consumption)
       begin
        case(link_class)
         4'b0001:  //First dimension plus
          begin
           total_link_energy_consumption= total_link_energy_consumption+link_energy_consumption;
           total_first_dimension_link_energy_consumption=total_first_dimension_link_energy_consumption+link_energy_consumption;
           node_links_energy_consumption[j]= node_links_energy_consumption[j]+link_energy_consumption;           
          end
         4'b0010:  //Second dimension plus
          begin
           total_link_energy_consumption= total_link_energy_consumption+link_energy_consumption;
           total_second_dimension_link_energy_consumption=total_second_dimension_link_energy_consumption+link_energy_consumption;
           node_links_energy_consumption[j]= node_links_energy_consumption[j]+link_energy_consumption; 
          end
         4'b0011:  //Third dimension plus
          begin
           total_link_energy_consumption= total_link_energy_consumption+link_energy_consumption;
           total_third_dimension_link_energy_consumption=total_third_dimension_link_energy_consumption+link_energy_consumption;
           node_links_energy_consumption[j]= node_links_energy_consumption[j]+link_energy_consumption;  
          end
         4'b0100:  //Inter-cluster link
          begin
           total_link_energy_consumption= total_link_energy_consumption+link_energy_consumption;
           total_type_express_link_energy_consumption=total_type_express_link_energy_consumption+link_energy_consumption;
           node_links_energy_consumption[j]= node_links_energy_consumption[j]+link_energy_consumption; 
          end
         4'b0101:  //Fork-finger_link
          begin
           total_link_energy_consumption= total_link_energy_consumption+link_energy_consumption;
           total_type_fork_energy_consumption=total_type_fork_energy_consumption+link_energy_consumption;
           node_links_energy_consumption[j]= node_links_energy_consumption[j]+link_energy_consumption; 
          end
        endcase
       end
     end
   end   
   #(cycle_period);
   if(have_fork==1)
    begin
     for(int j=0;j<no_fork;j++)
      begin
       #(cycle_period);
       link_addr_called[(link_addr_length-1):have_fork*(link_addr_length-no_fork_id_bits)]= j;
       link_addr_called[(link_addr_length-no_fork_id_bits)-1:1]= {100{1'b1}};
       link_addr_called[0]=0;
       #(cycle_period);
       if(|link_energy_consumption)
        begin
         total_link_energy_consumption= total_link_energy_consumption+link_energy_consumption;
         total_type_fork_energy_consumption=total_type_fork_energy_consumption+link_energy_consumption;
         fork_head_links_power_consumption[j][0]=fork_head_links_power_consumption[j][0]+link_energy_consumption; 
        end
       for(int k=0;k<(no_fork_fingers+1);k++)
        begin
         link_addr_called[(link_addr_length-1):have_fork*(link_addr_length-no_fork_id_bits)]= j;
         link_addr_called[(link_addr_length-no_fork_id_bits)-1:no_fork_links_id_bits+1]= {100{1'b1}};
         link_addr_called[no_fork_links_id_bits:((have_fork==1)?1:0)]= k;
         link_addr_called[0]=0;
         #(cycle_period);
         if(|link_energy_consumption)
          begin
           total_link_energy_consumption= total_link_energy_consumption+link_energy_consumption;
           total_type_fork_energy_consumption=total_type_fork_energy_consumption+link_energy_consumption;
           fork_head_links_power_consumption[j][0]=fork_head_links_power_consumption[j][0]+link_energy_consumption;
          end                                                                                                              
        end
       link_addr_called[(link_addr_length-1):have_fork*(link_addr_length-no_fork_id_bits)]= j;
       link_addr_called[(link_addr_length-no_fork_id_bits)-1:1]= {100{1'b1}};
       link_addr_called[0]=1;
       #(cycle_period);
       if(|link_energy_consumption)
        begin
         total_link_energy_consumption= total_link_energy_consumption+link_energy_consumption;
         total_type_fork_energy_consumption=total_type_fork_energy_consumption+link_energy_consumption;
         fork_head_links_power_consumption[j][1]=fork_head_links_power_consumption[j][1]+link_energy_consumption; 
        end
       for(int k=0;k<(no_fork_fingers+1);k++)
        begin
         link_addr_called[(link_addr_length-1):have_fork*(link_addr_length-no_fork_id_bits)]= j;
         link_addr_called[(link_addr_length-no_fork_id_bits)-1:no_fork_links_id_bits+1]= {100{1'b1}};
         link_addr_called[no_fork_links_id_bits:((have_fork==1)?1:0)]= k;
         link_addr_called[0]=1;
         #(cycle_period);
         if(|link_energy_consumption)
          begin
           total_link_energy_consumption= total_link_energy_consumption+link_energy_consumption;
           total_type_fork_energy_consumption=total_type_fork_energy_consumption+link_energy_consumption;
           fork_head_links_power_consumption[j][1]=fork_head_links_power_consumption[j][1]+link_energy_consumption;
          end                                                                                                              
        end  
      end
    end
   if(syn_or_real==0)
    $fdisplay(report_file,"Injection_rate= ",injection_rate,"\n");
   if(syn_or_real==1)
    $fdisplay(report_file,"Realistic Traffic:\n");
   $fdisplay(report_file,"Total Execution Time: ",timer,"\n");
   $fdisplay(report_file,"Average_latency= %g",(total_Latencies/total_number_of_received_packets),"\n");
   if(syn_or_real==0)
    $fdisplay(report_file,"Throughput(Mbps)= %g",(total_number_of_received_packets*syn_packet_length*flit_size*phit_size*(10**3))/
                                                                                 (2*cycle_period*simulation_duration));
   $fdisplay(report_file,"Link power consumption:");
   $fdisplay(report_file,"first_dimension_link_power_consumption(nW)=   %g",
                            (total_first_dimension_link_energy_consumption*1000)/(2*cycle_period*simulation_duration));
   $fdisplay(report_file,"second_dimension_link_power_consumption(nW)=  %g",
                           (total_second_dimension_link_energy_consumption*1000)/(2*cycle_period*simulation_duration));                        
                             
   if(each_cluster_dimension>2)
    $fdisplay(report_file,"third_dimension_link_power_consumption(nW)=   %g",
                            (total_third_dimension_link_energy_consumption*1000)/(2*cycle_period*simulation_duration));
   if(have_express_link==1)
    $fdisplay(report_file,"type_express_link_power_consumption(nW)= %g",
                         (total_type_express_link_energy_consumption*1000)/(2*cycle_period*simulation_duration));
   if(have_fork==1)
    $fdisplay(report_file,"type_fork_energy_consumption(nW)=             %g",
                         (total_type_fork_energy_consumption*1000)/(2*cycle_period*simulation_duration));                                                                                                                     
   $fdisplay(report_file,"Total_link_power_consumption(nW)=             %g",(total_link_energy_consumption*1000)/
                                                                                 (2*cycle_period*simulation_duration));
   $fdisplay(report_file,"*****\n","Nodes links power consumptions detail(nW):");
   for(int j=0;j<no_nodes;j++)
    begin
     $fdisplay(report_file,"Node:%g",j," Links power consumption=%g",(node_links_energy_consumption[j]*1000)/
                                                                                 (2*cycle_period*simulation_duration)); 
    end
   if(have_fork==1)
    for(int j=0;j<no_fork;j++)
     for(int k=0;k<2;k++)
      begin
       $fdisplay(report_file,"Fork:%g",j," Head:%g",k," Links power consumption=%g",(fork_head_links_power_consumption[j][k]*1000)/
                                                                                 (2*cycle_period*simulation_duration));
      end
   $fclose(report_file);
 end
  
initial
 begin
  router_compile=0;
  if(want_routers_power_estimation==1)
   begin
    vcd_to_saif_script_file=$fopen("./output_files/scripts/vcd_to_saif_script.txt");
    if(vcd_to_saif_script_file==0)  $display("Can't create vcd_to_saif_script.txt file in output_file/scripts");
    else if(is_netlist_provided==1)
     begin
      $fdisplay(vcd_to_saif_script_file,"cd ",design_compiler_project_path);
      if(have_fork==1)
       begin
        for(int i=0;i<no_fork;i++)
         begin
          $fdisplay(vcd_to_saif_script_file,"vcd2saif -input fork_head_zero_%g",i,".vcd -o fork_head_zero_%g",i,".saif");
          $fdisplay(vcd_to_saif_script_file,"vcd2saif -input fork_head_one_%g",i,".vcd -o fork_head_one_%g",i,".saif");
         end
       end
     end
   end
   
  if(want_routers_power_estimation==1)
   begin
    design_compiler_script_file_for_compilation=$fopen("./output_files/scripts/design_compiler_script_for_compilation.txt");
    if(design_compiler_script_file_for_compilation==0)
         $display("Can't create design_compiler_script_file_for_compilation.txt file in output_file/scripts");

    else
     begin
      if(is_netlist_provided==0)
       begin
        $fdisplay(design_compiler_script_file_for_compilation,"cd ",design_compiler_project_path);
        $fdisplay(design_compiler_script_file_for_compilation,"set link_library ",library_name);
        $fdisplay(design_compiler_script_file_for_compilation,"set target_library ",library_name);
        $fdisplay(design_compiler_script_file_for_compilation,"define_design_lib WORK -path ./WORK");   
        $fdisplay(design_compiler_script_file_for_compilation,"set my_clock_pin clk");    
        $fdisplay(design_compiler_script_file_for_compilation,"set my_clk_freq_MHz %g",frequency);    
        $fdisplay(design_compiler_script_file_for_compilation,"set my_period [expr 1000 / $my_clk_freq_MHz]");
        if(have_fork)
         begin           
          $fdisplay(design_compiler_script_file_for_compilation,"analyze -f verilog fork_module.v");
          $fdisplay(design_compiler_script_file_for_compilation,"set my_toplevel fork_module_netlist");           
          $fdisplay(design_compiler_script_file_for_compilation,"elaborate fork_module_netlist");
          $fdisplay(design_compiler_script_file_for_compilation,"create_clock -period $my_period clk");           
          $fdisplay(design_compiler_script_file_for_compilation,"link");
          $fdisplay(design_compiler_script_file_for_compilation,"uniquify");
          $fdisplay(design_compiler_script_file_for_compilation,"compile_ultra -gate_clock");
          $fdisplay(design_compiler_script_file_for_compilation,"check_design");
          $fdisplay(design_compiler_script_file_for_compilation,"write -f verilog -hierarchy -output ./netlists/fork_module_netlist.v");
          $fdisplay(design_compiler_script_file_for_compilation,"report_qor > ./reports/fork_module_compile_report.txt");
         end
       end
     end   
   end
  
  if(want_routers_power_estimation==1)
   begin 
    design_compiler_script_file_for_power_estimation=$fopen("./output_files/scripts/design_compiler_script_for_power_estimation.txt");
    if(design_compiler_script_file_for_power_estimation==0)
           $display("Can't create design_compiler_script_file_for_power_estimation.txt file in output_file/scripts");
    else if(is_netlist_provided==1)
     begin
      $fdisplay(design_compiler_script_file_for_power_estimation,"cd ",design_compiler_project_path);
      $fdisplay(design_compiler_script_file_for_power_estimation,"set link_library ",library_name);
      if(have_fork==1)
       begin
        for(int i=0;i<no_fork;i++)
         begin
          $fdisplay(design_compiler_script_file_for_power_estimation,"read_verilog ./netlists/fork_module_netlist.v");
          $fdisplay(design_compiler_script_file_for_power_estimation,"link");
          $fdisplay(design_compiler_script_file_for_power_estimation,"current_design fork_module_netlist");
          $fdisplay(design_compiler_script_file_for_power_estimation,"read_saif -input fork_head_zero_%g",i,".saif -instance_name simulator_top/network/genblk7.fork_loop[%g",
                                            i,"].sv_fork_module_headzero/fork_module_cortex/genblk1.fork_module_netlist");
          $fdisplay(design_compiler_script_file_for_power_estimation,"report_power > ./reports/fork_head_zero_%g",i,"_power_report.txt");
        
          $fdisplay(design_compiler_script_file_for_power_estimation,"read_verilog ./netlists/fork_module_netlist.v");
          $fdisplay(design_compiler_script_file_for_power_estimation,"read_saif -input fork_head_one_%g",i,".saif -instance_name simulator_top/network/genblk7.fork_loop[%g",
                                            i,"].sv_fork_module_headone/fork_module_cortex/genblk1.fork_module_netlist");
          $fdisplay(design_compiler_script_file_for_power_estimation,"report_power > ./reports/fork_head_one_%g",i,"_power_report.txt");
         end
       end
     end   
   end
 end

always@(posedge clk)
 begin
  if(program_active && packet_length==0 && want_routers_power_estimation==1)
   begin
    if(vcd_to_saif_script_file!=0 && want_routers_power_estimation==1 && is_netlist_provided==1)
     begin
      $fdisplay(vcd_to_saif_script_file,"vcd2saif -input router_%g",(node_no_port_from_network-2),"_%g",pe_id,".vcd -o router_%g",(node_no_port_from_network-2),"_%g",pe_id,".saif");
     end
    else $display("Can't write in vcd_to_saif_script.txt file in output_files folder");
    
    if(design_compiler_script_file_for_compilation!=0)
     begin
      if(router_compile[node_no_port_from_network-2]==0)
       begin
        if(want_routers_power_estimation==1 && is_netlist_provided==0)
         begin
          router_compile[node_no_port_from_network-2]=1;          
          $fdisplay(design_compiler_script_file_for_compilation,"analyze -f verilog router_type_%g",(node_no_port_from_network-2),".v");
          $fdisplay(design_compiler_script_file_for_compilation,"set my_toplevel router_type_%g",(node_no_port_from_network-2),"_netlist");          
          $fdisplay(design_compiler_script_file_for_compilation,"elaborate router_type_%g",(node_no_port_from_network-2),"_netlist");          
          $fdisplay(design_compiler_script_file_for_compilation,"create_clock -period $my_period clk");          
          $fdisplay(design_compiler_script_file_for_compilation,"link");
          $fdisplay(design_compiler_script_file_for_compilation,"uniquify");
          $fdisplay(design_compiler_script_file_for_compilation,"compile_ultra -gate_clock");
          $fdisplay(design_compiler_script_file_for_compilation,"check_design");
          $fdisplay(design_compiler_script_file_for_compilation,"write -f verilog -hierarchy -output ./netlists/router_type_%g",(node_no_port_from_network-2),"_netlist.v");
          $fdisplay(design_compiler_script_file_for_compilation,"report_qor > ./reports/router_type_%g",(node_no_port_from_network-2),"_compile_report.txt");
         end
       end
     end
    else $display("Can't write in design_compiler_script_file_for_compilation.txt file in output_files/scripts");
      
    if(want_routers_power_estimation==1 && is_netlist_provided==1 && design_compiler_script_file_for_power_estimation!=0)  
     begin
      $fdisplay(design_compiler_script_file_for_power_estimation,"read_verilog ./netlists/router_type_%g",(node_no_port_from_network-2),"_netlist.v");
      $fdisplay(design_compiler_script_file_for_power_estimation,"link");
      $fdisplay(design_compiler_script_file_for_power_estimation,"current_design router_type_%g",(node_no_port_from_network-2),"_netlist");
      $fdisplay(design_compiler_script_file_for_power_estimation,"read_saif -input router_%g",(node_no_port_from_network-2),"_%g",pe_id,".saif -instance_name simulator_top/network/node_cluster_loop[%g",
       pe_addr_called_c_addr,"].node_third_loop[%g",pe_addr_called_z_addr,"].node_second_loop[%g",pe_addr_called_y_addr,"].node_first_loop[%g",pe_addr_called_x_addr,"].sv_router_pc/sv_router/router_cortex/genblk1.router_type_%g",
       (node_no_port_from_network-2),"_netlist");
      $fdisplay(design_compiler_script_file_for_power_estimation,"report_power > ./reports/router_%g",pe_id,"_power_report.txt"); 
     end
    else $display("Can't write in design_compiler_script_file_for_power_estimation.txt file in output_files/scripts");    
   end
 end
 
 always@(posedge clk)
  begin
   if(full_rs) timer=0;
   else if(busy) timer++;
  end

always @(posedge clk)
 begin
  if(full_rs) manyclocks=0;
  else
   begin
    if(timer%600==0)
     manyclocks++;
   end
 end
  
always @(posedge manyclocks)
 begin
  if(busy)
   begin
    if(real_traffic_end_point!=1) total_number_of_received_packets=0; 
    for(int j=0;j<no_nodes;j++)
     begin
      pe_report_en=1;
      if(each_cluster_dimension==2 && no_clusters==1)
       begin
        pe_addr_called={1'b0,1'b0,y_addr[j],x_addr[j]};
        pe_addr_called_x_addr=x_addr[j];
        pe_addr_called_y_addr=y_addr[j];
        pe_addr_called_z_addr=0;
        pe_addr_called_c_addr=0;
       end
      else if(each_cluster_dimension==2 && no_clusters>1) 
       begin
        pe_addr_called={c_addr[j],1'b0,y_addr[j],x_addr[j]};
        pe_addr_called_x_addr=x_addr[j];
        pe_addr_called_y_addr=y_addr[j];
        pe_addr_called_z_addr=0;
        pe_addr_called_c_addr=c_addr[j];       
       end
      else if(each_cluster_dimension==3 && no_clusters==1)                                                    
       begin
        pe_addr_called={1'b0,z_addr[j],y_addr[j],x_addr[j]};
        pe_addr_called_x_addr=x_addr[j];
        pe_addr_called_y_addr=y_addr[j];
        pe_addr_called_z_addr=z_addr[j];
        pe_addr_called_c_addr=0;      
       end 
      else if(each_cluster_dimension==3 && no_clusters>1)
       begin
        pe_addr_called={c_addr[j],z_addr[j],y_addr[j],x_addr[j]};
        pe_addr_called_x_addr=x_addr[j];
        pe_addr_called_y_addr=y_addr[j];
        pe_addr_called_z_addr=z_addr[j];
        pe_addr_called_c_addr=c_addr[j];      
       end 
      #(cycle_period);                                    
      if(|averge_latency==1)
       begin
        total_number_of_received_packets= total_number_of_received_packets + no_packet_recieve;
       end
     end
     if(syn_or_real==1 && program_active==0 && no_packet_read>0 && total_number_of_received_packets>(0.9*no_packet_read))
       real_traffic_end_point=1;
   end    
 end
 
 task reading_map_file();
  integer map_file,map_file_counter,map_file_status;
  map_file= $fopen("./input_files/map_file.txt","r");
  if(map_file==0) $display("error in reading map_file!");
  else
   begin
    map_file_counter=0;
    while(!$feof(map_file))
     begin
      if(map_file_counter>no_nodes)
       begin
        $display("Number of trace nodes is bigger than network!");
        break;
       end
      if(each_cluster_dimension==2 && no_clusters==1)
                    map_file_status=$fscanf(map_file,"%d %d\n",y_addr[map_file_counter],x_addr[map_file_counter]);                               
      else if(each_cluster_dimension==2 && no_clusters>1)
                    map_file_status=$fscanf(map_file,"%d %d %d\n",c_addr[map_file_counter],
                                                               y_addr[map_file_counter],x_addr[map_file_counter]);
      else if(each_cluster_dimension==3 && no_clusters==1)
                    map_file_status=$fscanf(map_file,"%d %d %d\n",z_addr[map_file_counter],
                                                               y_addr[map_file_counter],x_addr[map_file_counter]);                  
      else if(each_cluster_dimension==3 && no_clusters>1) 
               map_file_status=$fscanf(map_file,"%d %d %d %d\n",c_addr[map_file_counter],z_addr[map_file_counter],
                                                               y_addr[map_file_counter],x_addr[map_file_counter]);
      map_file_counter= map_file_counter+1;
     end
   end
  $fclose(map_file);
 endtask
  
endmodule