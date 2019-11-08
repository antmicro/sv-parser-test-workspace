module top (
	input         c,
	input   [4:0] sel,
	input         wr,
	input  [31:0] d,
	output [31:0] q
);

localparam integer regfile_size = 32;
reg [31:0] cpuregs [0:regfile_size-1];

always @(posedge c)
begin
	if (wr)
		cpuregs[sel] <= d;
end

assign q = cpuregs[sel];

endmodule
