`timescale 1ns / 1ps

module MultipleModeRegister_sipo_lsb_tb;
	import Poli_Register_Modes_pkg::*;

	parameter int DW = 4;

	logic          clk;
	logic          sync_reset;
	logic          enb;
	logic          l_s;
	logic [DW-1:0] inp;
	logic [DW-1:0] out;

	int errores = 0;

// Instancia del DUT
	MultipleModeRegister #( .DW(DW), .MODE(SIPO_LSB_MODE) ) dut (
		.clk        (clk),
		.sync_reset (sync_reset),
		.enb        (enb),
		.l_s        (l_s),
		.inp        (inp),
		.out        (out)
	);

//	Clock
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

// Estimulos: la entrada serie es inp[0]
	initial begin
	clk        =  0;
	sync_reset =  1;
	enb        =  1;
	l_s        =  0;
	inp        = '0;

// SIPO LSB first

	#10;	check(4'b0000, "sync_reset inicial");		sync_reset = 0;	inp = 4'b0001;
	#10;	check(4'b1000, "entra 1, primer bit");		inp = 4'b0000;
	#10;	check(4'b0100, "entra 0");					inp = 4'b0000;
	#10;	check(4'b0010, "entra 0");					inp = 4'b0000;
	#10;	check(4'b0001, "primer bit llego al LSB");	enb = 0;	inp = 4'b0001;
	#10;	check(4'b0001, "retiene con enb = 0");		sync_reset = 1;
	#10;	check(4'b0000, "sync_reset en cero");

	if (errores == 0)
		$display("\n=== SIPO_LSB_MODE: PASS (0 errores) ===\n");
	else
		$display("\n=== SIPO_LSB_MODE: FAIL (%0d errores) ===\n", errores);

	$stop;
	end

endmodule
