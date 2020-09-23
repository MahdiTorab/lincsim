`timescale 1ns/10ps
module router(outdata_vec,
              outsent_req_vec,
              outnew_vec,
              inready_vec,
              outvc_no_vec,
           
              indata_vec,
              insent_req_vec,
              innew_vec,
              outready_vec,
              invc_no_vec,
              
              busy,
              my_addr,
              node_links_directions,
              have_fork_port,
              have_express_port,
              reset,
              clk);

parameter each_cluster_dimension=3;
parameter cluster_topology=0;         //0:Mesh, 1:Torus
parameter cluster_first_dimension_up_bound=1;
parameter cluster_second_dimension_up_bound=1;
parameter cluster_third_dimension_up_bound=1;
parameter no_clusters=1;
parameter cluster_first_dimension_no_addr_bits=1;
parameter cluster_second_dimension_no_addr_bits=1;
parameter cluster_third_dimension_no_addr_bits=1;
parameter no_cluster_no_addr_bits=1;
parameter no_outport=7;
parameter floorplusone_log2_no_outport=3;
parameter no_inport=7;
parameter floorplusone_log2_no_inport=3;
parameter no_vc=4;
parameter floorplusone_log2_no_vc=3;
parameter flit_size=1;                //In number of phits
parameter floorplusone_log2_flit_size=1;
parameter phit_size=32;               //In number of bits
parameter buf_size=4;                 //In number of flits
parameter floorplusone_log2_buf_size=3;
parameter switching_method=3;         //1 to Store&forward, 2 to VCT, 3 to Wormhole switching
parameter addr_length=4;              //In number of bits
parameter addr_place_in_header=0;     //bit number in header that address start

output [(no_outport*phit_size)-1:0] outdata_vec;
output [(no_outport-1):0] outsent_req_vec,outnew_vec;
input [(no_outport-1):0] inready_vec;
output [(no_outport*floorplusone_log2_no_vc)-1:0] outvc_no_vec;

input [(no_inport*phit_size)-1:0] indata_vec;
input [(no_inport-1):0] insent_req_vec,innew_vec;
output [(no_inport-1):0] outready_vec;
input [(no_inport*floorplusone_log2_no_vc)-1:0] invc_no_vec;

output busy;
input [(addr_length-1):0] my_addr;
input [31:0] node_links_directions;
input have_fork_port,have_express_port;
input reset,clk;

wire [(no_outport*floorplusone_log2_no_vc)-1:0] called_invc_no;
wire [(no_outport-1):0] active_vecs_to_inports [(no_inport-1):0];
wire [(no_inport-1):0] called_inport_vecs_from_outports [(no_outport-1):0];
wire [(no_outport*floorplusone_log2_no_vc)-1:0] invc_req_nos_from_inports [(no_inport-1):0];
wire [(no_inport*floorplusone_log2_no_vc)-1:0] invc_req_nos_to_outports [(no_outport-1):0];
wire [(no_inport-1):0] ready_vec_from_outports [(no_outport-1):0];
wire [(no_outport-1):0] ready_vec_to_inports [(no_inport-1):0];
wire [(no_inport-1):0] oks_vec_from_outports [(no_outport-1):0];
wire [(no_outport-1):0] oks_vec_to_inports [(no_inport-1):0];
wire [(no_outport*no_vc)-1:0] allow_vcs_vec_from_inport [(no_inport-1):0];
wire [(no_inport*no_vc)-1:0] allow_vcs_to_ouports [(no_outport-1):0];
wire [(no_outport-1):0] updates_from_inports [(no_inport-1):0];
wire [(no_inport-1):0] updates_to_outports [(no_outport-1):0];
wire [(no_outport-1):0] sent_req_from_inports [(no_inport-1):0];
wire [(no_inport-1):0] sent_req_to_outports [(no_outport-1):0];
wire [(no_outport-1):0] new_vec_from_inports [(no_inport-1):0];
wire [(no_inport-1):0] new_vec_to_outports [(no_outport-1):0];
wire [(no_outport*floorplusone_log2_no_vc)-1:0] busies;
wire [(no_outport*phit_size)-1:0] data_from_inports [(no_inport-1):0];
wire [(no_inport*phit_size)-1:0] data_to_ouports [(no_outport-1):0];

genvar i,j;

generate for(i=0;i<no_outport;i=i+1) begin: data_to_ouports_outloop
  for(j=0;j<no_inport;j=j+1) begin: data_to_ouports_inloop
  assign  data_to_ouports[i][((j+1)*phit_size)-1:(j*phit_size)]= data_from_inports[j][((i+1)*phit_size)-1:(i*phit_size)];
       end
    end
endgenerate

generate for(i=0;i<no_inport;i=i+1) begin: ready_vec_to_inports_outloop
            for(j=0;j<no_outport;j=j+1) begin: ready_vec_to_inports_inloop
               assign ready_vec_to_inports[i][j]= ready_vec_from_outports[j][i];
            end
         end
endgenerate

generate for(i=0;i<no_inport;i=i+1) begin: oks_vec_to_inports_outloop
            for(j=0;j<no_outport;j=j+1) begin: oks_vec_to_inports_inloop
               assign oks_vec_to_inports[i][j]= oks_vec_from_outports[j][i];
            end
         end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin: new_vec_to_outports_outloop
            for(j=0;j<no_inport;j=j+1) begin: new_vec_to_outports_inloop
               assign new_vec_to_outports[i][j]= new_vec_from_inports[j][i];
            end
         end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin: sent_req_to_outports_outloop
            for(j=0;j<no_inport;j=j+1) begin: sent_req_to_outports_inloop
               assign sent_req_to_outports[i][j]= sent_req_from_inports[j][i];
            end
         end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin: updates_to_outports_outloop
            for(j=0;j<no_inport;j=j+1) begin: updates_to_outports_inloop
               assign updates_to_outports[i][j]= updates_from_inports[j][i];
            end
         end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin: invc_req_nos_to_outports_outloop
  for(j=0;j<no_inport;j=j+1) begin: invc_req_nos_to_outports_inloop
     assign  invc_req_nos_to_outports[i][((j+1)*floorplusone_log2_no_vc)-1:(j*floorplusone_log2_no_vc)]=
                           invc_req_nos_from_inports[j][((i+1)*floorplusone_log2_no_vc)-1:(i*floorplusone_log2_no_vc)];
       end
    end
endgenerate

generate for(i=0;i<no_inport;i=i+1) begin: active_vecs_to_inports_outloop
            for(j=0;j<no_outport;j=j+1) begin: active_vecs_to_inports_inloop
               assign active_vecs_to_inports[i][j]= called_inport_vecs_from_outports[j][i];
            end
         end
endgenerate

generate for(i=0;i<no_outport;i=i+1) begin: allow_vcs_to_ouports_outloop
  for(j=0;j<no_inport;j=j+1) begin: allow_vcs_to_ouports_inloop
  assign  allow_vcs_to_ouports[i][((j+1)*no_vc)-1:(j*no_vc)]= 
                                                  allow_vcs_vec_from_inport[j][((i+1)*no_vc)-1:(i*no_vc)];
       end
    end
endgenerate

generate for(i=0;i<no_inport;i=i+1) begin: inport_loop
   
 inport #(each_cluster_dimension,
          cluster_topology,
          cluster_first_dimension_up_bound,
          cluster_second_dimension_up_bound,
          cluster_third_dimension_up_bound,
          no_clusters,
          cluster_first_dimension_no_addr_bits,
          cluster_second_dimension_no_addr_bits,
          cluster_third_dimension_no_addr_bits,
          no_cluster_no_addr_bits,
          no_outport,
          floorplusone_log2_no_outport,
          no_vc,
          floorplusone_log2_no_vc,
          flit_size,
          floorplusone_log2_flit_size,
          phit_size,
          buf_size,
          floorplusone_log2_buf_size,
          switching_method,
          addr_length,
          addr_place_in_header,
          i)
 inport  (data_from_inports[i],
          new_vec_from_inports[i],
          sent_req_from_inports[i],
          allow_vcs_vec_from_inport[i],
          updates_from_inports[i],
          invc_req_nos_from_inports[i],
          outready_vec[i],
          indata_vec[((i+1)*phit_size)-1:(i*phit_size)],
          innew_vec[i],
          insent_req_vec[i],
          invc_no_vec[((i+1)*floorplusone_log2_no_vc)-1:(i*floorplusone_log2_no_vc)],
          active_vecs_to_inports[i],
          ready_vec_to_inports[i],
          oks_vec_to_inports[i],
          called_invc_no,
          busies,
          my_addr,
          node_links_directions,
          have_fork_port,
          have_express_port,          
          reset,
          clk);
 end              
endgenerate               

generate for(i=0;i<no_outport;i=i+1) begin: outport_loop
 
 outport #(no_inport,
           floorplusone_log2_no_inport,
           no_vc,
           floorplusone_log2_no_vc,
           phit_size)
 outport  (outdata_vec[((i+1)*phit_size)-1:(i*phit_size)],
           outnew_vec[i],
           outsent_req_vec[i],
           outvc_no_vec[((i+1)*floorplusone_log2_no_vc)-1:(i*floorplusone_log2_no_vc)],
           inready_vec[i],
           called_invc_no[((i+1)*floorplusone_log2_no_vc)-1:(i*floorplusone_log2_no_vc)],
           called_inport_vecs_from_outports[i],
           busies[((i+1)*floorplusone_log2_no_vc)-1:(i*floorplusone_log2_no_vc)],
           updates_to_outports[i],
           invc_req_nos_to_outports[i],
           oks_vec_from_outports[i],
           data_to_ouports[i],
           new_vec_to_outports[i],
           sent_req_to_outports[i],
           ready_vec_from_outports[i],
           allow_vcs_to_ouports[i],
           reset,
           clk);
                                 
 end
endgenerate

assign busy= |busies;

endmodule