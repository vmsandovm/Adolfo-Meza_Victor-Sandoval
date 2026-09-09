`timescale 1ns / 1ps

module MultipleModeRegister_tb;
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
	MultipleModeRegister #( .DW(DW), .MODE(PIPO_MODE) ) dut (
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

// Estimulos: se aplican en los multiplos de 10, el reloj muestrea en 5, 15, 25...
	initial begin
	clk        =  0;
	sync_reset =  1;
	enb        =  1;
	l_s        =  0;	// Unicamente se usa para PISO y Load_shift
	inp        = '0;

// PIPO

	#10;	check(4'b0000, "sync_reset inicial");	sync_reset = 0;	inp = 4'b1010;
	#10;	check(4'b1010, "carga 1010");			inp = 4'b0101;
	#10;	check(4'b0101, "carga 0101");			enb = 0;	inp = 4'b1111;
	#10;	check(4'b0101, "retiene con enb = 0");	sync_reset = 1;
	#10;	check(4'b0000, "sync_reset en cero");

	if (errores == 0)
		$display("\n=== PIPO_MODE: PASS (0 errores) ===\n");
	else
		$display("\n=== PIPO_MODE: FAIL (%0d errores) ===\n", errores);

	$stop;
	end

endmodule