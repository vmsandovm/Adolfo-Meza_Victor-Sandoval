module MDRS_datapath #(parameter int DW = 10)(
    input  logic          clk, rst,
    input  logic          save_x, save_y, en_step, en_write_result, capture,
    input  logic [1:0]    operation,
    input  logic [DW-1:0] data,

    output logic [1:0]    op_reg,
    output logic [DW-1:0] result, remainder,
    output logic          error
);
    import MDRS_pkg::*;

    //registros compartidos y unico sumador
    logic [DW-1:0] x_reg, y_reg;
    logic [2*DW:0] accumulator;
    logic [2*DW:0] adder_a, adder_b, adder_sum;
    logic          adder_sel;
    logic [1:0]    op_now;
    logic          x_sign;
    logic [DW-1:0] filler;
    logic          en_div_step, en_sqrt_step;

    Sumador_Restador #(.DW(2*DW+1)) adder_unit (
        .a(adder_a), .b(adder_b), .sel(adder_sel), .Result(adder_sum)
    );

    // En el ciclo de save_x la operacion todavia no esta en op_reg
    always_comb begin
        if (save_x == 1'b1)
            op_now = operation;
        else
            op_now = op_reg;
    end
    
    // X ya no se modifica, asi que su signo siempre esta en x_reg
    assign x_sign       = x_reg[DW-1];
    assign filler       = {DW{1'b0}};
    assign en_div_step  = en_step;
    assign en_sqrt_step = en_step;

    //Booth datapath y Booth result
    logic                 Load;
    logic [DW-1:0]        Multiplier_init;
    logic [2*DW:0]        Product, Product_d_w, Product_next;
    logic signed [DW-1:0] Multiplicand_r;
    logic                 Accumulate_w, Subtract_w;
    logic signed [DW-1:0] Accumulator_w;
    logic signed [DW:0]   Adder_result_w, Accumulator_next_w;
    logic                 Overflow_w, Error_d;
    logic [DW-1:0]        Result_d, Remainder_d;

    assign Load            = save_x | save_y;
    assign Multiplier_init = data;
    assign Product         = accumulator;
    assign Multiplicand_r  = x_reg;
    assign Adder_result_w  = adder_sum[DW:0];

    assign Accumulator_w = Product[2*DW : DW+1];

    always_comb begin
        case (Product[1:0])
            2'b01:   begin Accumulate_w = 1'b1; Subtract_w = 1'b0; end
            2'b10:   begin Accumulate_w = 1'b1; Subtract_w = 1'b1; end
            default: begin Accumulate_w = 1'b0; Subtract_w = 1'b0; end
        endcase
    end

    always_comb begin
        if (Accumulate_w) begin
            Accumulator_next_w = Adder_result_w;
        end
        else begin
            Accumulator_next_w = {Accumulator_w[DW-1], Accumulator_w};
        end
    end

    assign Product_next = { Accumulator_next_w, Product[DW:1]};

    always_comb begin
        if (Load) begin
            Product_d_w = { {(DW){1'b0}}, Multiplier_init, 1'b0 };
        end
        else begin
            Product_d_w = Product_next;
        end
    end

    always_comb begin
        if ((&Product_next[2*DW:DW]) == 1'b1) begin
            Overflow_w = 1'b0;
        end
        else if ((|Product_next[2*DW:DW]) == 1'b0) begin
            Overflow_w = 1'b0;
        end
        else begin
            Overflow_w = 1'b1;
        end
    end

    always_comb begin
        if (Overflow_w == 1'b1) begin
            Result_d    = '1;
            Remainder_d = '1;
        end
        else begin
            Result_d    = Product_next[DW:1];
            Remainder_d = '0;
        end
    end

    assign Error_d = Overflow_w;

    //division datapath
    logic [DW-1:0] divisor, partial_remainder;
    logic [DW:0]   shifted_remainder;
    logic divisor_fits, x_mag_next_bit;
    logic [DW-1:0] result_magnitude, remainder_magnitude;
    logic [DW-1:0] result_before_adder, remainder_before_adder;
    logic result_sign, y_sign, div_by_zero, overflow;
    logic [2*DW:0] div_adder_a, div_adder_b;
    logic          div_adder_sel;

    assign y_sign = y_reg[DW-1];

    always_comb begin
        if (save_y == 1'b1)
            divisor = data;
        else
            divisor = y_reg;

        partial_remainder = accumulator[2*DW-1:DW];
        x_mag_next_bit = accumulator[DW-1];
        shifted_remainder = {partial_remainder, x_mag_next_bit};
        divisor_fits      = ~adder_sum[DW];

        result_magnitude = accumulator[DW-1:0];
        remainder_magnitude = accumulator[2*DW-1:DW];
        result_sign = x_sign ^ y_sign;

        if (result_sign == 1'b1)
            result_before_adder = ~result_magnitude;
        else
            result_before_adder = result_magnitude;

        if (x_sign == 1'b1)
            remainder_before_adder = ~remainder_magnitude;
        else
            remainder_before_adder = remainder_magnitude;

        div_by_zero = (y_reg == '0);
        overflow = (result_sign == 1'b0) && (result_magnitude[DW-1] == 1'b1);
    end

    always_comb begin
        div_adder_a = '0;
        div_adder_b = '0;
        div_adder_sel = 1'b0;

        if (save_x == 1'b1) begin
            div_adder_b = {filler, 1'b0, data};
            div_adder_sel = data[DW-1];
        end
        else if ((save_y == 1'b1) || (en_div_step == 1'b1)) begin
            div_adder_a = {filler, shifted_remainder};
            div_adder_b = {filler, divisor[DW-1], divisor};
            div_adder_sel = ~divisor[DW-1];
        end
        else if (en_write_result == 1'b1) begin
            div_adder_a = {remainder_before_adder, 1'b0, result_before_adder};
            div_adder_b = {filler[DW-2:0], x_sign, filler, result_sign};
            div_adder_sel = 1'b0;
        end
    end

    //Square Root datapath
    logic [DW-2:0] sqrt_partial_remainder;
    logic [1:0]    x_next_pair;
    logic [DW:0]   sqrt_shifted_remainder, root_term;
    logic [DW-1:0] root_result;
    logic remainder_sign, root_bit;
    logic [2*DW:0] sqrt_adder_a, sqrt_adder_b;
    logic          sqrt_adder_sel;

    always_comb begin
        sqrt_partial_remainder = accumulator[2*DW-2:DW];
        remainder_sign = accumulator[2*DW];
        root_result = accumulator[DW-1:0];
        x_next_pair = y_reg[DW-1:DW-2];
        sqrt_shifted_remainder = {sqrt_partial_remainder, x_next_pair};
        root_term = {root_result[DW-2:0], remainder_sign, 1'b1};
        root_bit = ~adder_sum[DW];
    end

    always_comb begin
        sqrt_adder_a = '0;
        sqrt_adder_b = '0;
        sqrt_adder_sel = 1'b0;

        if (en_sqrt_step == 1'b1) begin
            sqrt_adder_a = {filler, sqrt_shifted_remainder};
            sqrt_adder_b = {filler, root_term};
            sqrt_adder_sel = ~remainder_sign;
        end
        else if (en_write_result == 1'b1) begin
            sqrt_adder_a = {filler, accumulator[2*DW:DW]};
            if (remainder_sign == 1'b1)
                sqrt_adder_b = {filler, root_result, 1'b1};
        end
    end

    //Mux del unico sumador
    always_comb begin
        case (op_now)
            OP_DIV: begin
                adder_a = div_adder_a;   adder_b = div_adder_b;   adder_sel = div_adder_sel;
            end
            OP_SQRT: begin
                adder_a = sqrt_adder_a;  adder_b = sqrt_adder_b;  adder_sel = sqrt_adder_sel;
            end
            default: begin
                adder_a   = {{(DW+1){Accumulator_w[DW-1]}}, Accumulator_w};
                adder_b   = {{(DW+1){Multiplicand_r[DW-1]}}, Multiplicand_r};
                adder_sel = Subtract_w;
            end
        endcase
    end

    //Alwaysff de Division y Square Root
    always_ff @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            op_reg      <= '0;
            x_reg       <= '0;
            y_reg       <= '0;
            accumulator <= '0;
            result      <= '0;
            remainder   <= '0;
            error       <= 1'b0;
        end
        else begin
            if (save_x == 1'b1) begin
                op_reg <= operation;
                x_reg  <= data;
            end

            case (op_now)
                OP_DIV: begin
                    if (save_x == 1'b1) begin
                        accumulator <= {filler, 1'b0, adder_sum[DW-1:0]};
                    end
                    else if ((save_y == 1'b1) || (en_div_step == 1'b1)) begin
                        if (save_y == 1'b1)
                            y_reg <= data;

                        if (divisor_fits == 1'b1)
                            accumulator <= {adder_sum[DW:0], accumulator[DW-2:0], 1'b1};
                        else
                            accumulator <= {shifted_remainder, accumulator[DW-2:0], 1'b0};
                    end
                    else if (en_write_result == 1'b1) begin
                        if ((div_by_zero == 1'b1) || (overflow == 1'b1)) begin
                            result    <= '1;
                            remainder <= '1;
                            error     <= 1'b1;
                        end
                        else begin
                            result    <= adder_sum[DW-1:0];
                            remainder <= adder_sum[2*DW:DW+1];
                            error     <= 1'b0;
                        end
                    end
                end

                OP_SQRT: begin
                    if (save_x == 1'b1) begin
                        y_reg       <= data;
                        accumulator <= '0;
                    end
                    else if (en_sqrt_step == 1'b1) begin
                        y_reg       <= {y_reg[DW-3:0], 2'b00};
                        accumulator <= {adder_sum[DW:0], root_result[DW-2:0], root_bit};
                    end
                    else if (en_write_result == 1'b1) begin
                        if (x_sign == 1'b1) begin
                            result    <= '1;
                            remainder <= '1;
                            error     <= 1'b1;
                        end
                        else begin
                            result    <= root_result;
                            remainder <= adder_sum[DW-1:0];
                            error     <= 1'b0;
                        end
                    end
                end

                default: begin
                    if ((Load == 1'b1) || (en_step == 1'b1))
                        accumulator <= Product_d_w;

                    if (capture == 1'b1) begin
                        result    <= Result_d;
                        remainder <= Remainder_d;
                        error     <= Error_d;
                    end
                end
            endcase
        end
    end

endmodule