module top (
	input c,
	input [1:0] d,
	output [1:0] q
);

always @(posedge c)
begin
	case (d)
	2'b00: q <= 2'b11;
	2'b01: q <= 2'b10;
	2'b10: q <= 2'b01;
	2'b11: q <= 2'b00;
	default: q <= 2'b00;
	endcase
end

endmodule
