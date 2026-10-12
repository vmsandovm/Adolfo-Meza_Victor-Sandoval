module Parity_error #(
    parameter string PARITY_TYPE = "ODD",
    parameter int DW             = 8
)(
	input logic [DW-1:0] Data_out, 
    input logic en_parity, parity_bit,
	output logic parity_error
);

    logic calculated_parity;

    always_comb begin
        if (PARITY_TYPE == "EVEN")
            calculated_parity = ^Data_out;  //EVEN
        else
            calculated_parity = ~^Data_out; //ODD

        if (en_parity == 1'b0)
            parity_error = 1'b0;
        else
            if (calculated_parity != parity_bit)
                parity_error = 1'b1;
            else
                parity_error = 1'b0;
    end

endmodule