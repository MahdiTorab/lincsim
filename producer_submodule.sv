`timescale 1ns/10ps
module producer_submodule(out_data,
                          out_sent_req,
                          out_new,
                          busy,
                          first_phit,
                          new_transaction,
                          syn_or_real,
                          syn_pattern,
                          dest_addr,
                          packet_length,
                          timer,
                          hotspot_addr,
                          en,
                          rs,
                          clk);

parameter each_cluster_dimension=2;
parameter cluster_topology=0;              //0:Mesh, 1:Torus
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
parameter [(addr_length-1):0] my_addr=200;

output reg [(phit_size-1):0] out_data;
output reg out_sent_req,out_new;
output reg busy;
output reg first_phit;
input new_transaction;
input syn_or_real;                           //0:synthetic, 1:real
input [2:0] syn_pattern;
input [(addr_length-1):0] dest_addr;
input [15:0] packet_length;
input [127:0] timer;
input [(addr_length-1):0] hotspot_addr;
input en,rs,clk;

wire [(phit_size-1):0] tmp_data_array [(flit_size-1):0];
wire transaction_finish,next_data;

reg syn_or_real_reg;
reg [2:0] syn_pattern_reg;
reg [(addr_length-1):0] dest_addr_reg;
reg [15:0] packet_length_reg;
reg flit_valid;
reg [15:0] flit_no;
reg last_flit;
reg [(flit_size*phit_size)-1:0] tmp_data;
reg traffic_to_local_or_not;
reg [(each_cluster_dimension-1):0] traffic_to_local_direction;
reg traffic_to_hotspot_or_not;
reg [15:0] phit_no;
reg prepare_start;
reg prepare_start_zero_hold;

genvar i;

generate if((flit_size*phit_size)-1>(2*addr_length)+addr_place_in_header) begin:tmp_data_remains_loop
  always@(posedge clk)
     if(flit_no==0 || flit_no==1) tmp_data[(flit_size*phit_size)-1:((2*addr_length)+addr_place_in_header)]=0;
 end
endgenerate

generate for(i=0;i<flit_size;i++) begin:tmp_data_array_loop
  assign tmp_data_array[i]= tmp_data[((i+1)*phit_size)-1:(i*phit_size)];
 end
endgenerate

assign next_data= flit_valid && en && ~last_flit && (phit_no==flit_size-1);
assign transaction_finish= flit_valid && en && last_flit && (phit_no==flit_size-1);

always@(posedge clk)
 begin
  if(rs) traffic_to_local_direction=0;
  else if(~syn_or_real_reg && syn_pattern_reg==3'b001)
        for(int j=0;j<each_cluster_dimension;j++)
         if ((($urandom()>>2)%100)<50) traffic_to_local_direction[j]= 0;
         else traffic_to_local_direction[j]= 1;
 end

always@(posedge clk)
 begin
  if(rs)
   begin
    traffic_to_local_or_not=0;
    traffic_to_hotspot_or_not=0;
   end
  else if(~syn_or_real_reg)
   begin
    if(syn_pattern_reg==3'b001)
     begin
      if((($urandom()>>2)%100)<percentage_of_locality) traffic_to_local_or_not=1;
      else traffic_to_local_or_not=0;
     end
    else if(syn_pattern_reg==3'b010)
     begin
      if((($urandom()>>2)%100)<percentage_of_hotspot) traffic_to_hotspot_or_not=1;
      else traffic_to_hotspot_or_not=0; 
     end
   end
 end

  always@(posedge clk) //senting data
   begin
    if(rs)
     begin
      out_sent_req=0;
      out_new=0;
      out_data=0;
      phit_no=0;
      first_phit=0;
     end
    else
     begin
      first_phit= (flit_no==0 && phit_no==0);
      if(flit_valid & en)
       begin
        if(phit_no<flit_size) out_data= tmp_data_array[phit_no];
        if(!(last_flit && phit_no==flit_size-1)) out_sent_req=1;
        else out_sent_req=0;
        if(phit_no<flit_size) out_new=1;
        else out_new=0; 
        if(next_data | transaction_finish) phit_no=0;
        else phit_no=phit_no+1;
       end
      else
       begin
        if(~flit_valid) out_sent_req=0;
        out_new=0;
        if(next_data | transaction_finish) phit_no=0;
       end
     end
   end
   
 always@(posedge clk)  //preparing data
  begin
   if(rs)
    begin
     flit_valid=0;
     flit_no=0;
     last_flit=0;
     tmp_data=0;
     prepare_start_zero_hold=0;
    end
   else
    begin
     if(busy & ~transaction_finish)
      begin
       if(syn_or_real_reg)         //real_traffic
        begin
         if(next_data | prepare_start)
          begin
           if(flit_no==0)
            begin
             tmp_data[(addr_length+addr_place_in_header-1):addr_place_in_header]= dest_addr_reg;
             tmp_data[((2*addr_length)+addr_place_in_header-1):(addr_length+addr_place_in_header)]= my_addr;
             flit_no=flit_no+1;
             flit_valid=1;
            end
           else if(flit_no==1)
            begin
             tmp_data=timer;
             if(flit_no==packet_length_reg-1) last_flit=1;
             else last_flit=0;
             flit_no=flit_no+1;
             flit_valid=1;
            end
           else
            begin
             tmp_data=$urandom();
             if(flit_no==packet_length_reg-1) last_flit=1;
             else last_flit=0;
             flit_no=flit_no+1;
             flit_valid=1;
            end
          end
        end
       else if(~syn_or_real_reg)   //synthetic_traffic
        begin
         if(next_data | prepare_start)
          begin
           if(flit_no==0)
            begin
              case(syn_pattern)    //call your new synthetic pattern traffic functions here      
               3'b000:  //uniform traffic
                tmp_data[(addr_length+addr_place_in_header-1):addr_place_in_header]=
                                                                              uniform_dest_addr_generator();
               3'b001:  //local traffic
                tmp_data[(addr_length+addr_place_in_header-1):addr_place_in_header]=
                                                                              local_dest_addr_generator();
               3'b010:  //hotspot traffic
                tmp_data[(addr_length+addr_place_in_header-1):addr_place_in_header]=
                                                                              hotspot_dest_addr_generator();
              endcase
             tmp_data[((2*addr_length)+addr_place_in_header-1):(addr_length+addr_place_in_header)]= my_addr;
             flit_no=flit_no+1;
             flit_valid=1;
            end
           else if(flit_no==1)
            begin
             tmp_data=timer;
             if(flit_no==packet_length_reg-1) last_flit=1;
             else last_flit=0;
             flit_no=flit_no+1;
             flit_valid=1;
            end
           else
            begin
             tmp_data=$urandom();
             if(flit_no==packet_length_reg-1) last_flit=1;
             else last_flit=0;
             flit_no=flit_no+1;
             flit_valid=1;
            end
          end
        end
      end
     else
      begin    //if(~(busy & ~transaction_finish))
       flit_valid=0;
       flit_no=0;
       last_flit=0;
       prepare_start_zero_hold=0;
      end
    end
  end

 always@(posedge clk)  //reading commands
  begin
   if(rs)
    begin
     busy=0;
     syn_or_real_reg=0;
     syn_pattern_reg=0;
     dest_addr_reg=0;
     packet_length_reg=0;
     prepare_start=0;
    end
   else
    begin
     if(new_transaction)
      begin
       busy=1;
       syn_or_real_reg=syn_or_real;
       packet_length_reg=packet_length;
       prepare_start=1;
       prepare_start_zero_hold=1;
       if(syn_or_real==0) syn_pattern_reg=syn_pattern;
       else dest_addr_reg=dest_addr;
      end
     else
      begin
       if(prepare_start_zero_hold)prepare_start=0;
       if(transaction_finish) busy=0;
      end
    end
  end
 
 
 //uniform_dest_addr_generator
 function [(addr_length-1):0] uniform_dest_addr_generator;
  
    begin
     uniform_dest_addr_generator[(cluster_first_dimension_no_addr_bits-1):0]=
                                                             ($urandom()>>2)%(cluster_first_dimension_up_bound+1);
     
     uniform_dest_addr_generator[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                     cluster_first_dimension_no_addr_bits]= ($urandom()>>2)%(cluster_second_dimension_up_bound+1);
                          
     uniform_dest_addr_generator[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                      cluster_first_dimension_no_addr_bits-1):
                         (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]=
                                (each_cluster_dimension>2)?(($urandom()>>2)%(cluster_third_dimension_up_bound+1)):0;
     uniform_dest_addr_generator[(no_cluster_no_addr_bits+cluster_third_dimension_no_addr_bits+
                          cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                     (cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                          cluster_first_dimension_no_addr_bits)]=
                                           (no_clusters>1)?(($urandom()>>2)%(cluster_third_dimension_up_bound+1)):0;
    end
 endfunction

 //hotspot_dest_addr_generator
 function [(addr_length-1):0] hotspot_dest_addr_generator; 
  if(~traffic_to_hotspot_or_not) hotspot_dest_addr_generator= uniform_dest_addr_generator();
  else hotspot_dest_addr_generator= hotspot_addr;
 endfunction

 //local_dest_addr_generator
 function [(addr_length-1):0] local_dest_addr_generator;
  reg [15:0] tmp_local_traffic_domain;

   if(~traffic_to_local_or_not) local_dest_addr_generator=uniform_dest_addr_generator();
   else
    begin
     tmp_local_traffic_domain=(($urandom()>>2)%local_traffic_domain)+1;
     case(cluster_topology)
      0: //Mesh
       local_dest_addr_generator= mesh_dest_finder(my_addr,tmp_local_traffic_domain);
      1: //Torus
       local_dest_addr_generator= torus_dest_finder(my_addr,tmp_local_traffic_domain);
      
     endcase
    end
 endfunction
 
 
 //Mesh_dest_finder
 function [(addr_length-1):0] mesh_dest_finder;
  input [(addr_length-1):0] addr;
  input [15:0] path_size;
   reg [(addr_length-1):0] tmp_mesh_dest_finder;
   
   tmp_mesh_dest_finder= mesh_neighbour_finder(addr);
   path_size=path_size-1;
   if(path_size>0)
    mesh_dest_finder= mesh_dest_finder(tmp_mesh_dest_finder,path_size);
   else
    mesh_dest_finder= tmp_mesh_dest_finder; 
 endfunction

 //Torus_dest_finder
 function [(addr_length-1):0] torus_dest_finder;
  input [(addr_length-1):0] addr;
  input [15:0] path_size;
   reg [(addr_length-1):0] tmp_torus_dest_finder;
   
   tmp_torus_dest_finder= torus_neighbour_finder(addr);
   path_size=path_size-1;
   if(path_size>0)
    torus_dest_finder= torus_dest_finder(tmp_torus_dest_finder,path_size);
   else
    torus_dest_finder= tmp_torus_dest_finder; 
    
 endfunction
 
 //Mesh_neighbour_finder
 function [(addr_length-1):0] mesh_neighbour_finder;
  input [(addr_length-1):0] addr;   
   
  reg [2:0] dibs;
  
   mesh_neighbour_finder=addr;
   case(each_cluster_dimension)     
    2:
     begin
      dibs=($urandom()>>2)%2;
       case(dibs)
        0:
         begin
          if(~traffic_to_local_direction[0])
           begin
            if(mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]<cluster_first_dimension_up_bound)
             mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]+1;
            else
             mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]-1;                  
           end
          else
           begin
            if(mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]>0)
             mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]-1; 
            else
             mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]+1;
           end          
         end
         
        1:
         begin
          if(~traffic_to_local_direction[1])
           begin
            if(mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                              cluster_first_dimension_no_addr_bits]<cluster_second_dimension_up_bound)
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]+1;
            else
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]-1;
           end
          else
           begin
            if(mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                              cluster_first_dimension_no_addr_bits]>0)
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]-1;
            else
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]+1; 
           end
         end 
       endcase   
     end
    
    3:
     begin
      dibs=($urandom()>>2)%3;
       case(dibs)
        0:
         begin
          if(~traffic_to_local_direction[0])
           begin
            if(mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]<cluster_first_dimension_up_bound)
             mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]+1;
            else
             mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]-1;                   
           end
          else
           begin
            if(mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]>0)
             mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]-1; 
            else
             mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     mesh_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]+1;
           end          
         end
         
        1:
         begin
          if(~traffic_to_local_direction[1])
           begin
            if(mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                              cluster_first_dimension_no_addr_bits]<cluster_second_dimension_up_bound)
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]+1;
            else
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]-1;
           end
          else
           begin
            if(mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                              cluster_first_dimension_no_addr_bits]>0)
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]-1;
            else
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             mesh_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]+1; 
           end
         end 
        2:
         begin
          if(~traffic_to_local_direction[2])
           begin
            if(mesh_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
              (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]<cluster_third_dimension_up_bound)
               mesh_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]=
               mesh_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]+1;                    
            else
               mesh_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]=
               mesh_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]-1;  
           end
          else
           begin
            if(mesh_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]>0)
             mesh_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]=
             mesh_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                      (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]-1;
            else
             mesh_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]=
             mesh_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                      (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]+1;
           end           
         end
       endcase 
     end
   endcase
 endfunction
 
 
 //Torus_neighbour_finder
 function [(addr_length-1):0] torus_neighbour_finder;
  input [(addr_length-1):0] addr;   
   
  reg [2:0] dibs;
  
   torus_neighbour_finder=addr;
   case(each_cluster_dimension)     
    2:
     begin
      dibs=($urandom()>>2)%2;
       case(dibs)
        0:
         begin
          if(~traffic_to_local_direction[0])
           begin
            if(torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]<cluster_first_dimension_up_bound)
             torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]+1;
            else
             torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=0;                   
           end
          else
           begin
            if(torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]>0)
             torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                    torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]-1; 
            else
             torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=cluster_first_dimension_up_bound;
           end          
         end
         
        1:
         begin
          if(~traffic_to_local_direction[1])
           begin
            if(torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                              cluster_first_dimension_no_addr_bits]<cluster_second_dimension_up_bound)
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]+1;
            else
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=0;
           end
          else
           begin
            if(torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                              cluster_first_dimension_no_addr_bits]>0)
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]-1;
            else
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
                                                                       cluster_second_dimension_up_bound; 
           end
         end 
       endcase   
     end
    
    3:
     begin
      dibs=($urandom()>>2)%3;
       case(dibs)
        0:
         begin
          if(~traffic_to_local_direction[0])
           begin
            if(torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]<cluster_first_dimension_up_bound)
             torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]+1;
            else
             torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=0;                   
           end
          else
           begin
            if(torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]>0)
             torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=
                                     torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]-1; 
            else
             torus_neighbour_finder[(cluster_first_dimension_no_addr_bits-1):0]=cluster_first_dimension_up_bound;
           end          
         end
         
        1:
         begin
          if(~traffic_to_local_direction[1])
           begin
            if(torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                              cluster_first_dimension_no_addr_bits]<cluster_second_dimension_up_bound)
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]+1;
            else
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=0;
           end
          else
           begin
            if(torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                              cluster_first_dimension_no_addr_bits]>0)
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                      cluster_first_dimension_no_addr_bits]-1;
            else
             torus_neighbour_finder[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                       cluster_first_dimension_no_addr_bits]=
                                                                       cluster_second_dimension_up_bound; 
           end
         end 
        2:
         begin
          if(~traffic_to_local_direction[2])
           begin
            if(torus_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
              (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]<cluster_third_dimension_up_bound)
               torus_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]=
               torus_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]+1;                    
            else
               torus_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]=0;  
           end
          else
           begin
            if(torus_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]>0)
             torus_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]=
             torus_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                      (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]-1;
            else
             torus_neighbour_finder[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+
                                                       cluster_first_dimension_no_addr_bits-1):
                                (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)]=
                                                                        cluster_third_dimension_up_bound;
           end           
         end
       endcase 
     end
   endcase
 endfunction
 
endmodule