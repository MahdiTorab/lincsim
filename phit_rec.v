`timescale 1ns/10ps
module phit_rec(outdata,
                valid,
                indata,
                new,
                en,
                rs,
                clk);
 parameter flit_size=1;                //In number of phits
 parameter floorplusone_log2_flit_size=1;
 parameter phit_size=16;               //In number of bits

 output [(flit_size*phit_size)-1:0] outdata;
 output valid;
 input [(phit_size-1):0] indata;
 input new,en,rs,clk;
 
 reg [(floorplusone_log2_flit_size-1):0] pointer;
 reg [(phit_size-1):0] tmp_outdata [(flit_size-2):0];
 reg [(floorplusone_log2_flit_size-1):0] j;
 genvar i;
 
 assign outdata[(flit_size*phit_size)-1:(flit_size-1)*phit_size]=indata;
 generate for (i=0;i<flit_size-1;i=i+1) begin:outdata_loop
   assign outdata[((i+1)*phit_size)-1:(i*phit_size)]=tmp_outdata[i];
  end
 endgenerate

 assign valid= en & new & (pointer==flit_size-1);
  
 always@(posedge clk)
  begin
    if(rs) 
     begin
      pointer=0;
      for(j=0;j<flit_size-1;j=j+1) tmp_outdata[j]=0;
     end
    else
     begin
      if(en&new)
       begin
        if(pointer<flit_size-1)
         begin
          tmp_outdata[pointer]=indata;
          pointer=pointer+1;
         end
        else if(pointer==flit_size-1)
         begin
          pointer=0;
         end
       end
     end
  end
endmodule