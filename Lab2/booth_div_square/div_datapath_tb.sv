`timescale 1ns/1ps

module div_datapath_tb;

    logic clk = 1'b0;
    always #100 clk = ~clk;    // 5 MHz

    logic              rst, save_x, save_y, en_div_step, en_write_result;
    logic signed [9:0] data, result, remainder;
    logic              error;

    div_datapath dut (
        .clk            (clk),
        .rst            (rst),
        .data           (data),
        .save_x         (save_x),
        .save_y         (save_y),
        .en_div_step    (en_div_step),
        .en_write_result(en_write_result),
        .result         (result),
        .remainder      (remainder),
        .error          (error)
    );

    // Hace a mano lo mismo que haria la FSM
    task automatic divide(input int x, input int y);
        bit ok;

        @(negedge clk);
        data   = x;
        save_x = 1'b1;              // ciclo de X: el sumador saca |X|
        @(negedge clk);
        save_x = 1'b0;
        data   = y;
        save_y = 1'b1;              // ciclo de Y: vuelta 1
        @(negedge clk);
        save_y      = 1'b0;
        en_div_step = 1'b1;         // vueltas 2 a 10
        repeat (9) @(negedge clk);
        en_div_step     = 1'b0;
        en_write_result = 1'b1;     // etapa final: signos
        @(negedge clk);
        en_write_result = 1'b0;

        if ((y == 0) || ((x == -512) && (y == -1)))
            ok = (error == 1'b1) && (result == -1) && (remainder == -1);
        else
            ok = (error == 1'b0) && (result == x / y) && (remainder == x % y);

        $display("%5d / %5d -> result=%5d remainder=%5d error=%b  %s",
                 x, y, $signed(result), $signed(remainder), error, ok ? "OK" : "FALLA");
    endtask

    initial begin
        rst             = 1'b0;
        save_x          = 1'b0;
        save_y          = 1'b0;
        en_div_step     = 1'b0;
        en_write_result = 1'b0;
        data            = '0;
        @(negedge clk);
        rst = 1'b1;

        divide(11, 3);
        divide(-7, 2);
        divide(7, -2);
        divide(-7, -2);
        divide(0, 5);
        divide(511, -512);
        divide(-512, 1);
        divide(-512, -1);   // overflow
        divide(5, 0);       // division entre 0
        $stop;
    end

endmodule