`timescale 1ns/10ps
module routing_computation(outport_vec,
                           allow_vcs,
                           rc_valid,
                           header,
                           rc_req,
                           busies,
                           my_addr,
                           node_links_directions,
                           have_fork_port,
                           have_express_port,
                           clk);
  
parameter each_cluster_dimension=2;
parameter cluster_topology=0; //0:Mesh, 1:Torus
parameter cluster_first_dimension_up_bound=1;
parameter cluster_second_dimension_up_bound=1;
parameter cluster_third_dimension_up_bound=1;
parameter no_clusters=5;
parameter cluster_first_dimension_no_addr_bits=1;
parameter cluster_second_dimension_no_addr_bits=1;
parameter cluster_third_dimension_no_addr_bits=1;
parameter no_cluster_no_addr_bits=1;
parameter no_outport=6;
parameter floorplusone_log2_no_outport=2;
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;
parameter flit_size=1;                //In number of phits
parameter phit_size=16;               //In number of bits
parameter addr_length=10;
parameter addr_place_in_header=0;     //bit number in header that address start
parameter portid=0;

output [(no_outport-1):0] outport_vec;
output reg [(no_vc-1):0] allow_vcs;
output reg rc_valid;
input [(flit_size*phit_size)-1:0] header;
input rc_req;
input [(no_outport*floorplusone_log2_no_vc)-1:0] busies;
input [(addr_length-1):0] my_addr;
input [31:0] node_links_directions;
input have_fork_port,have_express_port;
input clk;

wire [(floorplusone_log2_no_vc-1):0] busy [(no_outport-1):0];
wire [3:0] links_directions [8:0];
wire [(no_cluster_no_addr_bits-1):0] des_c,cur_c;
wire [(cluster_third_dimension_no_addr_bits-1):0] des_z,cur_z;
wire [(cluster_second_dimension_no_addr_bits-1):0] des_y,cur_y;
wire [(cluster_first_dimension_no_addr_bits-1):0] des_x,cur_x;
reg [(floorplusone_log2_no_outport-1):0] outport;

genvar i;

defparam routing_computation_decoder.no_vc= no_outport;
defparam routing_computation_decoder.floorplusone_log2_no_vc=floorplusone_log2_no_outport;
decoder routing_computation_decoder(outport_vec,outport);
  
generate
 for(i=0;i<no_outport;i=i+1) begin: busy_loop
  assign busy[i]=busies[((i+1)*floorplusone_log2_no_vc)-1:(i*floorplusone_log2_no_vc)];
 end
endgenerate

assign links_directions[0]=0;
generate
 for(i=0;i<8;i=i+1) begin: links_directions_loop
  assign links_directions[i+1]= node_links_directions[((i+1)*4)-1:(i*4)];
 end
endgenerate

assign des_c=header[(addr_place_in_header+addr_length-1):(addr_place_in_header+addr_length-no_cluster_no_addr_bits)];
assign des_z=header[(addr_place_in_header+cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                  (addr_place_in_header+cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)];
assign des_y=header[(addr_place_in_header+cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                        (addr_place_in_header+cluster_first_dimension_no_addr_bits)];
assign des_x=header[(addr_place_in_header+cluster_first_dimension_no_addr_bits-1):addr_place_in_header];
assign cur_c=my_addr[(addr_length-1):(addr_length-no_cluster_no_addr_bits)];
assign cur_z=my_addr[(cluster_third_dimension_no_addr_bits+cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                       (cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits)];
assign cur_y=my_addr[(cluster_second_dimension_no_addr_bits+cluster_first_dimension_no_addr_bits-1):
                                                                               cluster_first_dimension_no_addr_bits];
assign cur_x=my_addr[(cluster_first_dimension_no_addr_bits-1):0]; 

//You can determine your routing here (for adaptive routing use busy signals that show every outport VCs congestion)

always@(posedge clk)
 begin
  if(rc_req)
   begin
    allow_vcs={no_vc{1'b1}};
    rc_valid=1;
    rc_valid=1;
    if(des_x<cur_x) outport=links_directions[2];
    else if(des_x>cur_x) outport=links_directions[1];
    else if((des_x==cur_x) && (des_y<cur_y)) outport=links_directions[4];
    else if((des_x==cur_x) && (des_y>cur_y)) outport=links_directions[3];
    else if((des_x==cur_x) && (des_y==cur_y) && (des_z<cur_z)) outport=links_directions[6];
    else if((des_x==cur_x) && (des_y==cur_y) && (des_z>cur_z)) outport=links_directions[5];                                                                                         
    else outport=links_directions[0]; 
   end
  else rc_valid=0;
 end
 
endmodule


