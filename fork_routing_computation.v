`timescale 1ns/10ps
module fork_routing_computation(outport_vec,
                                allow_vcs,
                                rc_valid,
                                header,
                                rc_req,
                                busies,
                                my_addr,
                                rs,
                                clk);
parameter no_outport=6;
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;
parameter flit_size=1;                //In number of phits
parameter phit_size=16;               //In number of bits
parameter addr_length=10;

output reg [(no_outport-1):0] outport_vec;
output reg [(no_vc-1):0] allow_vcs;
output reg rc_valid;
input [(flit_size*phit_size)-1:0] header;
input rc_req;
input [(no_outport*floorplusone_log2_no_vc)-1:0] busies;
input [(addr_length-1):0] my_addr;
input rs,clk;

wire [(floorplusone_log2_no_vc-1):0] busy [(no_outport-1):0];
reg [(no_outport-1):0] out_link_counter;
reg tmp;

genvar i;

generate
for(i=0;i<no_outport;i=i+1) begin: busy_loop
  assign busy[i]=busies[((i+1)*floorplusone_log2_no_vc)-1:(i*floorplusone_log2_no_vc)];
end
endgenerate

always@(posedge clk)
 begin
  if(rs)
   begin
    tmp=0; 
    out_link_counter={{(no_outport-1){1'b0}},1'b1};
    outport_vec= 0;
    allow_vcs={no_vc{1'b1}};
    rc_valid=0;
   end
  else
   begin 
    if(rc_req)
     begin
      if(tmp)
       begin
        if(out_link_counter!={1'b1,{(no_outport-1){1'b0}}})
         begin
          tmp=0;
          outport_vec= out_link_counter;
          out_link_counter= out_link_counter<<1;
          allow_vcs={no_vc{1'b1}};
          rc_valid=1;
         end
        else
         begin
          tmp=0;
          outport_vec= out_link_counter;
          out_link_counter={{(no_outport-1){1'b0}},1'b1};
          allow_vcs={no_vc{1'b1}};
          rc_valid=1;
         end
       end
      else
       begin
        tmp=1;
        outport_vec= out_link_counter;
        out_link_counter= out_link_counter;
        allow_vcs={no_vc{1'b1}};
        rc_valid=1; 
       end
     end
    else
     begin
      out_link_counter= out_link_counter;
      tmp=tmp;
      outport_vec= outport_vec;
      allow_vcs=allow_vcs;
      rc_valid=0;
     end
   end
 end

endmodule