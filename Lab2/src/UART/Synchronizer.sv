/**********************************************************************************************
                         ITESO
Module: Synchronizer
Description:
    Sincronizador de 3 flip-flops para la entrada RX.
    Input:
        - clk: Clk del sistema.
        - rst: Reset activo en bajo (0 = Reset, las etapas se ponen en 1).
        - rx_async: Entrada asincrona que viene directo del transmisor.
    Output:
        - rx_sync: Salida sincronizada (valor del ultimo flip-flop).
    Date: 28/09/2026
**********************************************************************************************/
module Synchronizer (
    input  logic clk, rst, 
    input logic rx_async,    //Entrada que viene directo del transmisor
    output logic rx_sync    //Salida limpia del sincronizador
);

    logic ff1, ff2, ff3;

    always_ff @(posedge clk) begin
        if (rst == 1'b0) begin
            //En UART el estado inactivo comun es 1
            ff1 <= 1'b1;
            ff2 <= 1'b1;
            ff3 <= 1'b1;
        end else begin
            ff1 <= rx_async;
            ff2 <= ff1;
            ff3 <= ff2;
        end
    end

    assign rx_sync = ff3; //La salida es el valor del ultimo flipflop

endmodule