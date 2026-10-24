/**********************************************************************************************
                         ITESO
Module: Parity_error
Description:
    Calcula la paridad de Data_out segun PARITY_TYPE (ODD por default, EVEN opcional) y la compara 
	 con el bit de paridad recibido. Si en_parity esta inactivo, parity_error se mantiene en 0.
    Parameters:
        - PARITY_TYPE: "ODD" (default) o "EVEN".
        - DW: Ancho del bus de datos.
    Input:
        - Data_out [DW-1:0]: Datos recibidos para calcular la paridad.
        - en_parity: Habilita la comparacion de paridad.
        - parity_bit: Bit de paridad recibido.
    Output:
        - parity_error: 1 cuando la paridad calculada no coincide con parity_bit.
    Date: 28/09/2026
**********************************************************************************************/

module Parity_error #(
    parameter string PARITY_TYPE = "ODD",
    parameter int DW             = 8
)(
	input logic [DW-1:0] Data_out, 
    input logic en_parity, parity_bit,
	output logic parity_error
);

    logic calculated_parity;

    always_comb begin
        if (PARITY_TYPE == "EVEN")
            calculated_parity = ^Data_out;  //EVEN
        else
            calculated_parity = ~^Data_out; //ODD

        if (en_parity == 1'b0)
            parity_error = 1'b0;
        else
            if (calculated_parity != parity_bit)
                parity_error = 1'b1;
            else
                parity_error = 1'b0;
    end

endmodule