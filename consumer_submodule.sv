`timescale 1ns/10ps
module consumer_submodule(source_addr,
                          packet_length,
                          time_of_flight,
                          valid,
                          indata,
                          in_sent_req,
                          in_new,
                          timer,
                          en,
                          rs,
                          clk);

parameter flit_size=1;
parameter floorplusone_log2_flit_size=1;
parameter phit_size=16;
parameter addr_length=8;
parameter addr_place_in_header=0;

output [(addr_length-1):0] source_addr;
output [15:0] packet_length;
output [31:0] time_of_flight;
output valid;
input [(phit_size-1):0] indata;
input in_sent_req,in_new;
input [127:0] timer;
input en,rs,clk;

wire phit_rec_valid;
wire [(flit_size*phit_size)-1:0] out_data_from_phit_rec;

reg [127:0] land_time;
reg [(addr_length-1):0] source_addr_reg;
reg [15:0] packet_length_reg;
reg [31:0] time_of_flight_reg;

defparam phit_rec.flit_size=flit_size;
defparam phit_rec.floorplusone_log2_flit_size=floorplusone_log2_flit_size;
defparam phit_rec.phit_size=phit_size;
phit_rec phit_rec(out_data_from_phit_rec,phit_rec_valid,indata,in_new,en,rs,clk);

assign source_addr= {addr_length{en}}&source_addr_reg;
assign packet_length= ({16{valid}}&(packet_length_reg+1));       
assign time_of_flight= ({32{(packet_length>1)&en}}&time_of_flight_reg) |
                    ({32{(packet_length==1)&en&~in_sent_req&phit_rec_valid}}&out_data_from_phit_rec);                     
assign valid= en & ~in_sent_req & in_new;

always@(posedge clk)
 begin
  if((en & ~in_sent_req & in_new) | rs)
   begin
    source_addr_reg=0;
    packet_length_reg=0;
    time_of_flight_reg=0;
    land_time=0;
   end
  else if(en & phit_rec_valid)
   begin
    if(packet_length_reg==0)
     begin
      source_addr_reg= 
                 out_data_from_phit_rec[((2*addr_length)+addr_place_in_header)-1:(addr_length+addr_place_in_header)];
      land_time=timer;
     end
    else if(packet_length_reg==1) time_of_flight_reg= (land_time-out_data_from_phit_rec);
    packet_length_reg= packet_length_reg+1;
   end
 end
endmodule