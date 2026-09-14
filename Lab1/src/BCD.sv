module BCD(
	input  logic [3:0] in,      // Nibble in
	output logic [3:0] out 
);

/*
	always_comb. 
		Sin memoria, combinacional, no necesita clk, evitamos latches.
	Logica.
		Segun "Double Dabble", para trabajar con el desbordamiento en BCD (o base 10)
        - Si "in" >= 5, al desplazar a la izquierda (multiplicar por 2) superaria el limite (el limite es 10)
            - Sumar 3 antes del desplazamiento forza un acarreo hacia la siguiente columna (teniendo este caso unidades/decenas/centenas)
        -Si <5, el resultado tras el desplazamiemto sigue siendo un digito BCD (<10), por lo que se queda igual.
*/

	always_comb begin
		if(in >= 4'd5)
			out = in + 4'd3;
		else
			out = in;
	end

endmodule