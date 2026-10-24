/**********************************************************************************************
                         ITESO                            
Module: Tx_Frame                                   
Description: 
    Wrap del frame .Coloca los bits de start, datos y stop segun las senales de control de la FSM.
    Input: 
        - Input: Bus paralelo de datos [DW-1:0] para calculo de paridad.                                              
        - Clk: Clk del sistema.
        - Reset: Reset activo en bajo (0 = Reset).
        - Data: Bit de datos serial proveniente del PISO.
        - Start_control: senal que ordena insertar el start bit (Se activa en 0).
        - Parity_control: Proximamente. Este habilita el uso de Parity bit
    Output:                                              
        - Output: salida del proyecto uart tx.
    Owner: Victor Manuel Sandoval Maciel                       
    Date: 28/09/2026                                           
**********************************************************************************************/

module Tx_Frame #( parameter DW )(
	input logic [DW-1:0] Input,
	input logic Reset,
	input logic Data,
	input logic Parity_control,
	input logic Start_control,
	input logic Data_control,

	output logic Output
);

// Odd = ~^Input;
// Even = ^Input 
	wire Parity_bit = ~^Input; 
	
	always_comb begin
		if(Reset==1'b0) begin
			Output = 1'b1;
		end else begin
			if (Start_control) begin				// Bit de inicio		
				Output = 1'b0;         
			end else if (Data_control==1'b1) begin		// El datos durante CLKS_PER_BIT ciclos			
				Output = Data;
			end else if (Parity_control==1'b1) begin	// Bit de paridad         
					Output = Parity_bit;    
			end else begin
				Output = 1'b1;         
			end
		end	
	end
	
endmodule