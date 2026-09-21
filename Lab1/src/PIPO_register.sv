module PIPO_register #( parameter int DW = 8
)(
    input  logic          Clock,
    input  logic          Reset,
    input  logic          Enable,
    input  logic [DW-1:0] Data_in,

    output logic [DW-1:0] Data_out
);

    always_ff @(posedge Clock or negedge Reset) begin
        if (Reset == 1'b0) begin
            Data_out <= '0;
        end
        else if (Enable) begin
            Data_out <= Data_in;
        end
    end

endmodule