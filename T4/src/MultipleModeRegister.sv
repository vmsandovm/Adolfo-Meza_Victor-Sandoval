module MultipleModeRegister #( parameter int DW = 4 )(
	input logic						clk, 
	input logic						reset,
	input logic 					enb,
	input logic  [ DW-1 :0 ]		inp,
	output logic [ DW-1 :0 ]		out
);



	Poli_Register #( .DW(DW) ) Pipo (
	.clk   (clk),
	.reset (reset),
	.enb   (enb),
	.inp   (inp),
	.out   (out)
);

endmodule