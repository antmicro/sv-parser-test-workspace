module top #(
	parameter XOR_VALUE = 1'b0,
	parameter OR_VALUE  = 1'b0,
	parameter AND_VALUE = 1'b1
) (
	input c,
	input d,
	output q
);

//`define NEG_OUTPUT

//reg t = 1'b0;
reg t; initial t = 1'b0;

always @(posedge c)
	t <= ((d ^ XOR_VALUE) | OR_VALUE) & AND_VALUE;

`ifdef NEG_OUTPUT
assign q = ~t;
`else
assign q = t;
`endif

endmodule
