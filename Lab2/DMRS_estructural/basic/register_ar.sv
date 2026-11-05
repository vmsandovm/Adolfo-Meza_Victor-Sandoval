module register_ar #(parameter int DW = 10)(
    input  logic          clk, rst, enb,
    input  logic [DW-1:0] d,

    output logic [DW-1:0] q
);

    //registro con enable y reset asincrono (activo en bajo)
    //es el unico bloque secuencial del datapath estructural
    always_ff @(posedge clk or negedge rst) begin
        if (rst == 1'b0)
            q <= '0;
        else if (enb == 1'b1)
            q <= d;
    end

endmodule
