module mux2 #(parameter int DW = 10)(
    input  logic [DW-1:0] in0, in1,
    input  logic          sel,

    output logic [DW-1:0] out
);

    //sel = 0 pasa in0, sel = 1 pasa in1
    assign out = sel ? in1 : in0;

endmodule
