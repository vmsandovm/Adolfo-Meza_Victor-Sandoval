module FSM_moore(
    input logic Clock, 
    input logic Reset, 
    input logic Start,
    
    output logic Ready,
    output logic Iterate,
    output logic Load,
    output logic Capture
);
// Cantidad de Iteraciones
    localparam logic [2:0] Last_iteration =3'd100;

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
    typedef enum logic [1:0] {
        IDLE,
        LOAD,
        RUN,
        DONE
    } state_t;
// Desplazaientos entre estados e contador para iteraciones
    state_t Current_state;
    state_t Next_state;
    logic [2:0] Iteration_count;

// Bloque sincrono de decision por iteracion segun Booth
    always_ff @(posedge Clock) begin
        if (Reset==0) begin
            Current_state <= IDLE;
            Iteration_count <= 1'b0;
        end
        else begin
            Current_state <= Next_state;
            if (Current_state == LOAD) begin
                Iteration_count <= 1'b0;
            end
            else if (Current_state == RUN) begin
                Iteration_count <= Iteration_count + 1'b1;
            end
        end
    end

// Bloque asincrono para el cambio de estados. Desplazamientos entre ellos
    always_comb begin
        Next_state =Current_state;
        case (Current_state)
            IDLE: begin
                if (Start) begin
                    Next_state = LOAD;
                end
            end
            LOAD: begin
                Next_state = RUN;
            end    
            RUN: begin
                if (Iteration_count == Last_iteration) begin
                    Next_state = DONE;
                end
                else begin
                    Next_state = RUN;
                end
            end

            DONE: begin
                Next_state = IDLE;
            end

            default: begin
                Next_state = IDLE;
            end
        endcase
    end

// Efectos del estado actual
    always_comb begin
        Load = 1'b0;
        Iterate = 1'b0;
        Capture = 1'b0;
        Ready = 1'b0;

        case(Current_state)
            IDLE: begin
                Ready =1'b1;
            end
            LOAD: begin
                Load =1'b1;
            end
            RUN: begin
                Iterate =1'b1;
            end
            DONE: begin
                Capture =1'b1;
            end
            default: begin
                Ready = 1'b1;
            end                        
        endcase
    end
endmodule