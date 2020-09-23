`timescale 1ns/10ps
module priority_encoder(out,
                        in,
                        allows);
parameter no_vc=15;
parameter floorplusone_log2_no_vc=4;
output reg [floorplusone_log2_no_vc-1:0] out;
input [(no_vc-1):0] in,allows;

wire [(no_vc-1):0] matured_in;
wire [(no_vc-1):0] tmp;
reg [(floorplusone_log2_no_vc-1):0] i;
genvar r;

assign matured_in=in&allows;  
assign tmp[0]=matured_in[0];
 
generate for(r=1;r<=(no_vc-1);r=r+1) begin:tmp_loop
	assign tmp[r]=tmp[r-1]|matured_in[r];
    end
endgenerate 
  
always@(matured_in)
	begin
		if(tmp[0]==1 || |matured_in==0) out=0;
		else
			begin
				for(i=1;i<=(no_vc-1);i=i+1)
				if(tmp[i]==1 && tmp[i-1]==0) out=i;
			end
    end
endmodule