`timescale 1ns/10ps
module producer_and_consumer(out_data,
                             out_sent_req,
                             out_new,
                             in_ready,
                             out_vc_no,
           
                             in_data,
                             in_sent_req,
                             in_new,
                             out_ready,
                             in_vc_no,

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
                             pe_id,
                             
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
parameter local_traffic_domain=1;
parameter percentage_of_locality=50;
parameter percentage_of_hotspot=50;
parameter flit_size=1;
parameter floorplusone_log2_flit_size=1;
parameter phit_size=16;
parameter addr_place_in_header=0;
parameter addr_length=8;
parameter injection_rate=0.01;
parameter [(addr_length-1):0] my_addr=200;
parameter no_vc=8;
parameter floorplusone_log2_no_vc=4;
parameter no_nodes=10;

output [(phit_size-1):0] out_data;
output out_sent_req;
output out_new;
input in_ready;
output reg [(floorplusone_log2_no_vc-1):0] out_vc_no;
           
input [(phit_size-1):0] in_data;
input in_sent_req;
input in_new;
output out_ready;
input [(floorplusone_log2_no_vc-1):0] in_vc_no;

output [31:0] average_time_of_flies_report;
output [31:0] no_packet_recieve_report;
output produce_mem_busy;
input active;
input syn_or_real;        //0:synthetic , 1:real
input [2:0] syn_pattern;
input program_active;
input [(addr_length-1):0] source_addr_from_manager;
input [(addr_length-1):0] dest_addr;
input [(addr_length-1):0] hotspot_addr;
input integer inject_time;
input integer packet_length;
input report_enable;
input integer log_file,pe_id;                         
input report_reset,full_reset,clk;                           

wire enable_to_producer;
wire [(addr_length-1):0] source_addr_vec [(no_vc-1):0];
wire [(no_vc-1):0] tmp_source_addr [(addr_length-1):0];
wire [(addr_length-1):0] source_addr;
wire [15:0] consumers_packet_length_vec [(no_vc-1):0];
wire [(no_vc-1):0] tmp_consumers_packet_length [15:0];
wire [15:0] consumers_packet_length;
wire [31:0] time_of_fly_vec [(no_vc-1):0];
wire [(no_vc-1):0] tmp_time_of_fly [31:0];
wire [31:0] time_of_fly;
wire [(no_vc-1):0] rec_packet_valid_vec;
wire rec_packet_valid;
wire [(no_vc-1):0] en_vec;
wire busy_from_producer;
wire first_phit_from_producer;

reg [127:0] timer;
reg [127:0] timer_to_producer;
reg [(addr_length-1):0] inject_dest_addr_mem [];
reg [255:0] total_time_of_flies;
reg [15:0] packet_length_to_producer;
reg new_transaction_to_producer;
reg [(addr_length-1):0] dest_addr_to_producer;
reg [(no_vc-1):0] en_vec_reg,en_vec_reg_reg;
reg [127:0] syn_timer_queue [];

bit coin,vc_changed;
integer injection_time_mem [];
integer packet_length_mem [];
integer no_packet_recieve;
integer average_time_of_flies;
int phit_due,packet_due,syn_timer_queue_head,syn_timer_queue_tail,mem_write_counter,mem_read_counter;
 
genvar i,j;

defparam producer_submodule.each_cluster_dimension= each_cluster_dimension;
defparam producer_submodule.cluster_topology= cluster_topology;
defparam producer_submodule.cluster_first_dimension_up_bound= cluster_first_dimension_up_bound;
defparam producer_submodule.cluster_second_dimension_up_bound= cluster_second_dimension_up_bound;
defparam producer_submodule.cluster_third_dimension_up_bound= cluster_third_dimension_up_bound;
defparam producer_submodule.no_clusters= no_clusters;
defparam producer_submodule.cluster_first_dimension_no_addr_bits=cluster_first_dimension_no_addr_bits;
defparam producer_submodule.cluster_second_dimension_no_addr_bits=cluster_second_dimension_no_addr_bits;
defparam producer_submodule.cluster_third_dimension_no_addr_bits=cluster_third_dimension_no_addr_bits;
defparam producer_submodule.no_cluster_no_addr_bits=no_cluster_no_addr_bits;
defparam producer_submodule.local_traffic_domain= local_traffic_domain;
defparam producer_submodule.percentage_of_locality= percentage_of_locality;
defparam producer_submodule.percentage_of_hotspot= percentage_of_hotspot;
defparam producer_submodule.flit_size= flit_size;
defparam producer_submodule.floorplusone_log2_flit_size= floorplusone_log2_flit_size;
defparam producer_submodule.phit_size= phit_size;
defparam producer_submodule.addr_place_in_header= addr_place_in_header;
defparam producer_submodule.addr_length= addr_length;
defparam producer_submodule.my_addr= my_addr;
producer_submodule producer_submodule(out_data,
                                      out_sent_req,
                                      out_new,
                                      busy_from_producer,
                                      first_phit_from_producer,
                                      new_transaction_to_producer,
                                      syn_or_real,
                                      syn_pattern,
                                      dest_addr_to_producer,
                                      packet_length_to_producer,
                                      timer_to_producer,
                                      hotspot_addr,
                                      enable_to_producer,
                                      full_reset,
                                      clk);

generate for(i=0;i<no_vc;i++) begin:tmp_source_addr_outloop
          for(j=0;j<addr_length;j++) begin:tmp_source_addr_inloop
           assign tmp_source_addr[j][i]= source_addr_vec[i][j];
          end
         end
endgenerate  

generate for(i=0;i<addr_length;i++) begin:source_addr_loop
          assign source_addr[i]= |tmp_source_addr[i];
         end
endgenerate

generate for(i=0;i<no_vc;i++) begin:tmp_consumers_packet_length_outloop
          for(j=0;j<16;j++) begin:tmp_consumers_packet_length_inloop
           assign tmp_consumers_packet_length[j][i]= consumers_packet_length_vec[i][j];
          end
         end
endgenerate  

generate for(i=0;i<16;i++) begin:consumers_packet_length_loop
          assign consumers_packet_length[i]= |tmp_consumers_packet_length[i];
         end
endgenerate   

generate for(i=0;i<no_vc;i++) begin:tmp_time_of_fly_outloop
          for(j=0;j<32;j++) begin:tmp_time_of_fly_inloop
           assign tmp_time_of_fly[j][i]= time_of_fly_vec[i][j];
          end
         end
endgenerate  

generate for(i=0;i<32;i++) begin:time_of_fly_loop
          assign time_of_fly[i]= |tmp_time_of_fly[i];
         end
endgenerate       

defparam decoder.no_vc=no_vc;
defparam decoder.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
decoder decoder(en_vec,in_vc_no);
      
generate for(i=0;i<no_vc;i++) begin:consumer_submodule_loop
 defparam consumer_submodule.flit_size=flit_size;
 defparam consumer_submodule.floorplusone_log2_flit_size=floorplusone_log2_flit_size;
 defparam consumer_submodule.phit_size=phit_size;
 defparam consumer_submodule.addr_length=addr_length;
 defparam consumer_submodule.addr_place_in_header=addr_place_in_header; 
 consumer_submodule consumer_submodule(source_addr_vec[i],
                                       consumers_packet_length_vec[i],
                                       time_of_fly_vec[i],
                                       rec_packet_valid_vec[i],
                                       in_data,
                                       in_sent_req,
                                       in_new,
                                       timer,
                                       en_vec_reg_reg[i],
                                       full_reset,
                                       clk);
 end
endgenerate                                       

generate for(i=0;i<32;i++) begin: no_packet_recieve_report_loop
  bufif1 no_packet(no_packet_recieve_report[i],no_packet_recieve[i],(report_enable && source_addr_from_manager==my_addr));
 end
endgenerate

generate for(i=0;i<32;i++) begin: average_time_of_flies_report_loop
  bufif1 average_time(average_time_of_flies_report[i],average_time_of_flies[i],
                                                                    (report_enable && source_addr_from_manager==my_addr));
 end
endgenerate

assign rec_packet_valid=|rec_packet_valid_vec;
assign out_ready=1;
assign produce_mem_busy= |(mem_read_counter^mem_write_counter) | new_transaction_to_producer | busy_from_producer;
assign enable_to_producer= busy_from_producer & active & in_ready & (syn_or_real?1'b1:(packet_due>0)) & ~vc_changed;

always@(posedge clk)
 begin
  if(full_reset) timer=0;
  else if(active) timer=timer+1;
 end

always@(posedge clk) coin=(($urandom()>>2)%100000)<(injection_rate*100000);
always@(negedge busy_from_producer) if(~full_reset & ~syn_or_real) packet_due--;

always@(posedge clk)
 begin
  if(full_reset)
   begin
    out_vc_no=0;
    vc_changed=0;
    phit_due=0;
    packet_due=0;
    syn_timer_queue_head=0;
    syn_timer_queue_tail=0;
   end
  else
   begin
    if(busy_from_producer & active & ~in_ready & first_phit_from_producer & (syn_or_real?1'b1:(packet_due>0)))
     begin
      if(vc_changed) vc_changed=0;
      else
       begin
        out_vc_no=(out_vc_no+1)%no_vc;
        vc_changed=1;
       end
     end
    else if(vc_changed)vc_changed=0;
    if((phit_due==packet_length*flit_size-1) && (active & coin & ~(busy_from_producer & in_ready)) && ~syn_or_real)
     begin
      packet_due++;
      syn_timer_queue = new[syn_timer_queue_tail+1](syn_timer_queue);
      syn_timer_queue[syn_timer_queue_tail]=timer;
      syn_timer_queue_tail++;
      phit_due=0;
     end
    else if(active & ~syn_or_real & coin & ~(busy_from_producer & in_ready)) phit_due++;
   end
 end

always@(posedge clk)
 begin
   if(full_reset)
    begin
     mem_write_counter=0; 
    end
   else if((syn_or_real==1) && (source_addr_from_manager==my_addr) && (packet_length!=0) && program_active)
     begin
      inject_dest_addr_mem= new[mem_write_counter+1](inject_dest_addr_mem);
      injection_time_mem= new[mem_write_counter+1](injection_time_mem);
      packet_length_mem= new[mem_write_counter+1](packet_length_mem);
      inject_dest_addr_mem[mem_write_counter]=dest_addr;
      injection_time_mem[mem_write_counter]=inject_time;
      packet_length_mem[mem_write_counter]=packet_length;
      mem_write_counter=mem_write_counter+1;
     end
 end
 
 always@(posedge clk)
  begin
   if(full_reset)
    begin
     new_transaction_to_producer=0;
     dest_addr_to_producer=0;
     packet_length_to_producer=0;
     mem_read_counter=0;
    end
   else
    begin
     if(~busy_from_producer & ~program_active)
      begin
       if(syn_or_real==0)
        begin
         packet_length_to_producer=packet_length;
         if(new_transaction_to_producer) new_transaction_to_producer=0;
         else if(active && (packet_due>0))
          begin
           new_transaction_to_producer=1; 
           timer_to_producer=syn_timer_queue[syn_timer_queue_head];
           syn_timer_queue_head++;
          end
        end
       else
        begin
         if(timer>=injection_time_mem[mem_read_counter])
          begin
           dest_addr_to_producer= inject_dest_addr_mem[mem_read_counter];
           packet_length_to_producer= packet_length_mem [mem_read_counter];
           timer_to_producer= injection_time_mem [mem_read_counter];   
           if(new_transaction_to_producer) new_transaction_to_producer=0;
           else
            begin
             new_transaction_to_producer=1; 
             mem_read_counter= mem_read_counter+1;
            end
          end
         else new_transaction_to_producer=0;
        end
      end
     else new_transaction_to_producer=0;
    end
  end     

 always@(posedge clk)//consumer
  begin
   if(full_reset|report_reset)
    begin
     average_time_of_flies=0;
     total_time_of_flies=0;
     no_packet_recieve=0;
    end
   else if(rec_packet_valid)
    begin
     total_time_of_flies=total_time_of_flies+time_of_fly;
     no_packet_recieve=no_packet_recieve+1;
     average_time_of_flies=total_time_of_flies/no_packet_recieve;
     $fdisplay(log_file,"sent_module_addr:%b",source_addr," ,rec_module_addr:%b",my_addr," ,packet_length:%g",consumers_packet_length-1,
                                                                                   " ,latency:%g",time_of_fly," ,recieve time:%g",timer);
    end
 end
  
 always@(negedge report_enable)
  begin
   if(source_addr_from_manager==my_addr && timer>0)
    begin
     $fdisplay(log_file,"****\n","Node: %g",pe_id," ,no_packet_recieve= %g",no_packet_recieve,
                                                                                " ,average_latency= %g",average_time_of_flies); 
    end
  end
  
 always@(posedge clk)
  begin
   en_vec_reg_reg= en_vec_reg;
   en_vec_reg= en_vec;
  end
endmodule