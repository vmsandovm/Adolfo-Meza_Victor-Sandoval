`timescale 1ns / 1ps

module Sequential_multiplier_tb;

	parameter int DW = 5;

	logic Start;
	logic Reset;
	logic Clock;
	logic Square;

	logic [DW-1:0] Data0;
	logic [DW-1:0] Data1;

	logic Ready;
	logic [(2*DW)-1:0] Result;

	logic [6:0] HEX0, HEX1, HEX2, HEX3;

	int passed;
	int failed;

	int a;
	int b;

	int expected;
	int received;


	Sequential_multiplier #(.DW(DW),
									.ACTIVE_LOW_BUTTONS(1'b0)
	) dut (
		.Start(Start),
		.Reset(Reset),
		.Clock(Clock),
		.Square(Square),

		.Data0(Data0),
		.Data1(Data1),

		.Ready(Ready),
		.Result(Result),

		.HEX0(HEX0),
		.HEX1(HEX1),
		.HEX2(HEX2),
		.HEX3(HEX3)
	);


	// Clock externo de 50 MHz simulado
	always #10 Clock = ~Clock;


	initial begin
// Inicializacion
		Clock  = 1'b0;
		Reset  = 1'b0;
		Start  = 1'b0;
		Square = 1'b0;

		Data0 = '0;
		Data1 = '0;

		passed = 0;
		failed = 0;

// Mantener reset activo
		#100; Reset = 1'b1;	// Liberar reset

// Esperar PLL + sistema disponible
		wait (Ready == 1'b1);

		for (a = -16; a <= 15; a = a + 1) begin
			for (b = -16; b <= 15; b = b + 1) begin

				Data0  = a;
				Data1  = b;
				Square = 1'b0;

// Sistema disponible
				wait (Ready == 1'b1);
// Lanzar Start
				@(negedge Clock);
				Start = 1'b1;
// Esperar hasta que la FSM acepte Start
				wait (Ready == 1'b0);
// Ya arrancó: retirar Start
				@(negedge Clock);
				Start = 1'b0;
// Esperar resultado
				wait (Ready == 1'b1);
				#1;
				expected = a * b;
				received = $signed(Result);

				if (received == expected) begin
					passed = passed + 1;
				end
				else begin
					failed = failed + 1;
					$display( "FAIL: %0d * %0d | Expected=%0d | Received=%0d", a, b, expected, received );
				end
			end
		end
// Resumen
		$display("");
		$display("======================================");
		$display(" MULTIPLICATION TEST FINISHED");
		$display("======================================");
		$display(" Total  : %0d", passed + failed);
		$display(" Passed : %0d", passed);
		$display(" Failed : %0d", failed);
		$display("======================================");
		
		if (failed == 0)
			$display(" RESULT: ALL TESTS PASSED");
		else
			$display(" RESULT: TEST FAILED");
		$stop;
	end

endmodule