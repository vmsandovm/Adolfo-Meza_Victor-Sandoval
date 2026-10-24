/**********************************************************************************************
	                         ITESO                            
Module: FSM_Moore_Tx                                   
Description: 
	Controlador FSM Moore para transmision UART con entradas activas en bajo (Push Buttons).
	Input:                                               
		- Clk: Reloj del sistema (actua de posedge).
		- Parity: Habilitar en un futuro la el parity bit.
		- Reset: Reset del sistema (activo en 0 ).
		- Start_tx: Inicio de transmision (activo en bajo 0).
	Output:                                              
		- load_shift: Habilita carga paralela (en 1) o desplazamiento (en 0) en PISO.
		- enb: Enable de actualizacion en PISO.
		- Parity_control: Control hacia Tx Frame para insertar paridad.
		- Start_control: Senal de inicio hacia Tx Frame.
		- Ready: Bandera de IDLE.
		- Data_control: Control hacia Tx Frame para datos seriales.
	Owner: Victor Manuel Sandoval Maciel                       
	Date: 28/09/2026                                           
**********************************************************************************************/

module FSM_Moore_Tx #(
	parameter int CLKS_PER_BIT
)(
	input logic Clk, 
	input logic Parity, 
	input logic Reset,
	input logic Start_tx,

	output logic load_shift,
	output logic enb,
	output logic Parity_control,
	output logic Start_control,
	output logic Ready,
	output logic Data_control
);

// estados
	typedef enum logic [2:0] { 
		IDLE,
		LOAD,
		START_BIT,
		DATA_BIT,
		PARITY_BIT,
		STOP_BIT
	} state;


	state current_state, next_state;	

// Contadores e bandera
	logic [5:0] baud_cnt;	// Ciclos de clk por cada baud 43 para 115k
	logic [3:0] N_Ciclos;	// Cantidad de bits transmitidos en el estado actual
	logic baud_tick;
// Generado al completarse cilco de clk
	always_comb begin
		 if (baud_cnt == CLKS_PER_BIT - 1)
			  baud_tick = 1'b1;
		 else
			  baud_tick = 1'b0;
	end	
	
	always_comb begin
		case (current_state)
			IDLE:begin
				if(Start_tx==1'b0)
					next_state = LOAD;
				else
					next_state = IDLE;
			end
			
			LOAD: begin
				next_state = START_BIT;
			end
			
			START_BIT: begin
				if(baud_tick==1'b1)
					next_state = DATA_BIT;
				else
					next_state = START_BIT;
				end
			
			DATA_BIT: begin
				if (baud_tick && N_Ciclos == 4'b0111) begin
					if (Parity==1'b1)
						next_state = PARITY_BIT;
					else
						next_state = STOP_BIT;
				end else begin
					next_state = DATA_BIT;
				end
			end
			
			PARITY_BIT: begin
				if (baud_tick==1'b1)
						  next_state = STOP_BIT;
					 else
						  next_state = PARITY_BIT;
				end			
			
			STOP_BIT: begin
				if (baud_tick && N_Ciclos == 4'b0001)
					  next_state = IDLE;
				 else
					  next_state = STOP_BIT;
				end
				
			default: next_state = IDLE;
		endcase
	end

	always_ff @(posedge Clk or negedge Reset) begin
		if (Reset==1'b0) begin
			current_state <= IDLE;
			N_Ciclos      <= 4'b0000;
			baud_cnt      <= 6'b000000;
		end else begin
			current_state <= next_state;

		if (current_state == IDLE) begin
			N_Ciclos <= 4'b0000;
			baud_cnt <= 6'b000000;
		end else if (current_state != next_state) begin 
			 baud_cnt <= 6'b000000;
			 N_Ciclos <= 4'b0000;
		end else begin

// En START, DATA y STOP: N_Ciclos avanza cada que baud_tick es 1
					if (baud_tick) begin
						baud_cnt <= 6'b000000;
						N_Ciclos <= N_Ciclos + 4'b0001;
					end else begin
						baud_cnt <= baud_cnt + 6'b000001;
					end
			end
		end
	end

	always_comb begin
		Ready           =1'b0;
		load_shift      =1'b0;
		enb             =1'b0;
		Start_control   =1'b0;
		Parity_control  =1'b0;
		Data_control    =1'b0;

		case (current_state)
			IDLE: begin
				Ready           =1'b1;
				load_shift      =1'b0;
				enb             =1'b0;
				Start_control   =1'b0;
				Parity_control  =1'b0;
				Data_control    =1'b0;
			end
			LOAD: begin
				Ready           =1'b0;
				load_shift      =1'b1;
				enb             =1'b1;
				Start_control   =1'b0;
				Parity_control  =1'b0;
				Data_control    =1'b0;
			end
			START_BIT: begin
				Ready           =1'b0;
				load_shift      =1'b0;
				enb             =1'b0;
				Start_control   =1'b1;
				Parity_control  =1'b0;
				Data_control    =1'b0;
			end
			DATA_BIT: begin
				Ready           =1'b0;
				load_shift      =1'b0;
				enb             = baud_tick;
				Start_control   =1'b0;
				Parity_control  =1'b0;
				Data_control    =1'b1;
			end
			PARITY_BIT: begin
				Ready           =1'b0;
				load_shift      =1'b0;
				enb             =1'b0;
				Start_control   =1'b0;
				Parity_control  =1'b1;
				Data_control    =1'b0;
			end			
			STOP_BIT: begin
				Ready           =1'b0;
				load_shift      =1'b0;
				enb             =1'b0;
				Start_control   =1'b0;
				Parity_control  =1'b0;
				Data_control    =1'b0;
			end
			default: begin
				Ready           =1'b1;
				load_shift      =1'b0;
				enb             =1'b0;
				Start_control   =1'b0;
				Parity_control  =1'b0;
				Data_control    =1'b0; 
			end
		endcase
	end

endmodule