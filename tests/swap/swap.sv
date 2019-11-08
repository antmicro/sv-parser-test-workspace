module top (
	input c,
	input  [1:0] d,
	output [1:0] q
);

//reg [1:0] t = 2'b10;
reg [1:0] t; initial t = 2'b10;

always @(posedge c)
begin
	t[0] <= d[1];
	t[1] <= d[0];
end

assign q = t;

endmodule
