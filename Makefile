VIVADO = /opt/Xilinx/Vivado/2019.2

.PHONY: ibex/prep

all:
	@true

clean::
	rm -f top.log yosys.log
	rm -f top_artya7.edf
	rm -f usage_statistics_webtalk.xml usage_statistics_webtalk.html

distclean:: clean
	rm -rf venv
	(cd ibex && git clean -xdf && git reset --hard HEAD)
	(cd yosys && git clean -xdf && git reset --hard HEAD)
	rm -f top.bit

yosys/yosys:
	(cd yosys && make -j`nproc`)

# ---------------------------------------------------
venv/bin/activate:
	virtualenv venv

venv/.fusesoc: venv/bin/activate ibex/.patch
	( . $< ; pip3 install -r $(PWD)/ibex/python-requirements.txt ) && touch $@

# ---------------------------------------------------
ibex/.patch: $(PWD)/ibex.patch
	(cd ibex && patch -Np1 < $<) && touch $@

ibex/build/lowrisc_ibex_top_artya7_0.1/synth-vivado/Makefile: venv/.fusesoc ibex/.patch
	( \
		. venv/bin/activate ; \
		cd ibex && \
			fusesoc --cores-root=. \
			run --target=synth --setup lowrisc:ibex:top_artya7 --part xc7a35ticsg324-1L \
	)

ibex/prep: ibex/build/lowrisc_ibex_top_artya7_0.1/synth-vivado/Makefile

# ------------------------------------------------------------------------------
IBEX_BUILD = ibex/build/lowrisc_ibex_top_artya7_0.1

IBEX_INCLUDE = \
	-I$(IBEX_BUILD)/src/lowrisc_prim_assert_0.1/rtl \
	-I$(IBEX_BUILD)/src/lowrisc_prim_util_memload_0/rtl \

IBEX_PKG_SOURCES = \
	$(shell \
		cat ibex/build/lowrisc_ibex_top_artya7_0.1/synth-vivado/lowrisc_ibex_top_artya7_0.1.tcl | \
		grep read_verilog | cut -d' ' -f3  | grep _pkg.sv | \
		sed 's@^..@ibex/build/lowrisc_ibex_top_artya7_0.1@')

IBEX_SOURCES = \
	$(IBEX_PKG_SOURCES) \
	$(shell \
		cat ibex/build/lowrisc_ibex_top_artya7_0.1/synth-vivado/lowrisc_ibex_top_artya7_0.1.tcl | \
		grep read_verilog | cut -d' ' -f3 | grep -v _pkg.sv | \
		sed 's@^..@ibex/build/lowrisc_ibex_top_artya7_0.1@')

top_artya7.edf: $(IBEX_SOURCES)
	./yosys/yosys \
		-p 'read_verilog -DSRAM_INIT_FILE=led.vmem -sv $(IBEX_INCLUDE) $^' \
		-p 'synth_xilinx -iopad -family xc7' \
		-p 'write_edif -pvector bra $@' \
		-l yosys.log

top/build: \
		ibex/build/lowrisc_ibex_top_artya7_0.1/synth-vivado/Makefile \
		yosys/yosys \
		build.tcl top_artya7.edf
	( \
		. $(VIVADO)/settings64.sh ; \
		vivado -nojournal -log top.log -mode batch -source build.tcl ; \
	)
