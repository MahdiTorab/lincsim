`timescale 1ns/10ps
module inport_in_interface_leftside(outdata,
                                    new,
                                    head,
                                    tail,
                                    outport_vec,
                                    allow_vcs,
                                    header,
                                    rc_req,
                                    handshake,
                                    in_new_to_buf,
                                    valid,rc_done,
                                    full,
                                    indata,
                                    rc_valid,
                                    outport_vec_from_rc,
                                    allow_vcs_from_rc,
                                    state,
                                    insent_req,
                                    in_new,
                                    data_en,
                                    rc_en,
                                    reset,
                                    clk);

parameter no_outport=6;
parameter no_vc=13;
parameter flit_size=3;              
parameter floorplusone_log2_flit_size=2;
parameter phit_size=8;              
parameter switching_method=1;         //1 to Store&forward, 2 to VCT, 3 to Wormhole switching          

output reg [(flit_size*phit_size)-1:0] outdata;
output [(no_outport-1):0] outport_vec;
output [(no_vc-1):0] allow_vcs;
output [(flit_size*phit_size)-1:0] header;
output rc_req,rc_done;
output reg new,head,tail;
output handshake,in_new_to_buf,valid;
input [(phit_size-1):0] indata;
input [(no_outport-1):0] outport_vec_from_rc;
input [(no_vc-1):0] allow_vcs_from_rc;
input [1:0] state;
input rc_valid,full,insent_req,in_new,data_en,rc_en,reset,clk;

wire [(flit_size*phit_size)-1:0] phit_rec_outdata;
wire valid,phit_rec_en;
reg [(flit_size*phit_size)-1:0] header_reg;
reg head_zeroforce,rc_req_reg,rc_en_reg;
reg [(no_vc-1):0] allow_vcs_reg;
reg [(no_outport-1):0] outport_vec_reg;

defparam inport_in_interface_leftside_phit_rec.flit_size=flit_size;
defparam inport_in_interface_leftside_phit_rec.floorplusone_log2_flit_size=floorplusone_log2_flit_size;
defparam inport_in_interface_leftside_phit_rec.phit_size=phit_size;
phit_rec inport_in_interface_leftside_phit_rec(phit_rec_outdata,valid,indata,in_new,phit_rec_en,reset,clk);

 assign rc_req= rc_en & rc_req_reg;
 assign phit_rec_en= ~full & data_en;
 assign header= {(flit_size*phit_size){rc_en}} & header_reg;
 assign handshake= ~state[1] & ~rc_req & insent_req & data_en;
 assign rc_done= rc_en_reg & rc_valid; 
 assign allow_vcs={no_vc{rc_req & rc_valid}}&allow_vcs_from_rc | allow_vcs_reg;
 assign outport_vec= {no_outport{rc_req & rc_valid}}&outport_vec_from_rc | outport_vec_reg;
 assign in_new_to_buf= in_new;
 
 always@(posedge clk)
  begin
   if(reset)
    begin
     allow_vcs_reg= 0;
     outport_vec_reg= 0;
     rc_en_reg=0;
    end
   else
    begin
     if(rc_en_reg & rc_valid)
      begin
       allow_vcs_reg= allow_vcs_from_rc;
       outport_vec_reg= outport_vec_from_rc;
      end
     rc_en_reg=rc_en;
    end
  end

 always@(posedge clk)
  begin
   if(reset)
    begin
     new=0;
     head=0;
     head_zeroforce=0;
     tail=0;
     outdata=0;
     header_reg=0;
     rc_req_reg=0;
    end
   else //if(~reset)
    begin
    case(state)
     2'b00:
      begin
       if(valid)
        begin
         new= ~tail;
         outdata= phit_rec_outdata;
         header_reg= ({(flit_size*phit_size){~head_zeroforce}} & phit_rec_outdata) |
                                                              ({(flit_size*phit_size){head_zeroforce}} & header_reg);
         head= ~head_zeroforce;
         head_zeroforce=1;
         rc_req_reg= ~rc_done & ~(rc_req_reg & rc_valid) & (switching_method!=1);
        end
       else //(~valid)
        begin
         new=0;
        end
      end
     2'b01:
      begin
       if(valid)
        begin
         rc_req_reg= ~rc_done & ~(rc_req_reg & rc_valid) & ((tail && switching_method==1)|
                                                            (head_zeroforce && switching_method!=1));
         new= ~tail;
         outdata= phit_rec_outdata;
         tail= ~insent_req|tail;
         header_reg= ({(flit_size*phit_size){~head_zeroforce}} & phit_rec_outdata) |
                                                              ({(flit_size*phit_size){head_zeroforce}} & header_reg);
         rc_req_reg= ~rc_done & ~(rc_req_reg & rc_valid) & ((tail && switching_method==1)||
                                                            (head_zeroforce && switching_method!=1));                                                              
         head= ~head_zeroforce;
         head_zeroforce=1;
        end
       else //(~valid)
        begin
         rc_req_reg= ~rc_done & ~(rc_req_reg & rc_valid) & ((tail && switching_method==1)||
                                                            (head_zeroforce && switching_method!=1));
         new=0;
        end
      end
     2'b10:
      begin
       if(valid)
        begin
         new= ~tail;
         outdata= phit_rec_outdata;
         tail= (~full & ~insent_req)|tail;
         tail= ~insent_req|tail;
         header_reg= ({(flit_size*phit_size){~head_zeroforce}} & phit_rec_outdata) |
                                                              ({(flit_size*phit_size){head_zeroforce}} & header_reg);
         head= ~head_zeroforce;
         head_zeroforce=1;
         rc_req_reg=0;
        end
       else //(~valid)
        begin
         new=0;
         rc_req_reg=0;
        end 
      end
     2'b11:
      begin
       if(valid)
        begin
         new= ~tail;
         outdata= phit_rec_outdata;
         tail= (~full & ~insent_req)|tail; 
         tail= ~insent_req|tail;
         head= ~head_zeroforce;
         head_zeroforce=1;
        end
       else //(~valid)
        begin
         new=0;
        end 
      end
    endcase
    end
  end

endmodule