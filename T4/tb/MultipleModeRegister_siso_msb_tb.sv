`timescale 1ns / 1ps

module MultipleModeRegister_siso_msb_tb;
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
	MultipleModeRegister #( .DW(DW), .MODE(SISO_MSB_MODE) ) dut (
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
			$display("[%0t] OK    %s: out = %b (serial_output_bit = %b)", $time, etiqueta, out, out[DW-1]);
	endtask

// Estimulos: la entrada serie es inp[0] y la salida serie es out[DW-1]
	initial begin
	clk        =  0;
	sync_reset =  1;
	enb        =  1;
	l_s        =  0;
	inp        = '0;

// SISO MSB first

	#10;	check(4'b0000, "sync_reset inicial");		sync_reset = 0;	inp = 4'b0001;
	#10;	check(4'b0001, "entra 1");					inp = 4'b0000;
	#10;	check(4'b0010, "entra 0");					inp = 4'b0001;
	#10;	check(4'b0101, "entra 1");					inp = 4'b0001;
	#10;	check(4'b1011, "palabra 1011 completa");	enb = 0;	inp = 4'b0001;
	#10;	check(4'b1011, "retiene con enb = 0");		sync_reset = 1;
	#10;	check(4'b0000, "sync_reset en cero");

	if (errores == 0)
		$display("\n=== SISO_MSB_MODE: PASS (0 errores) ===\n");
	else
		$display("\n=== SISO_MSB_MODE: FAIL (%0d errores) ===\n", errores);

	$stop;
	end

endmodule
