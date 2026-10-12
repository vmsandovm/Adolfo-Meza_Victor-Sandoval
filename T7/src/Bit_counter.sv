module Bit_counter (
    input  logic clk, rst, en_bit_count, sample_count,
    output logic [2:0] bit_count
);

    always_ff @(posedge clk) begin
        if (rst == 1'b0)
            bit_count <= 3'b000;
        else if (en_bit_count == 1'b0)
            bit_count <= 3'b000;
        else if (sample_count == 1'b1)
            bit_count <= bit_count + 1'b1;
    end

endmodule