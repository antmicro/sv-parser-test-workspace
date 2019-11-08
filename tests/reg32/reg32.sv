module top (
	input         c,
	input         d,
	output [31:0] q
);

reg [31:0] t; initial t = 32'h0;

always @(posedge c)
begin
	if (d)
		t <= t + 5;

	t[1:0] <= 0;
end

assign q = t;

endmodule
