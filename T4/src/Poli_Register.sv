import Poli_Register_Modes_pkg::*;

module Poli_Register #( 
	parameter DW	= 4, 
	parameter MODE = PIPO_MODE
)(
	input  logic					clk, 
	input  logic					sync_reset,
	input  logic 					enb,
	input	 logic					l_s,
	input  logic [ DW-1 :0 ]	inp,
	output logic [ DW-1 :0 ]	out
);

logic [DW-1:0] reg_r;
logic [DW-1:0] reg_next;

always_comb begin
	reg_next = reg_r;
	case (MODE)
		PIPO_MODE: begin
			reg_next = inp;
		end
		SISO_MSB_MODE: begin
			reg_next = {reg_r[DW-2:0], inp[0]};
		end
		SISO_LSB_MODE: begin
			reg_next = {inp[0], reg_r[DW-1:1]};
		end
		
		SIPO_MSB_MODE: begin
			reg_next = {reg_r[DW-2:0], inp[0]};
		end
		PISO_MSB_SIGN_MODE: begin
			if (l_s)
				reg_next = inp;
			else
				reg_next = {reg_r[DW-1], reg_r[DW-1:1]};
		end
		PISO_LSB_CIRC_MODE: begin
			if (l_s)
				reg_next = inp;
			else
				reg_next = {reg_r[0], reg_r[DW-1:1]};
		end
		LOAD_SHIFT_LEFT_CIRC_MODE: begin
			if (l_s)
				reg_next = inp;
			else
				reg_next = {reg_r[DW-2:0], reg_r[DW-1]};
		end
		
		SIPO_LSB_MODE: begin
			reg_next = {inp[0], reg_r[DW-1:1]};
		end
		
		
		default: begin
			reg_next = reg_r;
		end
		endcase
end

always_ff @(posedge clk) begin
	if (sync_reset)
		reg_r <= '0;
	else if (enb)
		reg_r <= reg_next;
	end


assign out = reg_r;

endmodule