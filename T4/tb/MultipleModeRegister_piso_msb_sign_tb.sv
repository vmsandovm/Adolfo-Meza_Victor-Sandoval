`timescale 1ns / 1ps

module MultipleModeRegister_piso_msb_sign_tb;
	import Poli_Register_Modes_pkg::*;

	parameter int DW = 4;

	logic          clk;
	logic          sync_reset;
	logic          enb;
	logic          l_s;
	logic [DW-1:0] inp;
	logic [DW-1:0] out;

	int errores = 0;

	MultipleModeRegister #( .DW(DW), .MODE(PISO_MSB_SIGN_MODE) ) dut (
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
			$display("[%0t] OK    %s: out = %b (serial_output_bit = %b)", $time, etiqueta, out, out[0]);
	endtask

// Estimulos: l_s = 1 carga en paralelo, l_s = 0 desplaza. La salida serie es out[0]
	initial begin
	clk        =  0;
	sync_reset =  1;
	enb        =  1;
	l_s        =  0;
	inp        = '0;

// PISO MSB first con conservacion de signo

	#10;	check(4'b0000, "sync_reset inicial");		sync_reset = 0;	l_s = 1;	inp = 4'b1011;
	#10;	check(4'b1011, "carga 1011 (negativo)");	l_s = 0;
	#10;	check(4'b1101, "shift 1, replica el MSB");
	#10;	check(4'b1110, "shift 2");
	#10;	check(4'b1111, "shift 3, satura en unos");	l_s = 1;	inp = 4'b0110;
	#10;	check(4'b0110, "carga 0110 (positivo)");	l_s = 0;
	#10;	check(4'b0011, "shift 1");
	#10;	check(4'b0001, "shift 2");
	#10;	check(4'b0000, "shift 3, satura en ceros");	l_s = 1;	inp = 4'b1010;
	#10;	check(4'b1010, "carga 1010");				enb = 0;	inp = 4'b1111;
	#10;	check(4'b1010, "retiene con enb = 0");		sync_reset = 1;
	#10;	check(4'b0000, "sync_reset en cero");

	if (errores == 0)
		$display("\n=== PISO_MSB_SIGN_MODE: PASS (0 errores) ===\n");
	else
		$display("\n=== PISO_MSB_SIGN_MODE: FAIL (%0d errores) ===\n", errores);

	$stop;
	end

endmodule
