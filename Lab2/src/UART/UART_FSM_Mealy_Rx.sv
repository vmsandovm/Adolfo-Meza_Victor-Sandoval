/**********************************************************************************************
                         ITESO
Module: UART_FSM_Mealy_Rx
Description:
	FSM Mealy del receptor UART. Controla la recepcion de un frame: 
		IDLE -> START -> DATA (8 bits) -> PARITY -> STOP.
	Input:
		- clk: Clk del sistema.
      - rst: Reset activo en bajo (0 = Reset).
      - sample_count: Pulso que indica el instante de muestreo del bit.
      - rx_sync: Linea RX sincronizada.
      - bit_count [2:0]: Contador de bits recibidos. Al llegar a 111 termina la etapa DATA.
	Output:
		- SIPO_load: Carga el bit muestreado al SIPO (en DATA).
      - received: Pulso que indica que el frame fue recibido (en PARITY).
      - en_parity: Habilita la etapa de paridad.
      - en_bit_count: Habilita el contador de bits.
      - en_baud_count: Habilita el contador de baudios.
	Date: 28/09/2026
**********************************************************************************************/
module UART_FSM_Mealy_Rx(
    input logic clk, rst, sample_count, rx_sync,
    input logic [2:0] bit_count,

    output logic SIPO_load, received,
    output logic en_parity, en_bit_count , en_baud_count
);

// Estados
    typedef enum logic [2:0] {
        IDLE    = 3'b000,
        START   = 3'b001,
        DATA    = 3'b010,
        PARITY  = 3'b011,
        STOP    = 3'b100
    } state_t;


    state_t Current_state, Next_state;

    always_ff @(posedge clk) begin
        if (rst == 1'b0) begin
            Current_state <= IDLE;
            end
        else begin
            Current_state <= Next_state;
        end
    end

    always_comb begin
        Next_state      = Current_state;
        en_baud_count   = 1'b0;
        en_bit_count    = 1'b0;
        SIPO_load       = 1'b0;
        en_parity       = 1'b0;
        received        = 1'b0;
        case (Current_state)
            IDLE:begin
                en_baud_count   = 1'b0;
                en_bit_count    = 1'b0;
                if (rx_sync == 1'b0) begin
                    Next_state = START;
                end
            end
            START:begin
                en_baud_count = 1'b1;
                if (sample_count == 1'b1) begin
                    if (rx_sync == 1'b0) begin
                        Next_state = DATA;
                    end
                    else begin
                        Next_state = IDLE;
                    end
                end
            end
            DATA:begin
                en_baud_count   = 1'b1;
                en_bit_count    = 1'b1;

                if (sample_count == 1'b1) begin
                    SIPO_load = 1'b1;

                    if (bit_count == 3'b111) begin
                        Next_state = PARITY;
                    end
                end
            end
            PARITY:begin
                en_baud_count   = 1'b1;
                en_parity       = 1'b1;

                if (sample_count == 1'b1) begin
                    received   = 1'b1;
                    Next_state = STOP;
                end
            end
            STOP:begin
                en_baud_count   = 1'b1;

                if (sample_count == 1'b1) begin
                    Next_state = IDLE;
                end
            end

            default:begin
                Next_state = IDLE;
            end
        endcase


    end
endmodule