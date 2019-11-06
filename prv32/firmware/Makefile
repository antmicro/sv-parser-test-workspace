TC = $(PWD)/riscv32-unknown-elf/bin/
CROSS_COMPILE = $(TC)/riscv32-unknown-elf-

CC = $(CROSS_COMPILE)gcc
OBJDUMP = $(CROSS_COMPILE)objdump
OBJCOPY = $(CROSS_COMPILE)objcopy

CFLAGS = -march=rv32i -mabi=ilp32 -O0 -pipe

all: firm.bin

firm.elf: startup.s script.ld
	$(CC) $(CFLAGS) -nostdlib -T script.ld -o $@ startup.s

firm.bin: firm.elf
	$(OBJCOPY) -Obinary $< $@

dis: firm.elf
	$(OBJDUMP) -d $<

hex: firm.bin
	hexdump -C $<

clean::
	rm -f firm.elf firm.bin

# Build RISC-V toolchain from scratch (riscv32-unknown-elf)
ct/bootstrap:
	git clone -n https://github.com/crosstool-ng/crosstool-ng ct && \
		(cd ct && git checkout crosstool-ng-1.24.0)

ct/configure: ct/bootstrap
	(cd ct && ./bootstrap)

ct/Makefile: ct/configure
	(cd ct && ./configure --enable-local)

ct/ct-ng: ct/Makefile
	(cd ct && make -j`nproc`)

ct/.config: ct/ct-ng
	(cd ct && ./ct-ng DEFCONFIG=../ct.config defconfig)

build-toolchain: ct/.config
	(cd ct && ./ct-ng build.`nproc`)

clean::
	rm -rf ct
