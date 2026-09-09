`timescale 1ns / 1ps

module MultipleModeRegister_lshift_l_circ_tb;
	import Poli_Register_Modes_pkg::*;

	parameter int DW = 4;

	logic          clk;
	logic          sync_reset;
	logic          enb;
	logic          l_s;
	logic [DW-1:0] inp;
	logic [DW-1:0] out;

	int errores = 0;

	MultipleModeRegister #( .DW(DW), .MODE(LOAD_SHIFT_LEFT_CIRC_MODE) ) dut (
		.clk        (clk),
		.sync_reset (sync_reset),
		.enb        (enb),
		.l_s        (l_s),
		.inp        (inp),
		.out        (out)
	);

	always #5 clk = ~clk;

//	Auto-check
	task automatic check (input logic [DW-1:0] esperado, input string etiqueta);
		if (out !== esperado) begin
			errores++;
			$display("[%0t] FALLA %s: out = %b, esperado = %b", $time, etiqueta, out, esperado);
		end
		else
			$display("[%0t] OK    %s: out = %b", $time, etiqueta, out);
	endtask

// Estimulos: l_s = 1 carga en paralelo, l_s = 0 rota.
	initial begin
	clk        =  0;
	sync_reset =  1;
	enb        =  1;
	l_s        =  0;
	inp        = '0;

// Load and Shift a la izquierda circular

	#10;	check(4'b0000, "sync_reset inicial");		sync_reset = 0;	l_s = 1;	inp = 4'b1011;
	#10;	check(4'b1011, "carga 1011");				l_s = 0;
	#10;	check(4'b0111, "rotacion 1");
	#10;	check(4'b1110, "rotacion 2");
	#10;	check(4'b1101, "rotacion 3");
	#10;	check(4'b1011, "rotacion 4, dato recuperado");	l_s = 1;	inp = 4'b1000;
	#10;	check(4'b1000, "carga 1000");				l_s = 0;
	#10;	check(4'b0001, "rotacion 1");
	#10;	check(4'b0010, "rotacion 2");
	#10;	check(4'b0100, "rotacion 3");
	#10;	check(4'b1000, "rotacion 4, vuelta completa");	enb = 0;	l_s = 1;	inp = 4'b0000;
	#10;	check(4'b1000, "retiene con enb = 0");		sync_reset = 1;
	#10;	check(4'b0000, "sync_reset en cero");

	if (errores == 0)
		$display("\n=== LOAD_SHIFT_LEFT_CIRC_MODE: PASS (0 errores) ===\n");
	else
		$display("\n=== LOAD_SHIFT_LEFT_CIRC_MODE: FAIL (%0d errores) ===\n", errores);

	$stop;
	end

endmodule
