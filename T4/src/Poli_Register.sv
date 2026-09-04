module Poli_Register #( parameter DW= 4 )(
	input logic					clk, 
	input logic					reset,
	input logic 				enb,
	input logic  [ DW-1 :0 ]	inp,
	output logic [ DW-1 :0 ]	out
);

logic [DW-1:0] reg_r;
	
always_ff @(posedge clk) begin : register_label
	if(reset)
		reg_r <= '0;
	else if(enb)
		reg_r <= inp;		
end:register_label
	
assign out = reg_r;

endmodule