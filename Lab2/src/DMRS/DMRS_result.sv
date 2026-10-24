/**********************************************************************************************
	                         ITESO                            
Module: DMRS_result                                   
Description: 
	Logica combinacional que calcula lo que se captura en result, remainder y error al terminar una 
	multiplicacion o square.
	Input:                                               
		- Product_next: Valor del registro de producto tras la ultima iteracion [2*DW+1:0].
		                El producto util son los 2*DW bits centrales, Product_next[2*DW:1].
	Output:                                              
		- Result_d: Resultado a capturar, DW bits con signo.
		- Remainder_d: Residuo a capturar, DW bits con signo.
		- Error_d: Vale 1 si el producto no es representable en DW bits con signo.
	Owner: Victor Manuel Sandoval Maciel                       
	Date: 20/10/2026                                           
**********************************************************************************************/

module DMRS_result #( parameter int DW = 10
)(
	input  logic [(2*DW)+1:0] Product_next,

	output logic [DW-1:0] Result_d,
	output logic [DW-1:0] Remainder_d,
	output logic Error_d
);

	logic Overflow_w;

// El producto util son los 2*DW bits Product_next[2*DW:1]. Cabe en DW bits con signo
// si los bits [2*DW:DW] son todos iguales (todos 0 o todos 1).
	always_comb begin
		if ((&Product_next[2*DW:DW]) == 1'b1) begin
			Overflow_w = 1'b0;
		end
		else if ((|Product_next[2*DW:DW]) == 1'b0) begin
			Overflow_w = 1'b0;
		end
		else begin
			Overflow_w = 1'b1;
		end
	end

// Con error, result y remainder valen -1 (todos unos)
	always_comb begin
		if (Overflow_w == 1'b1) begin
			Result_d    = '1;
			Remainder_d = '1;
		end
		else begin
			Result_d    = Product_next[DW:1];
			Remainder_d = '0;
		end
	end

	assign Error_d = Overflow_w;

endmodule