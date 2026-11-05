module mux4 #(parameter int DW = 10)(
    input  logic [DW-1:0] in0, in1, in2, in3,
    input  logic [1:0]    sel,

    output logic [DW-1:0] out
);

    logic [DW-1:0] low_pair, high_pair;

    //se arma con 3 mux2: sel[0] escoge dentro de cada par y sel[1] escoge el par
    mux2 #(.DW(DW)) mux_low  (.in0(in0),      .in1(in1),       .sel(sel[0]), .out(low_pair));
    mux2 #(.DW(DW)) mux_high (.in0(in2),      .in1(in3),       .sel(sel[0]), .out(high_pair));
    mux2 #(.DW(DW)) mux_out  (.in0(low_pair), .in1(high_pair), .sel(sel[1]), .out(out));

endmodule
