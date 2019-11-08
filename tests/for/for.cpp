#include <verilated.h>
#include <verilated_vcd_c.h>
#include "V%TOP_MODULE%.h"

static vluint64_t main_time = 0;

double
sc_time_stamp()
{
	return main_time;
}

int
main(int argc, char** argv, char** env)
{
    V%TOP_MODULE% *top = new V%TOP_MODULE%;

	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	top->trace(tfp, 99);
	tfp->open("dump.vcd");

 	top->c = 0;
	top->d = 0;
	top->sel = 0;
	top->wr = 0;

	while (!Verilated::gotFinish() && (main_time < 100)) {
		top->eval();
		tfp->dump(main_time);

		main_time += 1;
		if (main_time % 10 == 0)
			top->c = !top->c;

		if (main_time == 12)
			top->d = 1;

		if (main_time == 66)
			top->d = 0;

		switch (main_time) {
		case 22:
			top->d = 0xdeadbeef;
			top->wr = 1;
			break;

		case 32:
			top->wr = 0;
			break;

		case 48:
			top->sel = 2;
			top->wr = 1;
			top->d = 0x0badc0de;
			break;

		case 52:
			top->wr = 0;
			break;

		case 63:
			top->sel = 0;
			break;
		}
	}

	top->final();
	tfp->close();
    delete top;

	return 0;
}
