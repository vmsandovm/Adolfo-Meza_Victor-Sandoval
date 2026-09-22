`timescale 1ns/1ps

module tb;

// Generador de reloj
    logic clk;
    initial clk = 0;
// Periodo de 10ns
    always #5 clk = ~clk; 

// Instancia de la interfaz física
    BUS_MULT #(.DW(64)) itf (.clk(clk));

    sm_gm #(.DW(64)) dut (
        .clk    (itf.clk),
        .rst    (itf.rst),
        .data0  (itf.data0),
        .data1  (itf.data1),
        .square (itf.square),
        .start  (itf.start),
        .ready  (itf.ready),
        .result (itf.result)
    );

// Puntero
    microprocesador agente_uP;

    initial begin

        itf.rst    = 1'b0;
        itf.start  = 1'b0;
        itf.square = 1'b0;
        itf.data0  = '0;
        itf.data1  = '0;

// Construir la clase y pasarle el modport uP de la interfaz real
        agente_uP = new(itf.uP);

        #20;        itf.rst = 1'b1;     #20;

        $display("=== INICIO DE LA PRUEBA: 5 * 10 ===");

// Calcula el valor esperado
        agente_uP.multiply(64'd5, 64'd10);

// Task
        agente_uP.send_operation(64'd5, 64'd10, 1'b0);


        wait(itf.ready == 1'b0);
        wait(itf.ready == 1'b1);
        @(posedge itf.clk);         // Esperar un ciclo de reloj para lectura limpia

        agente_uP.compare();

        #50;
        $display("=== FIN DE LA PRUEBA ===");
        $finish;
    end

endmodule