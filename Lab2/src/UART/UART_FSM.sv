/**********************************************************************************************
	                         ITESO
Module: UART_FSM
Description:
	Controlador FSM Moore del UART (Rx y Tx en una sola maquina de estados). Es half-duplex: no
	recibe mientras transmite ni al reves. Contiene los contadores de baudios y de bits que usan
	ambos lados. En el Rx, el reloj de muestreo se alinea con la mitad del bit: en RX_START se
	espera la mitad del bit de start, y al cambiar de estado el contador se reinicia, de modo que
	baud_tick cae en la mitad de cada bit siguiente.
		Rx: IDLE -> RX_START -> RX_DATA (8 bits) -> RX_PARITY -> RX_STOP -> IDLE.
		Tx: IDLE -> TX_LOAD -> TX_START -> TX_DATA (8 bits) -> TX_PARITY -> TX_STOP -> IDLE.
	Si en IDLE coinciden Start_tx y el inicio de un frame de Rx, tiene prioridad el Tx para no
	perder el pulso de envio del driver.
	Parameters:
		- CLKS_PER_BIT: Ciclos de reloj por bit (clk / baudrate).
	Input:
		- Clk: Reloj del sistema (actua de posedge).
		- Reset: Reset del sistema (activo en 0 ).
		- Rx_sync: Linea RX sincronizada.
		- Parity_error: Error de paridad del frame recibido. Si vale 1 en RX_PARITY, no se activa Received.
		- Start_tx: Inicio de transmision (activo en bajo 0).
		- Parity: Habilita el bit de paridad en el Tx.
	Output:
		- SIPO_load: Carga el bit muestreado al SIPO (en RX_DATA).
		- En_parity: Habilita la comparacion de paridad (en RX_PARITY).
		- Received: Pulso que indica que el frame fue recibido sin error de paridad.
		- load_shift: Habilita carga paralela (en 1) o desplazamiento (en 0) en PISO.
		- enb: Enable de actualizacion en PISO.
		- Parity_control: Control hacia Tx Frame para insertar paridad.
		- Start_control: Senal de inicio hacia Tx Frame.
		- Data_control: Control hacia Tx Frame para datos seriales.
		- Ready: Bandera de IDLE (el Tx esta disponible).
	Owner: Victor Manuel Sandoval Maciel
	Date: 25/10/2026
**********************************************************************************************/

module UART_FSM #(
	parameter int CLKS_PER_BIT
)(
	input logic Clk,
	input logic Reset,
	input logic Rx_sync,
	input logic Parity_error,
	input logic Start_tx,
	input logic Parity,

	output logic SIPO_load,
	output logic En_parity,
	output logic Received,
	output logic load_shift,
	output logic enb,
	output logic Parity_control,
	output logic Start_control,
	output logic Data_control,
	output logic Ready
);

// estados
	typedef enum logic [3:0] {
		IDLE,
		RX_START,
		RX_DATA,
		RX_PARITY,
		RX_STOP,
		TX_LOAD,
		TX_START,
		TX_DATA,
		TX_PARITY,
		TX_STOP
	} state;

	state current_state, next_state;

// Contadores compartidos por Rx y Tx
	logic [5:0] baud_cnt;	// Ciclos de clk por cada baud 43 para 115k
	logic [3:0] N_Ciclos;	// Cantidad de bits transmitidos/recibidos en el estado actual
	logic baud_tick;
	logic sample_tick;

// Generado al completarse ciclo de clk
	always_comb begin
		if (baud_cnt == CLKS_PER_BIT - 1)
			baud_tick = 1'b1;
		else
			baud_tick = 1'b0;
	end

// Mitad del bit de start, para validar que no fue un glitch
	always_comb begin
		if (baud_cnt == (CLKS_PER_BIT >> 1))
			sample_tick = 1'b1;
		else
			sample_tick = 1'b0;
	end

	always_comb begin
		case (current_state)
			IDLE: begin
				if (Start_tx == 1'b0)
					next_state = TX_LOAD;
				else if (Rx_sync == 1'b0)
					next_state = RX_START;
				else
					next_state = IDLE;
			end

// Rx
			RX_START: begin
				if (sample_tick == 1'b1) begin
					if (Rx_sync == 1'b0)
						next_state = RX_DATA;
					else
						next_state = IDLE;
				end
				else begin
					next_state = RX_START;
				end
			end

			RX_DATA: begin
				if (baud_tick && N_Ciclos == 4'b0111)
					next_state = RX_PARITY;
				else
					next_state = RX_DATA;
			end

			RX_PARITY: begin
				if (baud_tick == 1'b1)
					next_state = RX_STOP;
				else
					next_state = RX_PARITY;
			end

			RX_STOP: begin
				if (baud_tick == 1'b1)
					next_state = IDLE;
				else
					next_state = RX_STOP;
			end

// Tx
			TX_LOAD: begin
				next_state = TX_START;
			end

			TX_START: begin
				if (baud_tick == 1'b1)
					next_state = TX_DATA;
				else
					next_state = TX_START;
			end

			TX_DATA: begin
				if (baud_tick && N_Ciclos == 4'b0111) begin
					if (Parity == 1'b1)
						next_state = TX_PARITY;
					else
						next_state = TX_STOP;
				end
				else begin
					next_state = TX_DATA;
				end
			end

			TX_PARITY: begin
				if (baud_tick == 1'b1)
					next_state = TX_STOP;
				else
					next_state = TX_PARITY;
			end

			TX_STOP: begin
				if (baud_tick && N_Ciclos == 4'b0001)
					next_state = IDLE;
				else
					next_state = TX_STOP;
			end

			default: next_state = IDLE;
		endcase
	end

	always_ff @(posedge Clk or negedge Reset) begin
		if (Reset == 1'b0) begin
			current_state <= IDLE;
			N_Ciclos      <= 4'b0000;
			baud_cnt      <= 6'b000000;
		end
		else begin
			current_state <= next_state;

			if (current_state == IDLE) begin
				N_Ciclos <= 4'b0000;
				baud_cnt <= 6'b000000;
			end
			else if (current_state != next_state) begin
				baud_cnt <= 6'b000000;
				N_Ciclos <= 4'b0000;
			end
			else begin
// N_Ciclos avanza cada que baud_tick es 1
				if (baud_tick) begin
					baud_cnt <= 6'b000000;
					N_Ciclos <= N_Ciclos + 4'b0001;
				end
				else begin
					baud_cnt <= baud_cnt + 6'b000001;
				end
			end
		end
	end

// Salidas. Por defecto todo en 0, cada estado solo lista lo que vale 1
	always_comb begin
		Ready          = 1'b0;
		SIPO_load      = 1'b0;
		En_parity      = 1'b0;
		Received       = 1'b0;
		load_shift     = 1'b0;
		enb            = 1'b0;
		Start_control  = 1'b0;
		Parity_control = 1'b0;
		Data_control   = 1'b0;

		case (current_state)
			IDLE: begin
				Ready = 1'b1;
			end
			RX_START: begin
				Ready = 1'b0;
			end
			RX_DATA: begin
				SIPO_load = baud_tick;
			end
			RX_PARITY: begin
				En_parity = 1'b1;
// Con error de paridad se descarta el byte
				Received  = baud_tick & ~Parity_error;
			end
			RX_STOP: begin
				Ready = 1'b0;
			end
			TX_LOAD: begin
				load_shift = 1'b1;
				enb        = 1'b1;
			end
			TX_START: begin
				Start_control = 1'b1;
			end
			TX_DATA: begin
				Data_control = 1'b1;
				enb          = baud_tick;
			end
			TX_PARITY: begin
				Parity_control = 1'b1;
			end
			TX_STOP: begin
				Ready = 1'b0;
			end
// Estado ilegal: se comporta como IDLE
			default: begin
				Ready = 1'b1;
			end
		endcase
	end

endmodule
