/**********************************************************************************************
	                         ITESO                            
Module: Poli_Register                                   
Description: 
	Registro secuencial polimorfico. Permite por medio de un parametro, cambiar el ancho de palabra (DW) 
	y su modo de operacion.
	Input ports:                                               
		- clk: Reloj del sistema (actua de posedge).
		- sync_reset: Reset sincrono, activo en alto que restablece los registros a cero.
		- enb: Enable de captura del registro de reloj(clk).
		- load_shift: Selector de modo Load/Shift (1 = Carga paralela, 0 = Desplazamiento).
		- inp: Bus de datos de entrada paralelo/serie de tamano [DW-1:0].
	Output ports:                                              
		- out: Salida del registro. Puede entregar el bus paralelo completo [DW-1:0]
		       o un bit.
	Owner: Victor Manuel Sandoval Maciel                       
	Date: 26/09/2026                                           
**********************************************************************************************/
import Poli_Register_Modes_pkg::*;

module Poli_Register #( 
	parameter DW, 
	parameter MODE = PIPO_MODE
)(
	input	logic	clk, 
	input	logic	sync_reset,
	input	logic	enb,
	input	logic	load_shift,
	input	logic	[ DW-1 :0 ]	inp,
	
	output logic out
);

// Para Parallel Output Cambiar
//	output logic [ DW-1 :0 ] out

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
			if (load_shift)
				reg_next = inp;
			else
				reg_next = {reg_r[DW-1], reg_r[DW-1:1]};
		end
		PISO_LSB_CIRC_MODE: begin
			if (load_shift)
				reg_next = inp;
			else
				reg_next = {reg_r[0], reg_r[DW-1:1]};
		end
		LOAD_SHIFT_LEFT_CIRC_MODE: begin
			if (load_shift)
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
	if (sync_reset==1'b0)
		reg_r <= 1'b0;
	else if (enb==1'b1)
		reg_r <= reg_next;
	end
/*
// Salida parallel
assign out = reg_r;
*/
// Salida Single
assign out = reg_r[0];

endmodule