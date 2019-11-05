module top (
	input             clk,
	input             resetn,

	output            mem_valid,
	output            mem_instr,
	input             mem_ready,

	output reg [31:0] mem_addr,
	output reg [31:0] mem_wdata,
	output reg [ 3:0] mem_wstrb,
	input      [31:0] mem_rdata
);


picorv32 picorv32_core (
	.clk(clk),
	.resetn(resetn),
	.trap(),

	.mem_valid(mem_valid),
	.mem_instr(mem_instr),
	.mem_ready(mem_ready),
	.mem_addr(mem_addr),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata),

	.mem_la_read(),
	.mem_la_write(),
	.mem_la_addr(),
	.mem_la_wdata(),
	.mem_la_wstrb(),

	.pcpi_valid(),
	.pcpi_insn(),
	.pcpi_rs1(),
	.pcpi_rs2(),
	.pcpi_wr(1'b0),
	.pcpi_rd(32'h00000000),
	.pcpi_wait(1'b0),
	.pcpi_ready(1'b0),

	.irq(32'h00000000),
	.eoi(),

	.trace_valid(),
	.trace_data()
);

endmodule
