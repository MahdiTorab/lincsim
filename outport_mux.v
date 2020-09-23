`timescale 1ns/10ps
module outport_mux(data,
                   new,
                   sent_req,
                   ready,
                   release_sig,
                   outdatas,
                   news,
                   sent_reqs,
                   readies,
                   select,
                   en,
                   rs,
                   clk);
 parameter phit_size=16;
 parameter no_inport=6;
 output[(phit_size-1):0] data;
 output new;
 output sent_req;
 input ready;
 output release_sig;
 input [((no_inport*phit_size)-1):0] outdatas;
 input [(no_inport-1):0] news;
 input [(no_inport-1):0] sent_reqs;
 output [(no_inport-1):0] readies;
 input [(no_inport-1):0] select;
 input en,rs,clk;
 genvar i,j,k,l;
 
 reg [(no_inport-1):0] data_select; //Pipelining vc_no and data
 reg ready_en,data_en; //Pipelining vc_no and data
 reg rs_reg,rs_reg_inst;
 
 wire [(phit_size-1):0] out_datas [(no_inport-1):0];
 wire [(no_inport-1):0] tmp_data [(phit_size-1):0];
 wire [(no_inport-1):0] tmp_new;
 wire [(no_inport-1):0] tmp_sent_req;
 
 
 generate for(i=0;i<no_inport;i=i+1) begin:out_datas_loop
   assign out_datas[i]={phit_size{data_en & data_select[i]}} & outdatas[((i+1)*phit_size)-1:(i*phit_size)];
   end
 endgenerate

 generate for(j=0;j<phit_size;j=j+1) begin:tmp_data_out_loop
           for(k=0;k<no_inport;k=k+1) begin:tmp_data_in_loop
    assign tmp_data[j][k]=out_datas[k][j];
     end
   end
 endgenerate 
 
 generate for(l=0;l<phit_size;l=l+1) begin:data_notLatch_loop
    assign data[l]= {no_inport{new}} & |tmp_data[l];;
   end
 endgenerate


 
 assign readies= ready_en?{no_inport{ready}} & select:0;
 assign tmp_new= {no_inport{data_en}} & news & data_select;
 assign new= |tmp_new;
 assign tmp_sent_req= {no_inport{data_en}} & sent_reqs & data_select;
 assign sent_req= ~(rs|rs_reg_inst) & |tmp_sent_req;
 assign release_sig= ~sent_req & new & data_en;
   
 always @(posedge clk)
  if(rs)
   begin
    data_en= ready_en;
    data_select= select;
    ready_en= en;
    rs_reg= 1;
    rs_reg_inst=1;    
   end
  else
   begin
    data_en= ready_en;
    data_select= select;
    ready_en= en;
    rs_reg_inst=rs_reg;
    rs_reg=rs;
   end
   
 endmodule