/**********************************************************************************************
	                         ITESO
Package: MDRS_pkg
Description:
	Codigos de operacion del MDRS.
Owner: Victor Manuel Sandoval Maciel
Date: 25/10/2026
**********************************************************************************************/
package MDRS_pkg;
	typedef enum logic [1:0] {
		OP_MULT   = 2'd0,
		OP_DIV    = 2'd1,
		OP_SQRT   = 2'd2,
		OP_SQUARE = 2'd3
	} mdrs_op_t;
endpackage
