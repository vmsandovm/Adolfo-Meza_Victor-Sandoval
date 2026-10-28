module div_datapath #(parameter int DW = 10)(
    input logic clk, rst, save_x, save_y, en_div_step, en_write_result,
    input logic  [DW-1:0] data,

    output logic [DW-1:0] result, remainder,
    output logic error
);


    logic [DW-1:0] y_reg;
    logic [2*DW:0] accumulator;
    logic x_sign;

    logic [2*DW:0] adder_a, adder_b, adder_sum;
    logic adder_sel;

    logic [DW-1:0] divisor, partial_remainder;
    logic [DW:0]   shifted_remainder; 
    logic divisor_fits, x_mag_next_bit;
    logic [DW-1:0] result_magnitude, remainder_magnitude;
    logic [DW-1:0]  result_before_adder, remainder_before_adder;
    logic result_sign, y_sign, div_by_zero, overflow;
    logic [DW-1:0] filler;

    Sumador_Restador #(.DW(2*DW+1)) adder_unit (
    .a(adder_a), 
    .b(adder_b), 
    .sel(adder_sel),
    .Result(adder_sum)
    );

    assign y_sign = y_reg[DW-1];
    assign filler = {DW{1'b0}};

    always_ff @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            x_sign      <= 1'b0;
            y_reg       <= '0;
            accumulator <= '0;
            result      <= '0;
            remainder   <= '0;
            error       <= 1'b0;
        end
        else if (save_x == 1'b1) begin
            x_sign  <= data[DW-1];
            accumulator <= {filler, 1'b0, adder_sum[DW-1:0]};    // residuo = 0, cociente = |X|
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
                result    <= '1;    // -1
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

    always_comb begin
        if (save_y == 1'b1)
            divisor = data;
        else
            divisor = y_reg;

        //toma 10 bits [19:10] del residuo, deja el bit 20(21) porque siempre es 0 ya que el maximo es 511
        //porque tomamos solo valor absoluto DENTRO del datapath
        //el unico caso que se usa el bit 19 tambien es cuando Y = 0
        partial_remainder = accumulator[2*DW-1:DW];
        //y se agrega el bit 9(10) de X
        x_mag_next_bit = accumulator[DW-1];

        shifted_remainder = {partial_remainder, x_mag_next_bit};

        //Si la resta (residuo - |Y|) no sale negativa entoces el divisor si cabe
        divisor_fits      = ~adder_sum[DW];

        //la magnitud del cociente son los primeros 10 datos que entran al acumulador
        result_magnitude = accumulator[DW-1:0];
        //la magnitud del residuo son los bits 10 al 19 del acumulador
        remainder_magnitude = accumulator[2*DW-1:DW];
        //se hace el xor con el bit de signo de y para saber si es positivo o negativo
        //si es 0 es positivo si es 1 es negativo
        result_sign = x_sign ^ y_sign;

        if (result_sign == 1'b1)
            //si es negativo el signo del resultado la magnitud se pasa a negativo
            result_before_adder = ~result_magnitude;
        else
            result_before_adder = result_magnitude;

        if (x_sign == 1'b1)
            remainder_before_adder = ~remainder_magnitude;
        else
            remainder_before_adder = remainder_magnitude;

        div_by_zero = (y_reg == '0);
        //solo -512 / -1
        overflow = (result_sign == 1'b0) && (result_magnitude[DW-1] == 1'b1);
    end

    //Casos Sumador-restador
    always_comb begin
        adder_a = '0;
        adder_b = '0;
        adder_sel = 1'b0;

        if (save_x == 1'b1) begin
            //revisa el bit de signo de X
            adder_b = {filler, 1'b0, data};
            adder_sel = data[DW-1];
        end

        else if ((save_y == 1'b1) || (en_div_step == 1'b1)) begin
            adder_a = {filler, shifted_remainder};
            adder_b = {filler, divisor[DW-1], divisor};
            adder_sel = ~divisor[DW-1];
        end

        else if (en_write_result == 1'b1) begin
            //contiene el remainder, "cero" donde va el signo y el resultado antes de sumarle 1 (en caso de que sea negativo)
            adder_a = {remainder_before_adder, 1'b0, result_before_adder};
            //son casi puros ceros, solo contiene el signo de x en el bit 11 (12 de 21)
            adder_b = {filler[DW-2:0], x_sign, filler, result_sign};
            adder_sel = 1'b0;
        end

    end

endmodule