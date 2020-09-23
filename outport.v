`timescale 1ns/10ps
module outport(data,
               new,
               sent_req,
               vc_no,
               ready,
               called_invc_no,
               called_inport_vec,
               busy,
               updates,
               invc_nos,
               oks,
               outdatas,
               news,
               sent_reqs,
               readies,
               all_allowed_vcs,
               rs,
               clk);                 
parameter no_inport=6;
parameter floorplusone_log2_no_inport=3;
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;
parameter phit_size=16;

output [(phit_size-1):0] data;                              //mux//
output new;                                                 //mux//
output sent_req;                                            //mux//
output [(floorplusone_log2_no_vc-1):0] vc_no ;              //encoder//
input ready;                                                //mux//
output [(floorplusone_log2_no_vc-1):0] called_invc_no;      //out_table//
output [(no_inport-1):0] called_inport_vec;                 //out_table//
output [floorplusone_log2_no_vc-1:0] busy;                  //ones_counter//
input [(no_inport-1):0] updates;                            //updater&releaser//
input [(no_inport*floorplusone_log2_no_vc)-1:0] invc_nos ;  //updater&releaser//
output [(no_inport-1):0] oks;                               //updater&releaser//
input [((no_inport*phit_size)-1):0] outdatas;               //mux//
input [(no_inport-1):0] news;                               //mux//
input [(no_inport-1):0] sent_reqs;                          //mux//
output [(no_inport-1):0] readies;                           //mux//
input [(no_inport*no_vc)-1:0] all_allowed_vcs;              //updater&releaser//
input rs,clk;

wire [(no_vc-1):0] allowed_vcs;                   //updater&releaser:priority_encoder
wire [(floorplusone_log2_no_vc-1):0] update_vc_no;//updater&releaser:outport_table
wire [(no_inport-1):0] port_no_vec;               //updater&releaser:outport_table
wire update_en;                                   //updater&releaser:outport_table
wire [(no_vc-1):0] tags;                          //updater&releaser:outport_table
wire [no_vc:0] read_addr;                     //counter_on_ones:outport_table
wire [(floorplusone_log2_no_vc-1):0] update_addr; //priority_encoder:outport_table
wire release_sig;                                 //outport_mux:outport_table

defparam update_release.no_inport=no_inport;
defparam update_release.floorplusone_log2_no_inport=floorplusone_log2_no_inport; 
defparam update_release.no_vc=no_vc; 
defparam update_release.floorplusone_log2_no_vc=floorplusone_log2_no_vc; 
update_release  update_release(update_vc_no,
                               allowed_vcs,
                               port_no_vec,
                               update_en,
                               oks,
                               tags,
                               invc_nos,
                               all_allowed_vcs,
                               updates,
                               rs,
                               clk);

defparam outport_table.no_inport=no_inport;
defparam outport_table.floorplusone_log2_no_inport=floorplusone_log2_no_inport;  
defparam outport_table.no_vc=no_vc;  
defparam outport_table.floorplusone_log2_no_vc=floorplusone_log2_no_vc;  
outport_table outport_table(called_invc_no,
                            called_inport_vec,
                            tags,
                            read_addr[no_vc:1],
                            update_addr,
                            update_en,
                            update_vc_no,
                            port_no_vec,
                            release_sig,
                            rs,
                            clk);
                                        
defparam priority_encoder.no_vc=no_vc;
defparam priority_encoder.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
priority_encoder  priority_encoder(update_addr,
                                   ~tags,
                                   allowed_vcs);


defparam counter_on_ones.no_vc=no_vc+1;
counter_on_ones counter_on_ones(read_addr,
                                {tags,1'b0},
                                rs,
                                clk);

defparam ones_counter.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
ones_counter ones_counter(busy,
                          update_en,
                          release_sig,
                          rs,
                          clk);

defparam encoder.no_vc=no_vc;
defparam encoder.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
encoder encoder(vc_no,
                read_addr[no_vc:1]);

defparam outport_mux.phit_size=phit_size;
defparam outport_mux.no_inport=no_inport;
outport_mux outport_mux(data,
                        new,
                        sent_req,
                        ready,
                        release_sig,
                        outdatas,
                        news,
                        sent_reqs,
                        readies,
                        called_inport_vec,
                        |read_addr[no_vc:1],
                        rs,
                        clk);
 
endmodule