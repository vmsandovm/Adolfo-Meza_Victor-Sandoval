/**********************************************************************************************
                         ITESO
Module: Bit_counter
Description:
    Contador de bits recibidos del receptor UART. Incrementa bit_count en cada sample_count mientras 
	 en_bit_count esta activo. Se reinicia cuando en_bit_count esta inactivo.
    Input ports:
        - clk: Clk del sistema.
        - rst: Reset activo en bajo (0 = Reset).
        - en_bit_count: Habilita el conteo de bits.
        - sample_count: Pulso de muestreo que incrementa el contador.
    Output ports:
        - bit_count [2:0]: Numero de bits recibidos.
    Date: 28/09/2026
**********************************************************************************************/
module Bit_counter (
    input  logic clk, rst, en_bit_count, sample_count,
    output logic [2:0] bit_count
);

    always_ff @(posedge clk) begin
        if (rst == 1'b0)
            bit_count <= 3'b000;
        else if (en_bit_count == 1'b0)
            bit_count <= 3'b000;
        else if (sample_count == 1'b1)
            bit_count <= bit_count + 1'b1;
    end

endmodule