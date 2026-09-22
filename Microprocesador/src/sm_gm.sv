module sm_gm#(
    parameter DW=64
 
)(
    // clock and reset
    input clk,
    input rst,
 
    // Input data
    input [DW - 1 : 0] data0,
    input [DW - 1 : 0] data1,
    input square,
 
    // control
    input start,
    output logic ready,
 
    // Output data
    output logic [2 * DW - 1 : 0]result
);
 
signed int internal_result;
 
initial begin
    result = {DW{1'b0}};
    ready = 1'b1;
    wait(rst == 1'b1);
end
 
always begin
    wait(rst == 1'b1);
    wait(start == 1'b1);
    internal_result = (square == 1'b1)? $signed(data0) * $signed(data0) :
                        $signed(data0) * $signed(data1);
    @(posedge clk);
    ready = 1'b0;
    repeat(DW) @(posedge clk);
    result <= internal_result;
    ready <= 1'b1;
end
   
endmodule