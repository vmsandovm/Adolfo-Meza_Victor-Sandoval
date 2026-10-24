/**********************************************************************************************
	                         ITESO                            
Module: UART_MDRS_FSM                                   
Description: 
	Controlador FSM del MDRS (Booth y division). Solo contiene la maquina de estados.
	El conteo de iteraciones vive en otro modulo. Salidas Moore, excepto Capture, que
	depende de Last_iteration para cumplir el maximo de DW ciclos entre el ultimo load y ready.
	
	Input ports:                                               
		- Clk: Reloj del sistema (actua de posedge).
		- Reset: Reset del sistema (activo en 0).
		- Load: Pulso de carga de operando (activo en alto).
		- Needs_Y: La operacion requiere segundo operando (mult o div), segun la op presente.
		- Last_iteration: El contador externo llego a la ultima iteracion (activo en alto).
		- Division: La operacion en curso es division (activo en alto).
	Output ports:                                              
		- Ready: Sistema disponible.
		- LoadX: Se espera el operando X.
		- LoadY: Se espera el operando Y.
		- Iterate: Ejecuta una iteracion del algoritmo.
		- Fix: Correccion de signo de cociente y residuo (solo division).
		- Capture: Captura de result/remainder/error.
		- Counter_clear: Limpia el contador de iteraciones.
		- Counter_enable: Habilita el contador de iteraciones.
	Owner: Victor Manuel Sandoval Maciel                       
	Date: 20/10/2026                                           
**********************************************************************************************/

module UART_MDRS_FSM (
	input logic Clk,
	input logic Reset,
	input logic Load,
	input logic Needs_Y,
	input logic Last_iteration,
	input logic Division,

	output logic Ready,
	output logic LoadX,
	output logic LoadY,
	output logic Iterate,
	output logic Fix,
	output logic Capture,
	output logic Counter_clear,
	output logic Counter_enable
);

// Estados
	typedef enum logic [1:0] {
		IDLE,
		WAIT_Y,
		RUN,
		FIX
	} state;

	state current_state, next_state;

// Registro de estado
	always_ff @(posedge Clk or negedge Reset) begin
		if (Reset == 1'b0) begin
			current_state <= IDLE;
		end
		else begin
			current_state <= next_state;
		end
	end

// Logica de siguiente estado
	always_comb begin
		case (current_state)
			IDLE: begin
				if (Load == 1'b1) begin
					if (Needs_Y == 1'b1)
						next_state = WAIT_Y;
					else
						next_state = RUN;
				end
				else begin
					next_state = IDLE;
				end
			end

			WAIT_Y: begin
				if (Load == 1'b1)
					next_state = RUN;
				else
					next_state = WAIT_Y;
			end

			RUN: begin
				if (Last_iteration == 1'b1) begin
					if (Division == 1'b1)
						next_state = FIX;
					else
						next_state = IDLE;
				end
				else begin
					next_state = RUN;
				end
			end

			FIX: begin
				next_state = IDLE;
			end

			default: next_state = IDLE;
		endcase
	end

// Salidas
	always_comb begin
		Ready          = 1'b0;
		LoadX          = 1'b0;
		LoadY          = 1'b0;
		Iterate        = 1'b0;
		Fix            = 1'b0;
		Capture        = 1'b0;
		Counter_clear  = 1'b0;
		Counter_enable = 1'b0;

		case (current_state)
			IDLE: begin				
				Ready          = 1'b1;
				LoadX          = 1'b1;
				LoadY          = 1'b0;
				Iterate        = 1'b0;
				Fix            = 1'b0;
				Capture        = 1'b0;
				Counter_clear  = 1'b1;
				Counter_enable = 1'b0;
			end
			WAIT_Y: begin
				Ready          = 1'b0;
				LoadX          = 1'b0;
				LoadY          = 1'b1;
				Iterate        = 1'b0;
				Fix            = 1'b0;
				Capture        = 1'b0;
				Counter_clear  = 1'b1;
				Counter_enable = 1'b0;
			end
			RUN: begin
				Ready          = 1'b0;
				LoadX          = 1'b0;
				LoadY          = 1'b0;
				Iterate        = 1'b1;
				Fix            = 1'b0;
				Capture        = 1'b0;
				Counter_clear  = 1'b0;
				Counter_enable = 1'b1;			
// Sin division, el resultado se captura en la ultima iteracion
				if ((Last_iteration == 1'b1) && (Division == 1'b0)) begin				
					Ready          = 1'b0;
					LoadX          = 1'b0;
					LoadY          = 1'b0;
					Iterate        = 1'b0;
					Fix            = 1'b0;
					Capture        = 1'b1;
					Counter_clear  = 1'b0;
					Counter_enable = 1'b0;				
				end
			end
			FIX: begin
				Ready          = 1'b0;
				LoadX          = 1'b0;
				LoadY          = 1'b0;
				Iterate        = 1'b0;
				Fix            = 1'b1;
				Capture        = 1'b1;
				Counter_clear  = 1'b1;
				Counter_enable = 1'b0;
			end
			default: begin			
				Ready          = 1'b1;
				LoadX          = 1'b1;
				LoadY          = 1'b0;
				Iterate        = 1'b0;
				Fix            = 1'b0;
				Capture        = 1'b0;
				Counter_clear  = 1'b1;
				Counter_enable = 1'b0;			
			end
		endcase
	end

endmodule