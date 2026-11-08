package mdrs_ref_model_pkg;
    import MDRS_pkg::*;

    typedef struct {
        int result;
        int remainder;
        bit error;
    } mdrs_expected_t;

    class mdrs_ref_model #(parameter int DW = 10);
        localparam int MAX_VAL = (1 << (DW-1)) - 1;    // 511
        localparam int MIN_VAL = -(1 << (DW-1));       // -512

        //true si el valor cabe en DW bits con signo
        local function bit fits(input int value);
            return (value >= MIN_VAL) && (value <= MAX_VAL);
        endfunction

        function mdrs_expected_t predict(input logic [1:0] op, input int x, input int y = 0);
            mdrs_expected_t e;
            e.result = -1; e.remainder = -1; e.error = 1'b1;
            case (op)
                OP_MULT, OP_SQUARE: begin
                    int p;
                    if (op == OP_MULT)
                        p = x * y;
                    else
                        p = x * x;
                    if (fits(p)) begin e.result = p; e.remainder = 0; e.error = 1'b0; end
                end
                OP_DIV: begin
                    //entre cero y -512/-1 (512 no cabe) son error; el residuo lleva el signo de x
                    if (!(y == 0 || (x == MIN_VAL && y == -1))) begin
                        e.result = x / y; e.remainder = x % y; e.error = 1'b0;
                    end
                end
                OP_SQRT: begin
                    //raiz entera: el mayor q con q*q <= x
                    if (x >= 0) begin
                        int q;
                        q = 0;
                        while ((q + 1) * (q + 1) <= x) q++;
                        e.result = q; e.remainder = x - q * q; e.error = 1'b0;
                    end
                end
            endcase
            return e;
        endfunction

        //compara lo que saco el DUT contra lo esperado; result y remainder entran como signed
        function bit check(input mdrs_expected_t e, input logic signed [DW-1:0] result, remainder, input logic error);
            return (result == e.result) && (remainder == e.remainder) && (error == e.error);
        endfunction
    endclass
endpackage
