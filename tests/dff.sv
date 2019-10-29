module top (
	input c,
	input d,
	output q
);

// Yosys generates this as AST_ASSIGN_LE (non-blocking)
//reg t = 1'b0;

// Yosys generates this as AST_ASSIGN_EQ (blocking)
reg t; initial t = 1'b0;

always @(posedge c)
begin
	t <= d;
end

assign q = t;

endmodule
