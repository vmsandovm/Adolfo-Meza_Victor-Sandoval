/**********************************************************************************************
                         ITESO
Module: DMRS_datapath
Description:
    Realiza una iteracion por ciclo: decide sumar, restar o no operar segun Product[1:0], 
	 usa un sumador/restador y desplaza el producto a la derecha con extension de signo. 
	 Si Load esta activo, inicializa el producto con Multiplier_init.
    Parameters:
        - DW: Ancho del multiplicando y del multiplicador.
    Input:
        - Load: Inicializa producto con el multiplicador.
        - Multiplicand_init [DW-1:0]: Multiplicando sin signo extendido.
        - Multiplier_init [DW-1:0]: Multiplicador inicial, se carga en el producto.
        - Product [2*DW+1:0]: Producto actual (acumulador y multiplicador).
        - Multiplicand_r [DW:0] (signado): Multiplicando registrado, usado por el sumador/restador.
    Output:
        - Product_d_w [2*DW+1:0]: Valor a cargar en el registro del producto (Load o Product_next).
        - Multiplicand_extension_w [DW:0] (signed): Multiplicando extendido un bit con signo.
        - Product_next [2*DW+1:0]: Producto despues de una iteracion Booth.
    Owner: Victor Manuel Sandoval Maciel
    Date: 21/10/2026
**********************************************************************************************/
module DMRS_datapath #( parameter int DW = 5
)(
    input  logic              Load,
    input  logic [DW-1:0]     Multiplicand_init,
    input  logic [DW-1:0]     Multiplier_init,
    input  logic [2*DW+1:0]         Product,
    input  logic signed [DW:0]      Multiplicand_r,

    output logic [2*DW+1:0]         Product_d_w,
    output logic signed [DW:0]      Multiplicand_extension_w,
    output logic [2*DW+1:0]         Product_next
);

    logic Accumulate_w;
    logic Subtract_w;

// Nodos del unico sumador/restador que tiene el multiplicador
    logic signed [DW:0] Accumulator_w;
    logic signed [DW:0] Adder_result_w;
    logic signed [DW:0] Accumulator_next_w;

    logic signed [2*DW+1:0] Product_pre_shift_w;

    assign Accumulator_w = Product[2*DW+1 : DW+1];

// La extension a DW+1 bits debe repetir el bit de signo, no rellenar con ceros
    assign Multiplicand_extension_w = { Multiplicand_init[DW-1], Multiplicand_init };

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
// 0 = A + B
// 1 = A - B
    Sumador_Restador #( .DW(DW+1) ) Booth_adder (
        .a(Accumulator_w),
        .b(Multiplicand_r),
        .sel(Subtract_w),
        .Result(Adder_result_w)
    );

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

// Load inicializa el producto con el multiplicador. Si no, avanza una iteracion.
// El enable del registro (en el top) decide cuando se captura.
    always_comb begin
        if (Load) begin
            Product_d_w = { {(DW+1){1'b0}}, Multiplier_init, 1'b0 };
        end
        else begin
            Product_d_w = Product_next;
        end
    end

endmodule