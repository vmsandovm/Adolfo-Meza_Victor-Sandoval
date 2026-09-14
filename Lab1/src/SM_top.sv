module SM_top #( parameter int DW = 5
)(
    input  logic       CLOCK_50,
    input  logic [3:0] KEY,
    input  logic [9:0] SW,

    output logic       Ready,
    output logic [6:0] HEX0,
    output logic [6:0] HEX1,
    output logic [6:0] HEX2,
    output logic [6:0] HEX3
);

    logic Clock_5MHz_w;
    logic PLL_locked_w;

// KEY[1] es el reset: los botones de la tarjeta entregan cero al presionarse, que
// es justo lo que espera el multiplicador. El PLL la toma invertida.
    PLL_50MHz_a_5MHz Clock_generator (
        .refclk   (CLOCK_50),
        .rst      (~KEY[1]),
        .outclk_0 (Clock_5MHz_w),
        .locked   (PLL_locked_w)
    );

// El multiplicador se mantiene en reset mientras el PLL no haya entrado.
// Se asierta de forma asincrona y se libera sincronizado a los 5 MHz
    logic       Reset_negated_wire;
    logic [1:0] Reset_sync_register;
    logic       Clean_reset_negated_wire;

    assign Reset_negated_wire = KEY[1] & PLL_locked_w;

    always_ff @(posedge Clock_5MHz_w or negedge Reset_negated_wire) begin
        if (Reset_negated_wire == 1'b0) begin
            Reset_sync_register <= 2'b00;
        end
        else begin
            Reset_sync_register <= {Reset_sync_register[0], 1'b1};
        end
    end

    assign Clean_reset_negated_wire = Reset_sync_register[1];

// Los botones se mantienen activos mientras se sostienen. 
    logic [1:0] Start_sync_register;
    logic       Start_previous_register;
    logic       Start_pulse_wire;

    always_ff @(posedge Clock_5MHz_w or negedge Clean_reset_negated_wire) begin
        if (Clean_reset_negated_wire == 1'b0) begin
            Start_sync_register     <= 2'b00;
            Start_previous_register <= 1'b0;
        end
        else begin
            Start_sync_register     <= {Start_sync_register[0], ~KEY[0]};
            Start_previous_register <= Start_sync_register[1];
        end
    end

    assign Start_pulse_wire = Start_sync_register[1] & ~Start_previous_register;

    Sequential_multiplier #( .DW(DW)
    ) Core (
        .Clock  (Clock_5MHz_w),
        .Reset  (Clean_reset_negated_wire),
        .Start  (Start_pulse_wire),
        .Square (~KEY[2]),
        .Data0  (SW[DW-1:0]),
        .Data1  (SW[(2*DW)-1:DW]),

        .Ready  (Ready),
        .Result (),
        .HEX0   (HEX0),
        .HEX1   (HEX1),
        .HEX2   (HEX2),
        .HEX3   (HEX3)
    );

endmodule
