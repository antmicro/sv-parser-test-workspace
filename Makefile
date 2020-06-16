VIVADO = /opt/Xilinx/Vivado/2019.2

.PHONY: ibex/prep

all:
	@true

clean::
	rm -f top.log
	rm -f sv2v.v top_artya7.edf
	rm -f usage_statistics_webtalk.xml usage_statistics_webtalk.html

distclean:: clean
	rm -rf venv
	(cd ibex && git clean -xdf && git reset --hard HEAD)
	(cd yosys && git clean -xdf && git reset --hard HEAD)
	rm -rf sv2v-Linux
	rm -f sv2v-Linux.zip

yosys/yosys:
	(cd yosys && make -j`nproc`)

sv2v-Linux.zip:
	wget -c https://github.com/zachjs/sv2v/releases/download/v0.0.3/sv2v-Linux.zip -O $@ && touch $@

sv2v-Linux/sv2v: sv2v-Linux.zip
	unzip $< && touch $@

# ---------------------------------------------------
venv/bin/activate:
	virtualenv venv

venv/.fusesoc: venv/bin/activate
	( . $< ; pip3 install fusesoc ) && touch $@

# ---------------------------------------------------
ibex/.checkout:
	(cd ibex && git checkout 4814b6776f1623ec08823b228f8479d7874bf043) && touch $@

ibex/.patch: ibex/.checkout $(PWD)/ibex.patch
	(cd ibex && patch -Np1 < $(word 2,$^)) && touch $@

ibex/build/lowrisc_ibex_top_artya7_0.1/synth-vivado/Makefile: venv/.fusesoc ibex/.patch
	( \
		. venv/bin/activate ; \
		cd ibex && \
			fusesoc --cores-root=. \
			run --target=synth --setup lowrisc:ibex:top_artya7 --part xc7a35ticsg324-1L \
	)

ibex/prep: ibex/build/lowrisc_ibex_top_artya7_0.1/synth-vivado/Makefile

# ------------------------------------------------------------------------------
sv2v.v: \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_pkg_0.1/rtl/ibex_pkg.sv \
		\
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_alu.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_fetch_fifo.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_cs_registers.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_pmp.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_core.sv \
		\
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_icache_0.1/rtl/ibex_icache.sv
	./sv2v-Linux/sv2v \
		-Iibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_prim_assert_0.1/rtl \
		-DSRAM_INIT_FILE=./ibex/examples/sw/led/led.vmem \
		$^ > $@

top_artya7.edf: \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_pkg_0.1/rtl/ibex_pkg.sv \
		\
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_compressed_decoder.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_controller.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_counters.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_decoder.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_ex_block.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_id_stage.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_if_stage.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_load_store_unit.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_multdiv_fast.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_multdiv_slow.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_prefetch_buffer.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_register_file_fpga.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_ibex_core_0.1/rtl/ibex_wb_stage.sv \
		\
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_prim_secded_0.1/rtl/prim_secded_28_22_dec.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_prim_secded_0.1/rtl/prim_secded_28_22_enc.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_prim_secded_0.1/rtl/prim_secded_72_64_dec.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_prim_secded_0.1/rtl/prim_secded_72_64_enc.sv \
		\
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_prim_generic_ram_1p_0/rtl/prim_generic_ram_1p.sv \
		\
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_fpga_xilinx_shared_0/rtl/fpga/xilinx/prim_clock_gating.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_fpga_xilinx_shared_0/rtl/fpga/xilinx/clkgen_xil7series.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_fpga_xilinx_shared_0/rtl/fpga/xilinx/clkgen_xil7series.sv \
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_fpga_xilinx_shared_0/rtl/ram_1p.sv \
		\
		./ibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_ibex_top_artya7_0.1/rtl/top_artya7.sv \
		\
		sv2v.v
	./yosys/yosys \
		-p 'read_verilog -sv -Iibex/build/lowrisc_ibex_top_artya7_0.1/src/lowrisc_prim_assert_0.1/rtl $^' \
		-p 'synth_xilinx -iopad -family xc7' \
		-p 'write_edif -pvector bra $@'

top/build: \
		ibex/build/lowrisc_ibex_top_artya7_0.1/synth-vivado/Makefile \
		sv2v-Linux/sv2v yosys/yosys \
		build.tcl top_artya7.edf
	( \
		. $(VIVADO)/settings64.sh ; \
		vivado -nojournal -log top.log -mode batch -source build.tcl ; \
	)
