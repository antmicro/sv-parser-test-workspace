module top (
	input c,
	input [1:0] d,
	output q
);

wire q_a, q_b;

dff dff_a (.c(c), .d(d[0]), .q(q_a));
dff dff_b (.c(c), .d(d[1]), .q(q_b));

assign q = q_a & q_b;

endmodule

module dff (
	input c,
	input d,
	output q
);

reg t; initial t = 1'b0;

always @(posedge c)
begin
	t <= d;
end

assign q = t;

endmodule
