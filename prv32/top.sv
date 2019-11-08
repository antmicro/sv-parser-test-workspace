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


picorv32 #(
	.ENABLE_COUNTERS		(0),
	.ENABLE_COUNTERS64		(0),
	.ENABLE_REGS_16_31		(0),
	.ENABLE_REGS_DUALPORT	(0),
	.LATCHED_MEM_RDATA		(0),
	.TWO_STAGE_SHIFT		(1),
	.BARREL_SHIFTER			(0),
	.TWO_CYCLE_COMPARE		(1),
	.TWO_CYCLE_ALU			(1),
	.COMPRESSED_ISA			(0),
	.CATCH_MISALIGN			(0),
	.CATCH_ILLINSN			(0),
	.ENABLE_PCPI			(0),
	.ENABLE_MUL				(0),
	.ENABLE_FAST_MUL		(0),
	.ENABLE_DIV				(0),
	.ENABLE_IRQ				(0),
	.ENABLE_IRQ_QREGS		(0),
	.ENABLE_IRQ_TIMER		(0),
	.ENABLE_TRACE			(0),
	.REGS_INIT_ZERO			(0),
	.MASKED_IRQ				(32'h 0000_0000),
	.LATCHED_IRQ			(32'h ffff_ffff),
	.PROGADDR_RESET			(32'h 0000_0000),
	.PROGADDR_IRQ			(32'h 0000_0010),
	.STACKADDR				(32'h ffff_ffff)
) picorv32_core (
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
