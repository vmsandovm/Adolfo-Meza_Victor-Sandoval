module Mux2to1_mod #( parameter int DW
)(
    input logic [DW-1:0] Input0,
    input logic [DW-1:0] Input1,
    input logic Sel,

    output logic [DW-1:0] Output_fixed,
    output logic [DW-1:0] Output2
);
// Salida Data0 fija        
    assign Output_fixed = Input0;

// Square define la segunda salida, en caso de ser 
//    Sel==1: DATA0*DATA0
//    Sel==0: DATA0*DATA1
    always_comb begin
        if (Sel == 1'b1) begin
            Output2 = Input0;
        end
        else begin
            Output2 = Input1;
        end
    end
endmodule