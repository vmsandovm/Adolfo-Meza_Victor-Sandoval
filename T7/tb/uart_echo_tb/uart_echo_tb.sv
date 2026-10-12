`timescale 1ns / 1ps

module uart_echo_tb;
	parameter DW = 8;
	parameter CLKS_PER_BIT = 8; // reducido para simulacion

	logic Reset;
	logic Clk;
	logic Pin_rx;
	logic Pin_tx;
	logic Ready;

	logic [DW-1:0] test_vector;
	logic [DW-1:0] received_data;
	logic frame_ok;
	logic paridad_rx;
	int passed;
	int failed;
	int b;
	int k;

	uart_echo #( .DW(DW), .CLKS_PER_BIT(CLKS_PER_BIT), .PARITY_TYPE("ODD") ) dut (
		.Reset(Reset), .Clk(Clk), .Pin_rx(Pin_rx),
		.Pin_tx(Pin_tx), .Ready(Ready)
	);

	always #100 Clk = ~Clk;   // 5 MHz

	initial begin
// Estado inicial
		Clk    = 1'b0;
		Reset  = 1'b0;
		Pin_rx = 1'b1;
		passed = 0;
		failed = 0;

// Reset asincrono (activo en bajo)
		#100;
		Reset = 1'b1;
		#(CLKS_PER_BIT * 200ns * 2);

// ASCII '0' a '9' = 48 a 57 = 0x30 a 0x39
		for (int v = 48; v <= 57; v++) begin
			test_vector   = v[DW-1:0];
			received_data = '0;
			frame_ok      = 1'b1;

			fork
// Transmision por Pin_rx: start, 8 datos (LSB primero), paridad ODD, 2 stop
				begin
					Pin_rx = 1'b0;                              // start
					#(CLKS_PER_BIT * 200ns);
					for (b = 0; b < DW; b = b + 1) begin
						Pin_rx = test_vector[b];
						#(CLKS_PER_BIT * 200ns);
					end
					Pin_rx = ~^test_vector;                     // paridad ODD
					#(CLKS_PER_BIT * 200ns);
					Pin_rx = 1'b1;                              // stop 1
					#(CLKS_PER_BIT * 200ns);
					Pin_rx = 1'b1;                              // stop 2
					#(CLKS_PER_BIT * 200ns);
				end

// Lectura del eco por Pin_tx
				begin
					wait (Pin_tx == 1'b0);                      // inicio del eco
					#(CLKS_PER_BIT * 100ns);                    // centro del start bit
					if (Pin_tx !== 1'b0) frame_ok = 1'b0;
					for (k = 0; k < DW; k = k + 1) begin
						#(CLKS_PER_BIT * 200ns);
						received_data[k] = Pin_tx;
					end
					#(CLKS_PER_BIT * 200ns);
					paridad_rx = Pin_tx;
					if (paridad_rx !== ~^received_data) frame_ok = 1'b0;   // paridad ODD
					#(CLKS_PER_BIT * 200ns);
					if (Pin_tx !== 1'b1) frame_ok = 1'b0;       // stop
				end
			join

			if (frame_ok && received_data == test_vector) begin
				passed = passed + 1;
				$display("PASS: '%c' (0x%02h) -> eco '%c' (0x%02h)",
				         v, test_vector, received_data, received_data);
			end else begin
				failed = failed + 1;
				$display("FAIL: Enviado=%08b | Recibido=%08b | frame_ok=%0b",
				         test_vector, received_data, frame_ok);
			end

			#(CLKS_PER_BIT * 200ns * 4);                        // espacio entre bytes
		end

// Resumen
		$display("");
		$display("======================================");
		$display("     UART ECHO ASCII 0-9 FINISHED     ");
		$display("======================================");
		$display(" Total   : %0d", passed + failed);
		$display(" Passed  : %0d", passed);
		$display(" Failed  : %0d", failed);
		$display("======================================");

		if (failed == 0)
			$display(" RESULT: ALL TESTS PASSED");
		else
			$display(" RESULT: TEST FAILED");

		#30;
		$stop;
	end

// Watchdog por si algun wait se queda esperando
	initial begin
		#(CLKS_PER_BIT * 200ns * 2000);
		$display("TIMEOUT");
		$finish;
	end

endmodule