`timescale 1ns/10ps
module outport_table(called_invc_no,
                     called_inport_vec,
                     tags,
                     read_addr,
                     update_addr,
                     update_en,
                     invc_no,
                     inport_vec,
                     release_sig,
                     rs,
                     clk);
parameter no_inport=6;
parameter floorplusone_log2_no_inport=3;
parameter no_vc=13;
parameter floorplusone_log2_no_vc=4;
output [(floorplusone_log2_no_vc-1):0] called_invc_no;
output [(no_inport-1):0] called_inport_vec;
output reg [(no_vc-1):0] tags;
input [(no_vc-1):0] read_addr;
input [(floorplusone_log2_no_vc-1):0] update_addr;
input update_en;
input [(floorplusone_log2_no_vc-1):0] invc_no;
input [(no_inport-1):0] inport_vec;
input release_sig,rs,clk;

wire [(floorplusone_log2_no_vc-1):0] both_update_and_release_addr;
wire [(no_inport+floorplusone_log2_no_vc-1):0] out_table_wires [(no_vc-1):0];
reg [(floorplusone_log2_no_vc-1):0] called_invc_no_tmp;
reg [(no_inport-1):0] called_inport_vec_tmp;
reg [(no_inport+floorplusone_log2_no_vc-1):0] out_table [(no_vc-1):0];
reg [(floorplusone_log2_no_vc-1):0] i;
reg [(no_vc-1):0] read_addr_reg,read_addr_reg_inst;
reg data_transfer_en;

genvar ii;
generate for(ii=0;ii<no_vc;ii=ii+1) begin: table_loop
  assign out_table_wires[ii]= out_table[ii];
 end
endgenerate

assign called_invc_no= called_invc_no_tmp & {floorplusone_log2_no_vc{~release_sig}};
assign called_inport_vec= called_inport_vec_tmp & {no_inport{~release_sig}};

always@(posedge clk)
begin
  if(rs) tags=0;
  else
    begin
     if(release_sig & ~update_en) tags=(~read_addr_reg_inst) & tags;
     if(~release_sig & update_en) tags[update_addr]=1;
    end
end

always@(posedge clk)
  if(~rs & update_en)
    out_table[release_sig?both_update_and_release_addr:update_addr]={inport_vec,invc_no};

always@(posedge clk)
begin
  if(rs)
    begin
     called_inport_vec_tmp=0;
     called_invc_no_tmp=0;
     data_transfer_en=0;
     read_addr_reg=0;
     read_addr_reg_inst=0;
   end 
  else
   begin
    data_transfer_en=|called_inport_vec;
    read_addr_reg_inst=read_addr_reg;
    read_addr_reg=read_addr;
    if(|tags)
     begin
      for(i=0;i<no_vc;i=i+1)
       begin
        if(read_addr[i])
         begin
          called_inport_vec_tmp=out_table[i][(no_inport+floorplusone_log2_no_vc-1):floorplusone_log2_no_vc];
          called_invc_no_tmp=out_table[i][(floorplusone_log2_no_vc-1):0];
         end
       end 
     end
    else
     begin
      if(update_en)
       begin
        called_inport_vec_tmp=inport_vec;
        called_invc_no_tmp=invc_no; 
       end
      else called_inport_vec_tmp=0;  
     end
  end
end

defparam table_encoder.no_vc=no_vc;
defparam table_encoder.floorplusone_log2_no_vc=floorplusone_log2_no_vc;
encoder table_encoder(both_update_and_release_addr,
                      read_addr_reg_inst);
                      
endmodule