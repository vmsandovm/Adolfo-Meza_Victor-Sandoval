`timescale 1ns/1ps
module mdrs_class_tb;
    import mdrs_tester_pkg::*;
    localparam int DW = 10;

    logic clk = 1'b0;
    always #100 clk = ~clk;

    mdrs_if #(.DW(DW)) bus (.clk(clk));

    MDRS_wrapper #(.DW(DW)) dut (
        .clk(bus.clk), .rst(bus.rst), .load(bus.load), .operation(bus.operation), .data(bus.data),
        .ready(bus.ready), .loadX(bus.loadX), .loadY(bus.loadY),
        .result(bus.result), .remainder(bus.remainder), .error(bus.error)
    );

    mdrs_tester #(.DW(DW)) tester;

    initial begin
        tester = new(bus);
        tester.reset();

        // Casos dirigidos (son los primeros en la onda)
        tester.mult  (  -7,  9);
        tester.mult  ( 100, 10);    // error, 1000 no cabe
        tester.mult  (-512,  1);    // limite negativo
        tester.div   (-100,  7);
        tester.div   (  57,  0);    // division entre 0
        tester.div   (-512, -1);    // overflow
        tester.sqrt  ( 500);
        tester.sqrt  (  -5);        // error
        tester.square(  22);
        tester.square( -23);        // error, 529 no cabe

        tester.summary();
        $stop;
    end
endmodule
