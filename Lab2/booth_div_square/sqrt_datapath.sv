module sqrt_datapath #(parameter int DW = 10)(
    input  logic clk, rst, save_x, en_sqrt_step, en_write_result,
    input  logic [DW-1:0] data,

    output logic [DW-1:0] result, remainder,
    output logic error
);

    logic [DW-1:0] x_reg;
    logic [2*DW:0] accumulator;
    logic x_sign;

    logic [2*DW:0] adder_a, adder_b, adder_sum;
    logic adder_sel;

    logic [DW-2:0] partial_remainder;
    logic [1:0]    x_next_pair;
    logic [DW:0]   shifted_remainder, root_term;
    logic [DW-1:0] root_result;
    logic remainder_sign, root_bit;
    logic [DW-1:0] filler;

    Sumador_Restador #(.DW(2*DW+1)) adder_unit (
    .a(adder_a), 
    .b(adder_b), 
    .sel(adder_sel),
    .Result(adder_sum)
    );

    assign filler = {DW{1'b0}};

    always_ff @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            x_reg       <= '0;
            x_sign      <= 1'b0;
            accumulator <= '0;
            result      <= '0;
            remainder   <= '0;
            error       <= 1'b0;
        end

        else if (save_x == 1'b1) begin
            x_reg <= data;
            x_sign <= data[DW-1];
            accumulator <= '0;
        end

        else if (en_sqrt_step == 1'b1) begin
            //baja el siguiente par, por eso DW-3 seria el bit 7(8) y rellena con 2 ceros
            x_reg <= {x_reg[DW-3:0], 2'b00};
            //
            accumulator <= {adder_sum[DW:0], root_result[DW-2:0], root_bit};
        end

        else if (en_write_result == 1'b1) begin
            if (x_sign == 1'b1) begin
                //si X es negativo es error y no se hace la raiz cuadrada
                result   <= '1;
                remainder <= '1;
                error <= 1'b1;
            end
            
            else begin
                //si X es positivo se hace la raiz y se muestra el residuo
                result <= root_result;
                remainder <= adder_sum[DW-1:0];
                error <= 1'b0;
            end
        end
    end


    always_comb begin
        // los bits 20 y 19 solo repiten el signo entonces no los tomamos en cuenta, solo del 10 al 18
        partial_remainder = accumulator [2*DW-2:DW];
        //Para eso tenemos remainder_sign
        remainder_sign = accumulator[2*DW];
        //y el resultado de la raiz esta entre los bits 0 a 9 del acumulador
        root_result = accumulator[DW-1:0];
        //Y los bits 8 y 9 son el primer par de x
        x_next_pair = x_reg[DW-1:DW-2];
        
        //El residuo va siendo los bits 10 a 18 que salen del acumulador y el siguiente par de bits de x
        //4R + p
        shifted_remainder = {partial_remainder, x_next_pair};
        //4Q + 1 si R=> 0, 4Q+3 si R < 0;
        root_term = {root_result[DW-2:0], remainder_sign, 1'b1};
        //
        root_bit = ~adder_sum[DW];
    end

    always_comb begin
        adder_a = '0;
        adder_b = '0;
        adder_sel = 1'b0;

        if (en_sqrt_step == 1'b1) begin
            // 4R + p, con 10 ceros de relleno para llegar a 21 bits
            adder_a = {filler, shifted_remainder};
            // 4Q + 1 si R >= 0, 4Q + 3 si R < 0
            adder_b = {filler, root_term};
            // R >= 0: resta;  R < 0: suma
            adder_sel = ~remainder_sign;
        end
        else if (en_write_result == 1'b1) begin
            //tomamos los bits 20 a 10 del acumulador que son el residuo con signo y rellenamos 10 ceros a la izquierda
            adder_a = {filler, accumulator[2*DW:DW]};
            //el signo del residuo es el bit 20 del acumulador
            if (remainder_sign == 1'b1)
                //Si el signo del residuo es negativo, se hace residuo = remainder + (2*result + 1);
                //Pegarle un bit 1 a la derecha es igual a multiplicarlo por 2 y sumarle 1
                adder_b = {filler, root_result, 1'b1};
        end
    end


endmodule