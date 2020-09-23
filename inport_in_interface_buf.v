`timescale 1ns/10ps
module inport_in_interface_buf(outdata,
                               pre_full,
                               full,
                               empty,
                               out_head,
                               out_tail,
                               indata,
                               new,
                               in_head,
                               in_tail,
                               want,
                               in_new,
                               valid,
                               reset,
                               clk);

parameter flit_size=2;       
parameter phit_size=16;              
parameter buf_size=10;                 
parameter floorplusone_log2_buf_size=4;

output reg [(flit_size*phit_size)-1:0] outdata;
output pre_full;
output reg full;
output reg empty,out_head,out_tail;
input [(flit_size*phit_size)-1:0] indata;
input new,in_head,in_tail,want,in_new,valid,reset,clk;

wire [(floorplusone_log2_buf_size-1):0] buf_head_pre,buf_tail_pre;
reg [(flit_size*phit_size)-1:0] buffer [(buf_size-1):0];
reg [1:0] type [(buf_size-1):0];      //this field determine the flit type, header flit 01, tail flit 10, others 00
reg [(floorplusone_log2_buf_size-1):0] buf_head;
reg [(floorplusone_log2_buf_size-1):0] buf_tail,pre_buf_tail_reg;
reg [(floorplusone_log2_buf_size-1):0] i; 

assign buf_head_pre= want?((buf_head<buf_size-1)?buf_head+1:0):buf_head;
assign buf_tail_pre= (in_new&valid)?((pre_buf_tail_reg<buf_size-1)?pre_buf_tail_reg+1:0):pre_buf_tail_reg;
assign pre_full=((((buf_tail_pre+1==buf_head_pre)||(buf_head_pre==0 && buf_tail_pre==buf_size-1))&& ((in_new&valid)&new))
                                                    || ((buf_head_pre==buf_tail_pre)&&((in_new&valid)|new))) | in_tail;

always@(posedge clk)
 begin
  if(reset)
   begin
    empty=1;
    full=0;
    outdata=0;
    buf_head=0;
    buf_tail=0;
    out_head=0;
    out_tail=0;
    pre_buf_tail_reg=0;
    for(i=0;i<buf_size;i=i+1)type[i]=0;
   end
  else if(~reset)
   begin
    if(in_new&valid) pre_buf_tail_reg=(pre_buf_tail_reg<buf_size-1)?pre_buf_tail_reg+1:0; 
    if(new & ~want)
     begin
      buffer[buf_tail]=indata;
      type[buf_tail][0]=in_head;
      type[buf_tail][1]=in_tail;
      if((((buf_tail+1==buf_head)&&(buf_tail<buf_size-1))||((buf_head==0)&&(buf_tail==buf_size-1))) && new) full=1;
      if(buf_tail<buf_size-1)buf_tail=buf_tail+1;
      else if (buf_tail==buf_size-1) buf_tail=0;
      empty=0;
     end
    else if(~new & want)
     begin
      if(~empty)
       begin
        outdata=buffer[buf_head];    
        out_head=type[buf_head][0];
        out_tail=type[buf_head][1];
        if(((buf_head+1==buf_tail)&&(buf_head<buf_size-1))||((buf_tail==0)&&(buf_head==buf_size-1))) empty=1;
        if(buf_head<buf_size-1)buf_head=buf_head+1;
        else if (buf_head==buf_size-1) buf_head=0;
        full=0;
       end
     end
    else if(new & want)
     begin
      if(~empty & ~full)
       begin  
        outdata=buffer[buf_head];
        out_head=type[buf_head][0];
        out_tail=type[buf_head][1];     
        buffer[buf_tail]=indata;
        type[buf_tail][0]=in_head;
        type[buf_tail][1]=in_tail;
        if(buf_head<buf_size-1)buf_head=buf_head+1;
        else if (buf_head==buf_size-1) buf_head=0;
        if(buf_tail<buf_size-1)buf_tail=buf_tail+1;
        else if (buf_tail==buf_size-1) buf_tail=0;   
       end
      else if(~empty & full)
       begin
        outdata=buffer[buf_head];
        out_head=type[buf_head][0];
        out_tail=type[buf_head][1];     
        buffer[buf_tail]=indata; 
        type[buf_tail][0]=in_head;
        type[buf_tail][1]=in_tail; 
        if(buf_head<buf_size-1)buf_head=buf_head+1;
        else if (buf_head==buf_size-1) buf_head=0;
        if(buf_tail<buf_size-1)buf_tail=buf_tail+1;
        else if (buf_tail==buf_size-1) buf_tail=0;
       end
      else if(empty  & ~full)
       begin
        outdata=indata;
        out_head=in_head;
        out_tail=in_tail;
       end
     end
   end
 end
  
endmodule