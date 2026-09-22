interface BUS_MULT #(
    parameter int DW = 64
)(
    input logic clk
);
    // Reset
    logic rst;

    // Input data
    logic [DW - 1 : 0] data0;
    logic [DW - 1 : 0] data1;
    logic square;

    // Control
    logic start;
    logic ready;

    // Output data
    logic [2 * DW - 1 : 0] result;

    modport uP(
        input clk, ready, result,
        output rst, data0, data1, square, start
    );

    modport sm(
        output ready, result,
        input clk, rst, data0, data1, square, start
    );

endinterface