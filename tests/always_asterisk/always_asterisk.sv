module top (
	input c,
	input d,
	output q
);

always @*
begin
	q = c & d;
end

endmodule
