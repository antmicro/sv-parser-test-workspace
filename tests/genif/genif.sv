module top #(
	parameter [0:0] ENABLE_SWAP = 0
) (
	input c,
	input  [1:0] d,
	output [1:0] q
);

//reg [1:0] t = 2'b10;
reg [1:0] t; initial t = 2'b10;

generate if (ENABLE_SWAP) begin
	always @(posedge c)
	begin
		t[0] <= d[1];
		t[1] <= d[0];
	end
end else begin
	always @(posedge c)
	begin
		t[0] <= d[0];
		t[1] <= d[1];
	end
end endgenerate

assign q = t;

endmodule
