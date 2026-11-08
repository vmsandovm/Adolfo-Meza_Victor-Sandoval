interface mdrs_if #(parameter int DW = 10)(input logic clk);
    logic          rst, load;
    logic [1:0]    operation;
    logic [DW-1:0] data;
    logic          ready, loadX, loadY;
    logic [DW-1:0] result, remainder;
    logic          error;

    modport dut (input  clk, rst, load, operation, data,
                 output ready, loadX, loadY, result, remainder, error);
    modport tb  (input  clk, ready, loadX, loadY, result, remainder, error,
                 output rst, load, operation, data);
endinterface
