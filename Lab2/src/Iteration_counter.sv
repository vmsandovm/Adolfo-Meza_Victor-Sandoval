/**********************************************************************************************
	                         ITESO                            
Module: Iteration_counter                                   
Description: 
	Contador de iteraciones del MDRS. Entrega Last_iteration cuando el conteo llega a la
	ultima iteracion de la operacion en curso.
	
	Input ports:                                               
		- Clk: Reloj del sistema (actua de posedge).
		- Reset: Reset del sistema (activo en 0).
		- Clear: Limpia el conteo (sincrono, activo en alto, tiene prioridad sobre Enable).
		- Enable: Incrementa el conteo (activo en alto).
		- Operation: 0 = mult, 1 = div, 2 = sqrt, 3 = square.
	Output ports:                                              
		- Last_iteration: Conteo igual a la ultima iteracion de la operacion.
	Owner: Victor Manuel Sandoval Maciel                       
	Date: 18/10/2026                                           
**********************************************************************************************/

module Iteration_counter #( parameter int DW = 10
)(
	input logic Clk,
	input logic Reset,
	input logic Clear,
	input logic Enable,
	input logic [1:0] Operation,

	output logic Last_iteration
);

	localparam int Count_width = $clog2(DW);

// Mult, div y square hacen DW iteraciones. Sqrt toma 2 bits por iteracion: DW/2.
	localparam logic [Count_width-1:0] Last_full = DW - 1;
	localparam logic [Count_width-1:0] Last_sqrt = (DW / 2) - 1;
	localparam logic [Count_width-1:0] Last_div  = DW - 2;

	logic [Count_width-1:0] Count_r;
	logic [Count_width-1:0] Last_count_w;

	always_ff @(posedge Clk or negedge Reset) begin
		if (Reset == 1'b0) begin
			Count_r <= '0;
		end
		else if (Clear == 1'b1) begin
			Count_r <= '0;
		end
		else if (Enable == 1'b1) begin
			Count_r <= Count_r + 1'b1;
		end
	end

// Seleccion de la ultima iteracion segun la operacion
	always_comb begin
		case (Operation)
			2'd1:    Last_count_w = Last_div;
			2'd2:    Last_count_w = Last_sqrt;
			default: Last_count_w = Last_full;
		endcase
	end

	always_comb begin
		if (Count_r == Last_count_w) begin
			Last_iteration = 1'b1;
		end
		else begin
			Last_iteration = 1'b0;
		end
	end

endmodule