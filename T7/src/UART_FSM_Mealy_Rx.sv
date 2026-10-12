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

        //ESTADO 1: IDLE, esperando a que llegue un Start Bit
        case (Current_state)
            IDLE:begin
                en_baud_count   = 1'b0;
                en_bit_count    = 1'b0;
                if (rx_sync == 1'b0) begin
                    Next_state = START;
                end
            end

            //ESTADO 2: START
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

            //ESTADO 3: DATA
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

            //ESTADO 4: PARITY
            PARITY:begin
                en_baud_count   = 1'b1;
                en_parity       = 1'b1;

                if (sample_count == 1'b1) begin
                    received   = 1'b1;
                    Next_state = STOP;
                end
            end

            //ESTADO 5: STOP
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