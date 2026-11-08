module MDRS_wrapper #(parameter int DW = 10)(
    input  logic          clk, rst,
    input  logic          load,
    input  logic [1:0]    operation,
    input  logic [DW-1:0] data,

    output logic          ready, loadX, loadY,
    output logic [DW-1:0] result, remainder,
    output logic          error
);
    import MDRS_pkg::*;

    logic       needs_y, division, capture_x, capture_y;
    logic       iterate, fix, capture;
    logic       counter_clear, counter_enable, last_iteration;
    logic [1:0] op_reg;

    //la operacion que llega con X dice si hace falta Y; la registrada dice si pasa por FIX
    assign needs_y   = ~operation[1];
    assign division  = (op_reg == OP_DIV) || (op_reg == OP_SQRT);
    assign capture_x = loadX & load;
    assign capture_y = loadY & load;

    UART_MDRS_FSM control (
        .Clk(clk), .Reset(rst), .Load(load), .Needs_Y(needs_y),
        .Last_iteration(last_iteration), .Division(division),
        .Ready(ready), .LoadX(loadX), .LoadY(loadY),
        .Iterate(iterate), .Fix(fix), .Capture(capture),
        .Counter_clear(counter_clear), .Counter_enable(counter_enable)
    );

    Iteration_counter #(.DW(DW)) counter (
        .Clk(clk), .Reset(rst),
        .Clear(counter_clear), .Enable(counter_enable),
        .Operation(op_reg), .Last_iteration(last_iteration)
    );

    MDRS_datapath_estructural #(.DW(DW)) datapath (
        .clk            (clk),
        .rst            (rst),
        .save_x         (capture_x),
        .save_y         (capture_y),
        .en_step        (iterate),
        .en_write_result(fix),
        .capture        (capture),
        .operation      (operation),
        .data           (data),
        .op_reg         (op_reg),
        .result         (result),
        .remainder      (remainder),
        .error          (error)
    );

endmodule
