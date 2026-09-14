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

    logic                     Operate_w;
    logic                     Sub_w;

// Nodos del unico sumador/restador que tiene el multiplicador
    logic signed [DW:0]       Acc_w;
    logic signed [DW:0]       Addend_w;
    logic signed [DW:0]       Addsub_w;
    logic signed [DW:0]       Acc_op_w;

    logic signed [2*DW+1:0]   Product_pre_shift_w;
    logic        [2*DW+1:0]   Product_d_w;

    assign Acc_w = Product[2*DW+1 : DW+1];

// Booth decide en funcion de los dos bits inferiores, Q(0) y Q(-1):
//    01 -> termina una cadena de unos -> sumar el multiplicando
//    10 -> empieza una cadena de unos -> restar el multiplicando
//    00 y 11 -> la cadena continua, el acumulador se queda igual
    always_comb begin
        case (Product[1:0])
            2'b01:   begin Operate_w = 1'b1; Sub_w = 1'b0; end
            2'b10:   begin Operate_w = 1'b1; Sub_w = 1'b1; end
            default: begin Operate_w = 1'b0; Sub_w = 1'b0; end
        endcase
    end

// Un solo sumador resuelve las dos operaciones. La resta se hace en complemento a
// 2: se invierte el multiplicando y el propio Sub_w entra como acarreo inicial,
// de manera que A - M se calcula como A + (~M) + 1.
    assign Addend_w = Sub_w ? ~Multiplicand_r : Multiplicand_r;
    assign Addsub_w = Acc_w + Addend_w + Sub_w;

// Cuando Booth no opera se descarta la salida del sumador con este mux, en vez de
// agregar una segunda unidad aritmetica
    assign Acc_op_w = Operate_w ? Addsub_w : Acc_w;

// Al recorrer a la derecha se repite el bit de signo en lugar de introducir un
// cero. Con un desplazamiento logico fallarian todos los casos negativos, y solo
// resulta aritmetico porque Product_pre_shift_w esta declarado signed.
    assign Product_pre_shift_w = { Acc_op_w, Product[DW:0] };
    assign Product_next        = Product_pre_shift_w >>> 1;

    always_comb begin
        if (Load) begin
            Product_d_w = { {(DW+1){1'b0}}, Multiplier_init, 1'b0 };
        end
        else if (Iterate) begin
            Product_d_w = Product_next;
        end
        else begin
            Product_d_w = Product;
        end
    end

// Reset asincrono y activo bajo
    always_ff @(posedge Clock or negedge Reset) begin
        if (Reset == 1'b0) begin
            Multiplicand_r <= '0;
            Product        <= '0;
        end
        else begin
// $signed obliga a que la extension a DW+1 bits repita el bit de signo
            if (Load) begin
                Multiplicand_r <= $signed(Multiplicand_init);
            end
            Product <= Product_d_w;
        end
    end

endmodule