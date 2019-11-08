module top (
	input c,
	input d,
	output [1:0] q
);

localparam integer sel = 0;
reg [1:0] t; initial t = 2'b00;

always @(posedge c)
begin
	t[sel] <= d;
end

assign q = t;

endmodule
