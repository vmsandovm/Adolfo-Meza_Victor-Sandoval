/**********************************************************************************************
                         ITESO
Module: Sumador_Restador
Description:
    Sumador/restador combinacional de DW bits.
    Parameters:
        - DW: Ancho de los operandos y del resultado.
    Input ports:
        - a [DW-1:0] (signado): Operando A.
        - b [DW-1:0] (signado): Operando B.
        - sel: Operacion.
    Output ports:
        - Result [DW-1:0] (signado): Resultado de la operacion.
    Owner: Victor Manuel Sandoval Maciel
    Date: 24/10/2026
**********************************************************************************************/
module Sumador_Restador #( parameter DW
)(
	input logic signed [DW-1:0] a,
	input logic signed [DW-1:0] b,
	input logic sel,   

	output logic signed [DW-1:0] Result
);
// 0 = A + B
// 1 = A - B
	always_comb begin
		if (sel == 1'b1) begin
			Result = a - b;
		end else begin
			Result = a + b;
		end
	end

endmodule