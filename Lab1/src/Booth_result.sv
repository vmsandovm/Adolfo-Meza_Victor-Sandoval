module Booth_result #( parameter int DW
)(
    input  logic              Clock,
    input  logic              Reset,
    input  logic              Capture,
    input  logic [(2*DW)+1:0]   Product,

    output logic [(2*DW)-1:0]   Result
);

// El registro Product del datapath lleva un bit de mas por arriba y el bit Q(-1)
// de Booth por abajo. El producto util son los 2*DW bits centrales, que equivalen
// al "result = product_temporal >> 1" del pseudocodigo de la especificacion.
//
// Con Capture en cero se conserva el valor anterior, porque la especificacion pide
// que Result permanezca estable mientras la operacion sigue en curso.

    always_ff @(posedge Clock or negedge Reset) begin
        if (Reset == 1'b0) begin
            Result <= '0;
        end
        else if (Capture) begin
            Result <= Product[2*DW : 1];
        end
    end

endmodule