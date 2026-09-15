module FSM_Mealy #( parameter int DW
)(
    input logic Clock, 
    input logic Reset, 
    input logic Start,
    
    output logic Ready,
    output logic Iterate,
    output logic Load,
    output logic Capture
);
// Cantidad de Iteraciones 
    localparam logic [2:0] Last_iteration = DW - 1;
// Estados definidos
// Ideal. esperando un nuevo start
//        Load =   0;
//        Iterate =0;
//        Capture =0;
//        Ready =  1; 
// Load.  Cargar e inicializar operandos
//        Load =   1;
//        Iterate =0;
//        Capture =0;
//        Ready =  0;
// Run.   Ejecutando Booth algorithm
//        Load =   0;
//        Iterate =1;
//        Capture =0;
//        Ready =  0;
// Done.  Se terminaron las iteraciones y se tiene el resultado listo para mostrar
//        Load =   0;
//        Iterate =0;
//        Capture =1;
//        Ready =  0;

// Estados
    typedef enum logic {
        IDLE,
        RUN
    } state_t;

// Desplazaientos entre estados e contador para iteraciones
    state_t Current_state;
    state_t Next_state;

    logic [2:0] Iteration_count;

// Bloque sincrono de decision por iteracion segun Booth
    always_ff @(posedge Clock or negedge Reset) begin
    if (Reset == 1'b0) begin
        Current_state   <= IDLE;
        Iteration_count <= 1'b0;
    end
    else begin
        Current_state <= Next_state;
        if (Current_state == IDLE) begin
            Iteration_count <= '0;
        end
        else if (Current_state == RUN) begin
            if (Iteration_count == Last_iteration)
                Iteration_count <= '0;
            else
                Iteration_count <= Iteration_count + 1'b1;
            end
        end
    end

// Bloque asincrono para el cambio de estados. Desplazamientos entre ellos
    always_comb begin
        Next_state = Current_state;
        case (Current_state)
            IDLE: begin
            if (Start == 1'b1)
                Next_state = RUN;
            end
        
            RUN: begin
                if (Iteration_count == Last_iteration)
                    Next_state = IDLE;
                else
                    Next_state = RUN;
            end

            default: begin
                Next_state = IDLE;
            end
        endcase
    end

// Efectos del estado actual
    always_comb begin
        Load    = 1'b0;
        Iterate = 1'b0;
        Capture = 1'b0;
        Ready   = 1'b0;
        
        case (Current_state)
            IDLE: begin
                Ready = 1'b1;
                if (Start == 1'b1) begin
                    Load  = 1'b1;
                    Ready = 1'b0;
                end                
            end
            RUN: begin
                Iterate = 1'b1;
                    if (Iteration_count == Last_iteration)
                        Capture = 1'b1;
                    else begin
                        Capture = 1'b0;
                    end
            end
            default: begin
                Ready = 1'b1;
            end
        endcase
    end
endmodule