module top (
	input c,
	input d,
	output [3:0] q
);

assign q = { { c, 1'b0 }, { d }, 1'b1 };

endmodule
