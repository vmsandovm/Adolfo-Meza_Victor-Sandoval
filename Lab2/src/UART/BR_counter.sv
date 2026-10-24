/**********************************************************************************************
                         ITESO
Module: BR_counter
Description:
    Contador de baudios del receptor UART. Cuenta CLK_CYCLES_PER_BIT ciclos de reloj por bit y
    genera sample_count en la mitad del bit. Se reinicia cuando en_baud_count esta inactivo.
    Parameters:
        - CLK_CYCLES_PER_BIT: Ciclos de reloj por bit (clk / baudrate).
    Input:
        - clk: Clk del sistema.
        - rst: Reset activo en bajo (0 = Reset).
        - en_baud_count: Habilita el conteo de baudios.
    Output:
        - sample_count: Pulso en la mitad del bit, indica el momento de muestreo.
    Date: 28/09/2026
**********************************************************************************************/

module BR_counter #(parameter int CLK_CYCLES_PER_BIT)
(
    input  logic clk, rst, en_baud_count,
    output logic sample_count
);
    logic [5:0] baud_count; //conteo de ciclos

    always_ff @(posedge clk) begin
        if (rst == 1'b0)
            baud_count <= 6'b000000;
        else if (en_baud_count == 1'b0)
            baud_count <= 6'b000000;
        else if (baud_count == CLK_CYCLES_PER_BIT-1)
            baud_count <= 6'b000000;
        else
            baud_count <= baud_count + 1'b1;
    end
    
    assign sample_count = (baud_count == (CLK_CYCLES_PER_BIT >> 1));

endmodule