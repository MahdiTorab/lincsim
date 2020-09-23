`timescale 1ns/10ps
module state(output [1:0] state,
             output reset,
             input hand_shake_done,rc_done,vc_done,all_done,vc_en,rs,clk);


reg [1:0] tmp_state;

assign reset= all_done || rs;
assign
   state= tmp_state[1]?(tmp_state[0]?(all_done?2'b00:2'b11):((vc_done)?2'b11:2'b10)):
                                 (tmp_state[0]?(rc_done?2'b10:2'b01):(hand_shake_done?2'b01:2'b00));

always@(posedge clk)
 begin
  if(rs) tmp_state=0;
  else if(tmp_state==0 && hand_shake_done) tmp_state=1;
  else if(tmp_state==1 && rc_done) tmp_state=2;
  else if(tmp_state==2 && vc_done) tmp_state=3;
  else if(tmp_state==3 && all_done) tmp_state=0;    
 end

endmodule