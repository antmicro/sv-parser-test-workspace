# Preparations:

Initialize the submodules
```
git submodule update --init --recursive
```

Build tools:
```
make prep
```


# Running tests:

Run dff.sv example with built-in Verilator parser:
```
$ make dff-sv
```

Run dff.sv example with YOSYS parser and JSON IF format:
```
$ make dff-json
```

Intermediate files would be located in build dir.
