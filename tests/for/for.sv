module top (
	input         c,
    input   [2:0] sel, /* sel */
    input         wr,
	input  [31:0] d,
	output [31:0] q
);

reg [31:0] mem [7:0];

integer i;
initial begin
	for (i = 0 ; i < 8 ; i = i + 1)
	begin
		mem[i] = 32'hdeadbeef;
	end
end

always @(posedge c)
begin
	if (wr)
	begin
        mem[sel] <= d;
	end
end

assign q = mem[sel];

endmodule
