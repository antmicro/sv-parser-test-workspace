#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"
#include <cstdio>
#include <cassert>
#include <iostream>

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

	FILE *mem = fopen("mem.bin", "r");

	bool keep_going = true;
	while (!Verilated::gotFinish() && (main_time < 3000) && keep_going) {
		top->eval();
		tfp->dump(main_time);

		main_time += 1;
		if (main_time % 10 == 0)
			top->clk = !top->clk;

		if (main_time == 300)
			top->resetn = 1;

		if (mem) {
			top->mem_ready = 0;
			if (top->mem_valid) {
				if (top->mem_instr) {
					int rc = fseek(mem, top->mem_addr, SEEK_SET);
					assert(rc == 0);
					top->mem_rdata = 0x0;
					rc = fread(&top->mem_rdata, 4, 1, mem);
					if (rc == 1)
						top->mem_ready = 1;
				} else {
					switch (top->mem_addr) {
					case 0xa0:
						if ( (top->mem_wstrb == 0xf) && (top->mem_wdata == 0x55) ) {
							std::cout << "End simulation" << std::endl;
							keep_going = false;
						}
						break;
					}
				}
			}
		} else {
			if (main_time == 600)
				top->mem_ready = 1;

			if (top->mem_addr == 0x0)
				top->mem_rdata = 0x13; // nop

			if (top->mem_addr == 0x20)
				top->mem_rdata = 0x0000006f; // 1: j 1b

			// j -20, jumps to address 0x0
			//if (top->mem_addr == 20) top->mem_rdata = 0xfedff06f;
		}
	}

	if (mem)
		fclose(mem);

	top->final();
	tfp->close();
    delete top;

	return 0;
}
