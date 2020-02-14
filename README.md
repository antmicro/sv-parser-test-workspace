# Test bench for SystemVerilog tools integration
[![Build Status](https://travis-ci.org/antmicro/sv-parser-test-workspace.svg?branch=uhdm-verilator)](https://travis-ci.org/antmicro/sv-parser-test-workspace)

## Preparations:

Initialize the submodules
```
git submodule update --init --recursive
```

Build tools:
```
make prep
```


## Running tests:

Run dff.sv example with built-in Verilator parser:
```
$ make dff-sv
```

Run dff.sv example with YOSYS parser and JSON IF format:
```
$ make dff-json
```

Run one-net example for Surelog-UHDM-Verilator flow:
```
$ make uhdm/verilator/test-ast
```

Intermediate files would be located in build dir.
