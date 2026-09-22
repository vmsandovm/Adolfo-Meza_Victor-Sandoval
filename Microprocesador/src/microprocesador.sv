class microprocesador;

// Con ayuda clara de Gemini "Flash"
// Le di contexto de lo que estoy haciendo y contenido de mi archivo microprocesador.sv
// Prompt: Explícame cómo completar el código de la clase microprocesador y explicame mis errores
// Comentarios base de Gemini y parafraseado por mi a mi entender.

//  1. Puntero a la interfaz física (a traves del modport "uP")
    virtual BUS_MULT.uP Micro;

//  2. Variable interna para almacenar el resultado esperado del modelo matemático
//  (Usamos 128 bits para que no haya desbordamiento si DW=64)
   
    logic [127:0] expected_result;

// 3. Constructor: conecta la clase con la interfaz real
    function new(virtual BUS_MULT.uP vif);
        this.Micro = vif;
    endfunction

// 4. Valor de referencia
    function void multiply(logic [63:0] x, logic [63:0] y);
        expected_result = x * y;
    endfunction

// 5. Comparador
    function void compare();
        if (Micro.result === expected_result) begin
            $display("[TEST EXITOSO] HW = %0d | Esperado = %0d", Micro.result, expected_result);
        end else begin
            $error("[TEST FALLIDO] HW = %0d | Esperado = %0d", Micro.result, expected_result);
        end
    endfunction

// 6. Tareas para estimular las señales
    task send_operation(logic [63:0] op0, logic [63:0] op1, logic is_square);
        @(posedge Micro.clk);
        Micro.rst    <= 1'b1; 
        Micro.square <= is_square;
        Micro.data0  <= op0;
        Micro.data1  <= op1;
        Micro.start  <= 1'b1;

        @(posedge Micro.clk);
        Micro.start  <= 1'b0; // Pulso de inicio
    endtask

endclass



