module Result_display #( parameter int DW = 5
)(
	input logic [(2*DW)-1:0] Result,

	output logic [6:0] HEX0,
	output logic [6:0] HEX1,
	output logic [6:0] HEX2,
	output logic [6:0] HEX3
);

// Signo y magnitud
	logic Sign_w;
	logic [(2*DW)-1:0] Magnitude_full_w;
	logic [8:0] Magnitude_w;
	logic [7:0] bin;

// Digitos BCD
	logic [3:0] bcd_centenas;
	logic [3:0] bcd_decenas;
	logic [3:0] bcd_unidades;

// Senales internas de Double Dabble
	logic [3:0] c1, c2, c3, c4, c5, c6, c7;

// Signo y valor absoluto
	assign Sign_w = Result[(2*DW)-1];
	assign Magnitude_w = Magnitude_full_w[8:0];
	assign bin = Magnitude_w[7:0];

	always_comb begin
		if (Sign_w == 1'b1) begin
			Magnitude_full_w = ~Result + 1'b1;
		end
		else begin
			Magnitude_full_w = Result;
		end
	end
	
// Double Dabble
	BCD u1 ( .in ({1'b0, bin[7:5]}), .out(c1) );
	BCD u2 ( .in ({c1[2:0], bin[4]}), .out(c2) );
	BCD u3 ( .in ({c2[2:0], bin[3]}), .out(c3) );
	BCD u4 ( .in ({c3[2:0], bin[2]}), .out(c4) );
	BCD u5 ( .in ({1'b0, c1[3], c2[3], c3[3]}), .out(c5) );
	BCD u6 ( .in ({c4[2:0], bin[1]}),.out(c6) );

	BCD u7 ( .in ({c5[2:0], c4[3]}), .out(c7) );
	
// BCD final


	always_comb begin
// Para DW = 5, el unico valor cuya magnitud
// necesita 9 bits es 256.
		if (Magnitude_w[8]==1) begin
			bcd_centenas = 4'd2;
			bcd_decenas  = 4'd5;
			bcd_unidades = 4'd6;
		end
		else begin
			bcd_unidades = {c6[2:0], bin[0]};
			bcd_decenas  = {c7[2:0], c6[3]};
			bcd_centenas = {2'b00, c5[3], c7[3]};
		end
	end

// BCD a 7 seg.
	BinToSegs seg_units ( .in (bcd_unidades), .seg(HEX0) );
	BinToSegs seg_tens ( .in (bcd_decenas), .seg(HEX1) );
	BinToSegs seg_hundreds ( .in (bcd_centenas), .seg(HEX2) );

// Signo

	always_comb begin
		if (Sign_w)
			HEX3 = 7'b0111111; // "-"
		else
			HEX3 = 7'b1111111; // apagado
	end
endmodule