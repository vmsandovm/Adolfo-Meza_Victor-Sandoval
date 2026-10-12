module BR_counter #(parameter int CLK_CYCLES_PER_BIT)
(
    input  logic clk, rst, en_baud_count,
    output logic sample_count
);
    logic [5:0] baud_count; //conteo de ciclos

    always_ff @(posedge clk) begin
        if (rst == 1'b0)
            baud_count <= 6'b000000;
        else if (en_baud_count == 1'b0)
            baud_count <= 6'b000000;
        else if (baud_count == CLK_CYCLES_PER_BIT-1)
            baud_count <= 6'b000000;
        else
            baud_count <= baud_count + 1'b1;
    end
    
    assign sample_count = (baud_count == (CLK_CYCLES_PER_BIT >> 1));

endmodule