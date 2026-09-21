module Booth_datapath #( parameter int DW = 5
)(
    input  logic              Clock,
    input  logic              Reset,
    input  logic              Load,
    input  logic              Iterate,
    input  logic [DW-1:0]     Multiplicand_init,
    input  logic [DW-1:0]     Multiplier_init,

    output logic [2*DW+1:0]   Product,
    output logic [2*DW+1:0]   Product_next
);

// Distribucion de bits de Product (2*DW+2 bits en total):
//    [2*DW+1 : DW+1]  acumulador A, con signo. Lleva DW+1 bits y no DW porque
//                     -2^(DW-1) al cuadrado se desbordaria con DW bits.
//    [DW:1]           multiplicador Q, que se recorre a la derecha en cada paso
//    [0]              Q(-1), el bit auxiliar que Booth necesita para arrancar
// El producto final son los 2*DW bits centrales: Product[2*DW : 1]

    logic signed [DW:0]       Multiplicand_r;
    logic signed [DW:0]       Multiplicand_extension_w;

    logic                     Accumulate_w;
    logic                     Subtract_w;

// Nodos del unico sumador/restador que tiene el multiplicador
    logic signed [DW:0]       Accumulator_w;
    logic signed [DW:0]       Adder_operand_w;
    logic signed [DW:0]       Adder_result_w;
    logic signed [DW:0]       Accumulator_next_w;

    logic signed [2*DW+1:0]   Product_pre_shift_w;
    logic        [2*DW+1:0]   Product_d_w;

    assign Accumulator_w = Product[2*DW+1 : DW+1];

// La extension a DW+1 bits debe repetir el bit de signo, no rellenar con ceros
    assign Multiplicand_extension_w = $signed(Multiplicand_init);

// Booth decide en funcion de los dos bits inferiores, Q(0) y Q(-1):
//    01 -> termina una cadena de unos -> sumar el multiplicando
//    10 -> empieza una cadena de unos -> restar el multiplicando
//    00 y 11 -> la cadena continua, el acumulador se queda igual
    always_comb begin
        case (Product[1:0])
            2'b01:   begin Accumulate_w = 1'b1; Subtract_w = 1'b0; end
            2'b10:   begin Accumulate_w = 1'b1; Subtract_w = 1'b1; end
            default: begin Accumulate_w = 1'b0; Subtract_w = 1'b0; end
        endcase
    end

// Un solo sumador resuelve las dos operaciones. La resta se hace en complemento a
// 2: se invierte el multiplicando y el propio Subtract_w entra como acarreo
// inicial, de manera que A - M se calcula como A + (~M) + 1.
    always_comb begin
        if (Subtract_w) begin
            Adder_operand_w = ~Multiplicand_r;
        end
        else begin
            Adder_operand_w = Multiplicand_r;
        end
    end

    assign Adder_result_w = Accumulator_w + Adder_operand_w + Subtract_w;

// Cuando Booth no opera se descarta la salida del sumador con este mux, en vez de
// agregar una segunda unidad aritmetica
    always_comb begin
        if (Accumulate_w) begin
            Accumulator_next_w = Adder_result_w;
        end
        else begin
            Accumulator_next_w = Accumulator_w;
        end
    end

// Al recorrer a la derecha se repite el bit de signo para no introducir un
// cero. Con un desplazamiento logico fallarian todos los casos negativos, y solo
// resulta aritmetico porque Product_pre_shift_w esta declarado signed.
    assign Product_pre_shift_w = { Accumulator_next_w, Product[DW:0] };
    assign Product_next        = Product_pre_shift_w >>> 1;

// El enable del registro sustituye a la rama que antes reasignaba Product consigo
// mismo cuando no habia nada que hacer
    always_comb begin
        if (Load) begin
            Product_d_w = { {(DW+1){1'b0}}, Multiplier_init, 1'b0 };
        end
        else begin
            Product_d_w = Product_next;
        end
    end

    PIPO_register #( .DW(2*DW+2)
    ) Product_reg (
        .Clock(Clock),
        .Reset(Reset),
        .Enable(Load | Iterate),
        .Data_in(Product_d_w),

        .Data_out(Product)
    );

    PIPO_register #( .DW(DW+1)
    ) Multiplicand_reg (
        .Clock(Clock),
        .Reset(Reset),
        .Enable(Load),
        .Data_in(Multiplicand_extension_w),

        .Data_out(Multiplicand_r)
    );

endmodule