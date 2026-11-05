module MDRS_datapath_estructural #(parameter int DW = 10)(
    input  logic          clk, rst,
    input  logic          save_x, save_y, en_step, en_write_result, capture,
    input  logic [1:0]    operation,
    input  logic [DW-1:0] data,

    output logic [1:0]    op_reg,
    output logic [DW-1:0] result, remainder,
    output logic          error
);

    //registros compartidos
    logic [DW-1:0] x_reg, y_reg;
    logic [2*DW:0] accumulator;
    logic [2*DW:0] adder_a, adder_b, adder_sum;
    logic          adder_sel;
    logic [1:0]    op_now;
    logic          x_sign;
    logic [DW-1:0] filler;
    logic          en_div_step, en_sqrt_step;
    logic          is_div, is_sqrt;

    //Unico sumador
    Sumador_Restador #(.DW(2*DW+1)) adder_unit (
        .a(adder_a), .b(adder_b), .sel(adder_sel), .Result(adder_sum)
    );

    // En el ciclo de save_x la operacion todavia no esta en op_reg
    mux2 #(.DW(2)) op_now_mux (
        .sel(save_x), .in1(operation), .in0(op_reg), .out(op_now)
    );

    // X ya no se modifica, asi que su signo siempre esta en x_reg
    assign x_sign       = x_reg[DW-1];
    assign filler       = {DW{1'b0}};
    assign en_div_step  = en_step;
    assign en_sqrt_step = en_step;
    //op: 0 mult, 1 div, 2 sqrt, 3 square (div y sqrt son las que pasan por FIX)
    assign is_div       = ~op_now[1] &  op_now[0];
    assign is_sqrt      =  op_now[1] & ~op_now[0];

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
    //Nuevas para booth estructural
    logic [2*DW:0]        booth_adder_a, booth_adder_b;

    assign Load            = save_x | save_y;
    assign Multiplier_init = data;
    assign Product         = accumulator;
    assign Multiplicand_r  = x_reg;
    assign Adder_result_w  = adder_sum[DW:0];

    assign Accumulator_w = Product[2*DW : DW+1];

    //Booth decide con Q(0) y Q(-1): 01 suma el multiplicando, 10 lo resta, 00 y 11 no hacen nada
    assign Accumulate_w = Product[1] ^ Product[0];
    assign Subtract_w   = Product[1] & ~Product[0];

    //A y M extendidos en signo al ancho del sumador compartido
    assign booth_adder_a = {{(DW+1){Accumulator_w[DW-1]}}, Accumulator_w};
    assign booth_adder_b = {{(DW+1){Multiplicand_r[DW-1]}}, Multiplicand_r};

    //cuando Booth no opera se conserva el acumulador (con el signo repetido) en vez de la salida del sumador
    mux2 #(.DW(DW+1)) accumulator_next_w_mux (
        .sel(Accumulate_w), .in1(Adder_result_w), .in0({Accumulator_w[DW-1], Accumulator_w}), .out(Accumulator_next_w)
    );

    //el bit extra del sumador ya trae el signo: recorrer a la derecha es descartar el bit 0
    assign Product_next = {Accumulator_next_w, Product[DW:1]};

    //Load inicializa el producto con el multiplicador y Q(-1) = 0, si no avanza una iteracion
    mux2 #(.DW(2*DW+1)) product_d_mux (
        .sel(Load), .in1({filler, Multiplier_init, 1'b0}), .in0(Product_next), .out(Product_d_w)
    );

    //el producto cabe en DW bits con signo si los bits [2*DW:DW] son todos 1 o todos 0
    assign Overflow_w = ~(&Product_next[2*DW:DW]) & (|Product_next[2*DW:DW]);

    //con error result y remainder valen -1 (todos unos)
    mux2 #(.DW(DW)) result_d_mux    (.sel(Overflow_w), .in1('1), .in0(Product_next[DW:1]), .out(Result_d));
    mux2 #(.DW(DW)) remainder_d_mux (.sel(Overflow_w), .in1('1), .in0('0),                 .out(Remainder_d));

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
    //Nuevas para div estructural
    logic          div_step, div_error;
    logic [2*DW:0] div_step_a, div_step_b;
    logic          div_step_sel;

    assign y_sign = y_reg[DW-1];

    //en el ciclo de save_y Y todavia no esta en y_reg, se toma directo de data
    mux2 #(.DW(DW)) divisor_mux (
        .sel(save_y), .in1(data), .in0(y_reg), .out(divisor)
    );

    //toma 10 bits [19:10] del residuo, deja el bit 20 porque siempre es 0 ya que el maximo es 511
    //(dentro del datapath se trabaja con el valor absoluto) el unico caso que usa el bit 19 es Y = 0
    assign partial_remainder = accumulator[2*DW-1:DW];
    //se agrega el bit 9 de X
    assign x_mag_next_bit    = accumulator[DW-1];
    assign shifted_remainder = {partial_remainder, x_mag_next_bit};
    //si la resta (residuo - |Y|) no sale negativa entonces el divisor si cabe
    assign divisor_fits      = ~adder_sum[DW];

    //la magnitud del cociente (resultado) son los primeros 10 bits que entran al acumulador
    assign result_magnitude    = accumulator[DW-1:0];
    //la magnitud del residuo son los bits 10 al 19 del acumulador
    assign remainder_magnitude = accumulator[2*DW-1:DW];
    //Xor para ver el signo de la mag del resultado. 0 el cociente es positivo, 1 es negativo
    assign result_sign         = x_sign ^ y_sign;

    //si el resultado es negativo la magnitud se invierte, el +1 lo pone el sumador en FIX
    mux2 #(.DW(DW)) result_before_adder_mux (
        .sel(result_sign), .in1(~result_magnitude), .in0(result_magnitude), .out(result_before_adder)
    );
    //el residuo lleva el signo de X
    mux2 #(.DW(DW)) remainder_before_adder_mux (
        .sel(x_sign), .in1(~remainder_magnitude), .in0(remainder_magnitude), .out(remainder_before_adder)
    );

    //ningun bit de Y en 1
    assign div_by_zero = (y_reg == '0);
    //solo -512 / -1
    assign overflow    = ~result_sign & result_magnitude[DW-1];
    assign div_error   = div_by_zero | overflow;


    //save_x: revisa el bit de signo de X para sacar |X|
    //save_y o en_div_step: residuo corrido menos |Y| (restar -Y es lo mismo que sumar Y, por eso sel = ~signo de Y)
    //en_write_result: remainder, "cero" donde va el signo y result antes de sumarles 1 (en caso de que sean negativos)
    //b son casi puros ceros, solo el signo de X en el bit 11 (12 de 21) y el signo del result en el 0
    //cuando no hay fase activa el resultado del sumador no se usa, por eso FIX queda como ultimo caso
    assign div_step = save_y | en_div_step;

    mux2 #(.DW(2*DW+1)) div_step_a_mux (
        .sel(div_step), .in1({filler, shifted_remainder}), .in0({remainder_before_adder, 1'b0, result_before_adder}), .out(div_step_a)
    );
    mux2 #(.DW(2*DW+1)) div_adder_a_mux (
        .sel(save_x), .in1('0), .in0(div_step_a), .out(div_adder_a)
    );

    mux2 #(.DW(2*DW+1)) div_step_b_mux (
        .sel(div_step), .in1({filler, divisor[DW-1], divisor}), .in0({filler[DW-2:0], x_sign, filler, result_sign}), .out(div_step_b)
    );
    mux2 #(.DW(2*DW+1)) div_adder_b_mux (
        .sel(save_x), .in1({filler, 1'b0, data}), .in0(div_step_b), .out(div_adder_b)
    );

    mux2 #(.DW(1)) div_step_sel_mux (
        .sel(div_step), .in1(~divisor[DW-1]), .in0(1'b0), .out(div_step_sel)
    );
    mux2 #(.DW(1)) div_adder_sel_mux (
        .sel(save_x), .in1(data[DW-1]), .in0(div_step_sel), .out(div_adder_sel)
    );

    //Square Root datapath
    logic [DW-2:0] sqrt_partial_remainder;
    logic [1:0]    x_next_pair;
    logic [DW:0]   sqrt_shifted_remainder, root_term;
    logic [DW-1:0] root_result;
    logic remainder_sign, root_bit;
    logic [2*DW:0] sqrt_adder_a, sqrt_adder_b, sqrt_fix_b;
    logic          sqrt_adder_sel;

    //los bits 20 y 19 solo repiten el signo entonces no se toman en cuenta, solo del 10 al 18
    assign sqrt_partial_remainder = accumulator[2*DW-2:DW];
    //para eso esta remainder_sign
    assign remainder_sign         = accumulator[2*DW];
    //el resultado de la raiz esta entre los bits 0 a 9 del acumulador
    assign root_result            = accumulator[DW-1:0];
    //la copia de X que se va recorriendo vive en y_reg, los bits 9 y 8 son el siguiente par
    assign x_next_pair            = y_reg[DW-1:DW-2];
    //4R + p: el residuo que sale del acumulador y el siguiente par de bits de X
    assign sqrt_shifted_remainder = {sqrt_partial_remainder, x_next_pair};
    //4Q + 1 si R >= 0, 4Q + 3 si R < 0
    assign root_term              = {root_result[DW-2:0], remainder_sign, 1'b1};
    //el bit de la raiz es 1 si el residuo nuevo no salio negativo
    assign root_bit               = ~adder_sum[DW];

    //en_sqrt_step: 4R + p con 10 ceros de relleno para llegar a 21 bits, contra 4Q + 1 o 4Q + 3;
    //R >= 0 resta, R < 0 suma
    //en_write_result: bits 20 a 10 del acumulador (residuo con signo) y, si queda negativo,
    //se le suma 2*result + 1 (pegarle un 1 a la derecha es multiplicar por 2 y sumar 1)
    mux2 #(.DW(2*DW+1)) sqrt_fix_b_mux (
        .sel(remainder_sign), .in1({filler, root_result, 1'b1}), .in0('0), .out(sqrt_fix_b)
    );

    mux2 #(.DW(2*DW+1)) sqrt_adder_a_mux (
        .sel(en_sqrt_step), .in1({filler, sqrt_shifted_remainder}), .in0({filler, accumulator[2*DW:DW]}), .out(sqrt_adder_a)
    );
    mux2 #(.DW(2*DW+1)) sqrt_adder_b_mux (
        .sel(en_sqrt_step), .in1({filler, root_term}), .in0(sqrt_fix_b), .out(sqrt_adder_b)
    );
    mux2 #(.DW(1)) sqrt_adder_sel_mux (
        .sel(en_sqrt_step), .in1(~remainder_sign), .in0(1'b0), .out(sqrt_adder_sel)
    );

    //Mux del unico sumador
    //op_now: 0 mult, 1 div, 2 sqrt, 3 square (mult y square usan Booth)
    mux4 #(.DW(2*DW+1)) adder_a_mux (
        .sel(op_now), .in0(booth_adder_a), .in1(div_adder_a), .in2(sqrt_adder_a), .in3(booth_adder_a), .out(adder_a)
    );
    mux4 #(.DW(2*DW+1)) adder_b_mux (
        .sel(op_now), .in0(booth_adder_b), .in1(div_adder_b), .in2(sqrt_adder_b), .in3(booth_adder_b), .out(adder_b)
    );
    mux4 #(.DW(1)) adder_sel_mux (
        .sel(op_now), .in0(Subtract_w), .in1(div_adder_sel), .in2(sqrt_adder_sel), .in3(Subtract_w), .out(adder_sel)
    );

    //Registros (lo que era el always_ff de div y sqrt): cada uno con su enable y su siguiente valor
    logic          en_y, en_accumulator, en_output;
    logic [DW-1:0] y_next;
    logic [2*DW:0] accumulator_next, div_accumulator_step, div_accumulator_next, sqrt_accumulator_next;
    logic [DW-1:0] div_result_next, div_remainder_next, sqrt_result_next, sqrt_remainder_next;
    logic [DW-1:0] result_next, remainder_next;
    logic          error_next;

    //op_reg y x_reg se cargan junto con X
    register_ar #(.DW(2))  op_register (.clk(clk), .rst(rst), .enb(save_x), .d(operation), .q(op_reg));
    register_ar #(.DW(DW)) x_register  (.clk(clk), .rst(rst), .enb(save_x), .d(data),      .q(x_reg));

    //y_reg: la division guarda Y con save_y
    //la raiz guarda X con save_x y lo recorre 2 bits en cada en_sqrt_step
    assign en_y = (is_div & save_y) | (is_sqrt & (save_x | en_sqrt_step));
    //baja el siguiente par, por eso DW-3 seria el bit 7 y rellena con 2 ceros
    mux2 #(.DW(DW)) y_next_mux (
        .sel(en_sqrt_step), .in1({y_reg[DW-3:0], 2'b00}), .in0(data), .out(y_next)
    );
    register_ar #(.DW(DW)) y_register (.clk(clk), .rst(rst), .enb(en_y), .d(y_next), .q(y_reg));

    //acumulador de la division: save_x guarda |X|. Residuo = 0, cociente = |X|
    //en save_y o en_div_step entra el bit del cociente: 1 si cupo el divisor, 0 si no (y se regresa el residuo corrido)
    mux2 #(.DW(2*DW+1)) div_accumulator_step_mux (
        .sel(divisor_fits), .in1({adder_sum[DW:0], accumulator[DW-2:0], 1'b1}), .in0({shifted_remainder, accumulator[DW-2:0], 1'b0}), .out(div_accumulator_step)
    );
    mux2 #(.DW(2*DW+1)) div_accumulator_next_mux (
        .sel(save_x), .in1({filler, 1'b0, adder_sum[DW-1:0]}), .in0(div_accumulator_step), .out(div_accumulator_next)
    );

    //acumulador de la raiz: save_x lo limpia, en cada en_sqrt_step entra el residuo nuevo y el bit de la raiz
    mux2 #(.DW(2*DW+1)) sqrt_accumulator_next_mux (
        .sel(save_x), .in1('0), .in0({adder_sum[DW:0], root_result[DW-2:0], root_bit}), .out(sqrt_accumulator_next)
    );

    //Booth usa Product_d_w (ya trae el mux de Load)
    mux4 #(.DW(2*DW+1)) accumulator_next_mux (
        .sel(op_now), .in0(Product_d_w), .in1(div_accumulator_next), .in2(sqrt_accumulator_next), .in3(Product_d_w), .out(accumulator_next)
    );
    //en las 3 operaciones el acumulador cambia al cargar un operando o en cada vuelta
    assign en_accumulator = save_x | save_y | en_step;
    register_ar #(.DW(2*DW+1)) accumulator_register (.clk(clk), .rst(rst), .enb(en_accumulator), .d(accumulator_next), .q(accumulator));

    //salidas con error result y remainder valen -1
    //En la division Y = 0 o -512 / -1 es error, si no toma el cociente y el residuo ya con signo que salen del sumador
    mux2 #(.DW(DW)) div_result_mux    (.sel(div_error), .in1('1), .in0(adder_sum[DW-1:0]),    .out(div_result_next));
    mux2 #(.DW(DW)) div_remainder_mux (.sel(div_error), .in1('1), .in0(adder_sum[2*DW:DW+1]), .out(div_remainder_next));

    //En la raiz si X es negativo es error y no se hace la raiz
    mux2 #(.DW(DW)) sqrt_result_mux    (.sel(x_sign), .in1('1), .in0(root_result),       .out(sqrt_result_next));
    mux2 #(.DW(DW)) sqrt_remainder_mux (.sel(x_sign), .in1('1), .in0(adder_sum[DW-1:0]), .out(sqrt_remainder_next));

    mux4 #(.DW(DW)) result_next_mux    (.sel(op_now), .in0(Result_d),    .in1(div_result_next),    .in2(sqrt_result_next),    .in3(Result_d),    .out(result_next));
    mux4 #(.DW(DW)) remainder_next_mux (.sel(op_now), .in0(Remainder_d), .in1(div_remainder_next), .in2(sqrt_remainder_next), .in3(Remainder_d), .out(remainder_next));
    mux4 #(.DW(1))  error_next_mux     (.sel(op_now), .in0(Error_d),     .in1(div_error),          .in2(x_sign),              .in3(Error_d),     .out(error_next));

    //Booth guarda con capture y div/sqrt con en_write_result (la FSM los sube juntos en FIX)
    assign en_output = capture | en_write_result;
    register_ar #(.DW(DW)) result_register    (.clk(clk), .rst(rst), .enb(en_output), .d(result_next),    .q(result));
    register_ar #(.DW(DW)) remainder_register (.clk(clk), .rst(rst), .enb(en_output), .d(remainder_next), .q(remainder));
    register_ar #(.DW(1))  error_register     (.clk(clk), .rst(rst), .enb(en_output), .d(error_next),     .q(error));

endmodule
