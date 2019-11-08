TESTS = $(shell find tests -name *.sv | cut -d\/ -f2 | sort)

QUIET ?= @

all:
	@echo "Availble tests: $(TESTS)"

verilator/configure: verilator/configure.ac
	(cd verilator && autoconf)

verilator/Makefile: verilator/configure
	(cd verilator && ./configure --prefix=$(PWD)/image)

verilator/bin/verilator_bin: verilator/Makefile
	(cd verilator && make -j`nproc`)

image/bin/verilator: verilator/bin/verilator_bin
	(cd verilator && make install)

yosys/yosys: yosys/Makefile
	(cd yosys && make -j`nproc`)

prep: image/bin/verilator yosys/yosys

clean::
	rm -rf build

vcd:
	gtkwave build/dump.vcd &>/dev/null &

VERILATOR = ./image/bin/verilator
YOSYS = ./yosys/yosys

define template
$(1)-sv: tests/$(1)/$(1).sv tests/$(1)/$(1).cpp
	rm -rf build
	$(VERILATOR) \
		--trace --cc --exe -Mdir build \
		$$< sim.cpp
	cat tests/$(1)/$(1).cpp | sed 's/%TOP_MODULE%/$(1)/g' > build/sim.cpp
	make -C build -f V$(1).mk
	(cd build && ./V$(1))

$(1)-sv-xml: tests/$(1)/$(1).sv
	rm -rf build
	$(VERILATOR) --cc --xml-only -Mdir build $$<

$(1)-ast: tests/$(1)/$(1).sv tests/$(1)/$(1).cpp
	rm -rf build
	mkdir build
	(cd build && ../$(YOSYS) -p \
		'read_verilog -dump_ast1 ../tests/$(1)/$(1).sv')
	./merge.py build/ast.json build/*.json
	$(VERILATOR) \
		--trace --cc --exe -Mdir build \
		--top-module top \
		-Wno-CASEINCOMPLETE \
		--json-ast build/ast.json sim.cpp
	cat tests/$(1)/$(1).cpp | sed 's/%TOP_MODULE%/top/g' > build/sim.cpp
	make -C build -f Vtop.mk
	(cd build && ./Vtop)

$(1)-ast-xml: tests/$(1)/$(1).sv
	rm -rf build
	mkdir build
	(cd build && ../$(YOSYS) -p \
		'read_verilog -dump_ast1 ../$$<')
	./merge.py build/ast.json build/*.json
	$(VERILATOR) \
		--cc --xml-only -Mdir build --top-module top --json-ast build/ast.json
endef

$(foreach f,$(TESTS),$(eval $(call template,$(f))))

build-verilator:
	(cd verilator/src && make ../bin/verilator_bin)

veri: build-verilator image/bin/verilator

missing-nodes:
	$(QUIET)cat build/ast.json | grep type | grep AST_ | \
		cut -d\" -f4 | sort | uniq > nodes-ast.tmp
	$(QUIET)cat verilator/src/JsonAst.cpp | sed 's/||/\n/g' | \
		grep 'type ==' | grep AST_ | cut -d\" -f2 | \
		sort | uniq > nodes-veri.tmp
	$(QUIET)comm -23 nodes-ast.tmp nodes-veri.tmp
	$(QUIET)rm -f nodes-ast.tmp nodes-veri.tmp

# PicoRV32 test
prv32-sv:
	rm -rf build
	./$(VERILATOR) \
		--cc --exe --trace --top-module top \
		-Mdir build \
		prv32/top.sv prv32/picorv32/picorv32.v prv32/main.cpp
	make -C build -f Vtop.mk
	[ -f prv32/firmware/firm.bin ] && cp prv32/firmware/firm.bin build/mem.bin || true
	(cd build && ./Vtop)

prv32-ast:
	rm -rf build
	mkdir build
	(cd build && ../$(YOSYS) \
		-p 'read_verilog -dump_ast1 ../prv32/top.sv' \
		-p 'read_verilog -dump_ast1 ../prv32/picorv32/picorv32.v')
	./merge.py build/ast.json \
		build/picorv32.json \
		build/top.json
	./$(VERILATOR) \
		--cc --exe --trace -top-module top \
		-Mdir build \
		-Wno-WIDTH -Wno-CASEINCOMPLETE -Wno-PINMISSING -Wno-SELRANGE -Wno-CASEOVERLAP \
		--json-ast build/ast.json prv32/main.cpp
	make -C build -f Vtop.mk
	[ -f prv32/firmware/firm.bin ] && cp prv32/firmware/firm.bin build/mem.bin || true
	(cd build && ./Vtop)
