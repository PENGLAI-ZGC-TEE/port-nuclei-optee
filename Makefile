## Default configuration
SOC ?= xiangshansoc
CORE ?= nanhu
ISA ?= rv64imafdc
ABI ?= lp64d

# Set source dir of this repo
srcdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
srcdir := $(srcdir:/=)
wrkdir_root := $(CURDIR)/work

# Set ./conf dir and ./work dir
confdir := $(srcdir)/conf/$(SOC)
wrkdir := $(wrkdir_root)/$(SOC)

## Toolchain
toolchain_srcdir := $(srcdir)/nuclei_toolchain
toolchain_url := https://www.nucleisys.com/upload/files/nuclei_riscv_glibc_prebuilt_linux64_2022.04.tar.bz2

## Cross compile
target := riscv-nuclei-linux-gnu
CROSS_COMPILE := $(toolchain_srcdir)/gcc/bin/$(target)-
target_gcc := $(CROSS_COMPILE)gcc
target_gdb := $(CROSS_COMPILE)gdb

#############
# Toolchain #
#############
.PHONY: toolchain
toolchain:
	$(call download_toolchain, $(toolchain_srcdir), $(toolchain_url))

# Download prebuilt toolchain
# $(1) is toolchain source dir to download to
# $(2) is toolchain url where the tarball can be downloaded
define download_toolchain
	mkdir -p $(1)
	cd $(1)
	wget $(2) -O temp.tar.gz
	tar -xvjf temp.tar.gz -C $(1)
	rm -f temp.tar.gz
endef

.PHONY: clean-toolchain
clean-toolchain:
	rm -rf $(toolchain_srcdir)