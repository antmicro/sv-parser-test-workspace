#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"

static vluint64_t main_time = 0;

double
sc_time_stamp()
{
	return main_time;
}

int
main(int argc, char** argv, char** env)
{
    Vtop *top = new Vtop;

	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	top->trace(tfp, 99);
	tfp->open("dump.vcd");

	top->clk = 0;
	top->resetn = 0;

	top->mem_rdata = 0x00000013; // nop instruction

	while (!Verilated::gotFinish() && (main_time < 3000)) {
		top->eval();
		tfp->dump(main_time);

		main_time += 1;
		if (main_time % 10 == 0)
			top->clk = !top->clk;

		if (main_time == 1000)
			top->resetn = 1;

		if (main_time == 1100)
			top->mem_ready = 1;

		if (top->mem_addr == 0x20)
			top->mem_rdata = 0x0000006f; // 1: j 1b
	}

	top->final();
	tfp->close();
    delete top;

	return 0;
}
