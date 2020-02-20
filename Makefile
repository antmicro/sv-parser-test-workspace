TESTS = $(shell find tests -name *.sv | cut -d\/ -f2 | sort)
TEST ?= tests/onenet
TEST_SCRIPT ?= $(TEST)/yosys_script

BAZEL_URL = https://github.com/bazelbuild/bazel/releases/download/1.1.0/bazel-1.1.0-dist.zip
VERIBLE_PARSER ?= $(PWD)/verible/bazel-bin/verilog/tools/syntax/verilog_syntax

BAZEL_BIN = $(shell which bazel)
ifeq ($(BAZEL_BIN),)
BAZEL_BIN = $(PWD)/bazel/output/bazel
endif

BAZEL = $(BAZEL_BIN)
VERIBLE_FLAGS = --cxxopt=-std=c++17

ifneq ($(VERIBLE_DEBUG),)
VERIBLE_FLAGS += \
	--copt=-g3 --copt=-ggdb \
	--copt=-g3 --cxxopt=-ggdb \
	--linkopt=-g3 --linkopt=-ggdb \
	--strip=never
endif

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

$(1)-vp $(1)-verible-parser: tests/$(1)/$(1).sv
	rm -rf build
	mkdir build
	(cd build && \
		$(VERIBLE_PARSER) -printtree ../$$<)
	(cd build && ../v2j.py --input=verible.json --output=ast.json)
	$(VERILATOR) \
		--trace --cc --exe -Mdir build \
		--top-module top \
		-Wno-CASEINCOMPLETE \
		--json-ast build/ast.json sim.cpp
	cat tests/$(1)/$(1).cpp | sed 's/%TOP_MODULE%/top/g' > build/sim.cpp
	make -C build -f Vtop.mk
	(cd build && ./Vtop)

define yosys_$(1)_script
read_jsonast ast.json
prep -top top
sim -clock c -resetn d -rstlen 10 -vcd dump.vcd
endef

export yosys_$(1)_script

$(1)-yosys: tests/$(1)/$(1).sv
	rm -rf build
	mkdir build
	(cd build && $(VERIBLE_PARSER) -printtree ../$$<)
	(cd build && ../v2j.py --input=verible.json --output=ast.json)
	(cd build && echo "$$$$yosys_$(1)_script" > yosys_$(1)_script)
	(cd build && ../$(YOSYS) -s yosys_$(1)_script)

endef

$(foreach f,$(TESTS),$(eval $(call template,$(f))))

build-verilator:
	(cd verilator/src && make ../bin/verilator_bin)

veri: build-verilator image/bin/verilator

missing-nodes:
	$(QUIET)cat yosys_ast.txt | grep AST_ | \
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

# ------------- BAZEL -----------
bazel/.dir:
	mkdir bazel && touch $@

bazel/src.zip: bazel/.dir
	wget -O $@ -c "$(BAZEL_URL)" && touch $@

bazel/.unpack: bazel/src.zip
	(cd bazel && unzip src.zip) && touch $@

bazel/.compile: bazel/.unpack
	(cd bazel && \
		env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" \
		bash ./compile.sh) && touch $@

build-bazel: bazel/.compile

# ------------ Verible ---------
verible/tags:
	(cd verible && ctags -R common/ verilog/)

verible/build:
	(cd verible && $(BAZEL) \
		--output_user_root=$(PWD)/cache \
		build \
		$(VERIBLE_FLAGS) \
		//...)

verible/test:
	(cd verible && $(BAZEL) \
		--output_user_root=$(PWD)/cache \
		test \
		$(VERIBLE_FLAGS) \
		//...)

COVERAGE_REPORT_GENERATOR = \
	/tools/test/CoverageOutputGenerator/java/com/google/devtools/coverageoutputgenerator

verible/coverage:
	(cd verible && $(BAZEL) \
		--output_user_root=$(PWD)/cache \
		coverage -s \
		$(VERIBLE_FLAGS) \
		--instrument_test_targets \
		--experimental_cc_coverage \
		--combined_report=lcov \
		--coverage_report_generator=@bazel_tools/$(COVERAGE_REPORT_GENERATOR):Main \
		//...)

verible/coverage/report:
	(cd verible && \
		genhtml -o coverage_report bazel-out/_coverage/_coverage_report.dat)

verible/coverage/report/view:
	(cd verible/coverage_report && chromium-browser \
		--user-data-dir=$$PWD/cr.work \
		--app="file://$$PWD/index.html" >/dev/null 2>/dev/null) &

verible/cov:
	make -C . --no-print-directory verible/coverage
	make -C . --no-print-directory verible/coverage/report >/dev/null

verible/cov/view:
	make -C . --no-print-directory verible/cov
	make -C . --no-print-directory verible/coverage/report/view

verible/clean:
	rm -rf verible/coverage_report
	rm -f verible/tags
	(cd verible && $(BAZEL) \
		--output_user_root=$(PWD)/cache \
		clean)

verible/distclean: verible/clean
	chmod -R 755 cache
	rm -rf cache

# ------------ Surelog ------------ 
surelog: Surelog/build/dist/Release/hellosureworld

Surelog/build/dist/Release/hellosureworld:
	(cd Surelog && make PREFIX=$(PWD)/image && make install)

surelog/listener: test_listener

test_listener:
	g++ -std=c++14 uhdm/tests/test_listener.cpp \
		-I/usr/local/include/uhdm \
		-I/usr/local/include/uhdm/include /usr/local/lib/uhdm/libuhdm.a \
		-lcapnp -lkj -ldl -lutil -lm -lrt -lpthread \
		-o test_listener

surelog/parse: surelog
	Surelog/build/dist/Release/hellosureworld -parse $(TEST)/top.sv
	cp slpp_all/surelog.uhdm $(TEST)/top.uhdm

# ------------ UHDM ------------ 

uhdm/clean:
	rm -rf test_listener read_dff obj_dir slpp_all

uhdm/cleanall: uhdm/clean
	rm -rf ./image
	(cd uhdm && make clean)
	(cd verilator && make clean)
	(cd Surelog && make clean)

uhdm/build:
	mkdir -p uhdm/build
	(cd uhdm/build && cmake \
		-DCMAKE_INSTALL_PREFIX=$(PWD)/image \
		-D_GLIBCXX_DEBUG=1 \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_CXX_FLAGS='-D_GLIBCXX_USE_CXX11_ABI=1 -DWITH_LIBCXX=Off' \
		../)
	(cd uhdm && make install)

uhdm/restore: surelog/listener surelog/parse
	./test_listener $(TEST)/top.uhdm

uhdm/print: surelog/parse read_dff
	./read_dff $(TEST)/top.uhdm

uhdm/app: read_dff

read_dff:
	g++ -g -std=c++14 empty_design.cpp \
		-I/usr/local/include/uhdm \
		-I/usr/local/include/uhdm/include \
		/usr/local/lib/uhdm/libuhdm.a \
		-L$(PWD)/image/lib \
		-lcapnp -lkj -ldl -lutil -lm -lrt -lpthread \
		-o read_dff

uhdm/verilator/build: uhdm/build image/bin/verilator

uhdm/verilator/dff:
	./image/bin/verilator --cc $(TEST)/top.sv --exe $(TEST)/top.sv
	make -j -C obj_dir -f Vtop.mk Vtop
	obj_dir/Vtop

uhdm/verilator/get-ast:
	./image/bin/verilator --cc $(TEST)/top.sv --exe $(TEST)/main.cpp --xml-only

uhdm/verilator/ast-xml: uhdm/verilator/build surelog/parse
	./image/bin/verilator --uhdm-ast --cc $(TEST)/top.uhdm --exe $(TEST)/main.cpp --top-module work_TOP --xml-only --debug

uhdm/verilator/test-ast: uhdm/verilator/build surelog/parse
	./image/bin/verilator --uhdm-ast --cc $(TEST)/top.uhdm --exe $(TEST)/main.cpp --top-module work_TOP --trace
	 #make -j -C obj_dir -f Vtop.mk Vtop
	 make -j -C obj_dir -f Vwork_TOP.mk Vwork_TOP
	 obj_dir/Vwork_TOP

uhdm/yosys/onenet: yosys/yosys
	yosys/yosys -s $(TEST_SCRIPT)
