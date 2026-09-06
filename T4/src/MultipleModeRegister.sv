import Poli_Register_Modes_pkg::*;

module MultipleModeRegister #( parameter int DW = 4 )(
	input logic							clk, 
	input logic							sync_reset,
	input logic 						enb,
	input logic  [ DW-1 :0 ]		inp,
	output logic [ DW-1 :0 ]		out
);

	Poli_Register #( 
	.DW(DW),
	.MODE(SISO_LSB_MODE)	
	) Pipo (
	
	.clk   (clk),
	.sync_reset (sync_reset),
	.enb   (enb),
	.inp   (inp),
	.out   (out)
);

endmodule