module top (
	input c,
	input d,
	output q
);

//reg t = 1'b0;
reg t; initial t = 1'b0;

always @(posedge c)
	t <= d;

assign q = ~t;

endmodule
