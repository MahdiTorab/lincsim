`timescale 1ns/10ps
module inport_in_interface_rightside(outdata,
                                     sent_req_vec,
                                     new_vec,
                                     want,
                                     all_done,
                                     indata,
                                     ready_vec,
                                     calls,
                                     outport_vec,
                                     state,
                                     head,
                                     tail,
                                     empty,
                                     reset,
                                     clk);

parameter no_outport=6;
parameter floorplusone_log2_no_outport=3;
parameter flit_size=1;                //In number of phits
parameter floorplusone_log2_flit_size=1;
parameter phit_size=16;               //In number of bits

output [(no_outport*phit_size)-1:0] outdata;
output [(no_outport-1):0] sent_req_vec;
output [(no_outport-1):0] new_vec;
output want;
output reg all_done;
input [(flit_size*phit_size)-1:0] indata;
input [(no_outport-1):0] ready_vec,calls,outport_vec;
input [1:0] state;
input head,tail,empty,reset,clk;

wire all_complete,valid;
wire [(no_outport-1):0] finish,finished,complete,my_ready_vec,tmp_finish;
wire [(floorplusone_log2_flit_size-1):0] counters [(no_outport-1):0];
wire [(floorplusone_log2_flit_size-1):0] remains [(no_outport-1):0];
wire [(phit_size-1):0] indatas [(flit_size-1):0];
wire [(phit_size-1):0] outdatas [(no_outport-1):0];

reg tmp_valid,sent_req_time;
reg [(no_outport-1):0] my_ready_vec_reg;


genvar i;

generate for(i=0;i<no_outport;i=i+1) begin:counters_loop
  inport_in_interface_rightside_counter #(flit_size,
                                          floorplusone_log2_flit_size)
  inport_in_interface_rightside_counter(counters[i],
                                        (my_ready_vec[i]&~finished[i]&valid),
                                        reset,
                                        want,
                                        clk);
 end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin:remains_loop
  assign remains[i]=flit_size-counters[i];
 end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin:finished_loop
  assign finished[i]=((~|remains[i])&outport_vec[i])|~outport_vec[i];
 end
endgenerate

generate if(flit_size>1) begin:tmp_finish_if_outloop
 for(i=0;i<no_outport;i=i+1) begin:tmp_finish_if_inloop
   assign tmp_finish[i]=~|remains[i][(floorplusone_log2_flit_size-1):1];
  end
 end
         else begin:tmp_finish_else_outloop
 for(i=0;i<no_outport;i=i+1) begin:tmp_finish_else_inloop
   assign tmp_finish[i]=1'b1;
  end
 end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin:finish_loop
  assign finish[i]=(remains[i][0]&tmp_finish[i])&(outport_vec[i]&my_ready_vec_reg[i]);
 end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin:complete_loop
  assign complete[i]=finish[i]|finished[i];
 end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin:outdata_loop
  assign outdata[((i+1)*phit_size)-1:(i*phit_size)]=outdatas[i];
 end
endgenerate

generate for(i=0;i<flit_size;i=i+1) begin:indatas_loop
  assign indatas[i]=indata[((i+1)*phit_size)-1:(i*phit_size)];
 end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin:outdatas_loop
  assign  outdatas[i]={phit_size{my_ready_vec_reg[i]}} & {phit_size{valid}} & {phit_size{~finished[i]}} & indatas[counters[i]];
 end
endgenerate

assign all_complete= &complete;
assign my_ready_vec= ready_vec&calls;
assign want= all_complete&~empty&|my_ready_vec;
assign sent_req_vec= {no_outport{(sent_req_time)}} & outport_vec & ~({no_outport{tail}}&(finish|finished)) & ~{no_outport{all_done}};
assign valid= (tmp_valid|want) & ~&finished;
assign new_vec= my_ready_vec_reg & {no_outport{valid}}&~finished;

always@(posedge clk)
 begin
  if(reset)
   begin
    tmp_valid=0;
    all_done=0;
    my_ready_vec_reg=0;
    sent_req_time=0;
   end
  else if (state==2'b11)
   begin
    my_ready_vec_reg=my_ready_vec;
    all_done= all_complete&tail;
    sent_req_time= (|my_ready_vec) | sent_req_time;
    if(want) tmp_valid=1;
   end
 end
 
endmodule