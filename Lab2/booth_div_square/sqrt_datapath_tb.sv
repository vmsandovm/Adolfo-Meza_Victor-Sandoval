`timescale 1ns/1ps

module sqrt_datapath_tb;

    logic clk = 1'b0;
    always #100 clk = ~clk;    // 5 MHz

    logic              rst, save_x, en_sqrt_step, en_write_result;
    logic signed [9:0] data, result, remainder;
    logic              error;

    int pass_count = 0;
    int fail_count = 0;

    sqrt_datapath dut (
        .clk            (clk),
        .rst            (rst),
        .data           (data),
        .save_x         (save_x),
        .en_sqrt_step   (en_sqrt_step),
        .en_write_result(en_write_result),
        .result         (result),
        .remainder      (remainder),
        .error          (error)
    );

    // Hace a mano lo mismo que haria la FSM
    task automatic square_root(input int x, input bit show);
        int expected_root = 0;
        int expected_remainder;
        bit ok;

        @(negedge clk);
        data   = x;
        save_x = 1'b1;              // ciclo de X: se carga X, R = 0, Q = 0
        @(negedge clk);
        save_x       = 1'b0;
        en_sqrt_step = 1'b1;        // 5 vueltas (DW/2)
        repeat (5) @(negedge clk);
        en_sqrt_step    = 1'b0;
        en_write_result = 1'b1;     // etapa final: corrige el residuo
        @(negedge clk);
        en_write_result = 1'b0;

        if (x < 0)
            ok = (error == 1'b1) && (result == -1) && (remainder == -1);
        else begin
            while ((expected_root + 1) * (expected_root + 1) <= x)
                expected_root++;
            expected_remainder = x - expected_root * expected_root;
            ok = (error == 1'b0) && (result == expected_root) && (remainder == expected_remainder);
        end

        if (ok)
            pass_count++;
        else
            fail_count++;

        if (show || ((ok == 1'b0) && (fail_count <= 10)))
            $display("sqrt(%4d) -> result=%3d remainder=%3d error=%b  %s",
                     x, $signed(result), $signed(remainder), error, ok ? "OK" : "FALLA");
    endtask

    initial begin
        rst             = 1'b0;
        save_x          = 1'b0;
        en_sqrt_step    = 1'b0;
        en_write_result = 1'b0;
        data            = '0;
        @(negedge clk);
        rst = 1'b1;

        // casos para ver uno por uno
        square_root(0,    1'b1);
        square_root(1,    1'b1);
        square_root(4,    1'b1);
        square_root(15,   1'b1);
        square_root(16,   1'b1);
        square_root(200,  1'b1);
        square_root(484,  1'b1);
        square_root(511,  1'b1);
        square_root(-1,   1'b1);    // error
        square_root(-512, 1'b1);    // error

        // todos los valores posibles; solo se imprimen las fallas
        pass_count = 0;
        fail_count = 0;
        for (int x = -512; x <= 511; x++)
            square_root(x, 1'b0);

        $display("PASS: %0d  FAIL: %0d", pass_count, fail_count);
        $stop;
    end

endmodule
