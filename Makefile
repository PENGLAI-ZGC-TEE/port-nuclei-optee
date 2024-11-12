## Default configuration
SOC ?= xiangshansoc
CORE ?= nanhu
ISA ?= rv64imafdc
ABI ?= lp64d
NPROC ?= $(shell nproc)

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

## Linux
linux_srcdir := $(srcdir)/linux
linux_wrkdir := $(wrkdir)/linux
linux_defconfig := $(confdir)/linux_$(ISA)_defconfig
linux_gen_initramfs=$(linux_srcdir)/usr/gen_initramfs.sh
linux_image := $(linux_wrkdir)/arch/riscv/boot/Image
vmlinux := $(linux_wrkdir)/vmlinux
initramfs := $(wrkdir)/initramfs.cpio.gz

## DTS
platform_dts := $(confdir)/bosc_$(ISA).dts
platform_preproc_dts := $(wrkdir)/bosc_$(ISA).dts.preprocessed
platform_dtb := $(wrkdir)/bosc_$(ISA).dtb

## OpenSBI
opensbi_srcdir := $(srcdir)/opensbi
opensbi_wrkdir := $(wrkdir)/opensbi
opensbi_plat_confdir := $(confdir)/opensbi
opensbi_plat_srcdir := $(srcdir)/opensbi/platform/bosc/$(SOC)
opensbi_payload := $(opensbi_wrkdir)/platform/bosc/$(SOC)/firmware/fw_payload.elf
opensbi_dynamic := $(opensbi_wrkdir)/platform/bosc/$(SOC)/firmware/fw_dynamic.elf
opensbi_jumpbin := $(opensbi_wrkdir)/platform/bosc/$(SOC)/firmware/fw_jump.bin
opensbi_jumpelf := $(opensbi_wrkdir)/platform/bosc/$(SOC)/firmware/fw_jump.elf
opensbi_plat_deps := $(wildcard $(addprefix $(opensbi_plat_confdir)/, *.mk *.c *.h))

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

#########
# Linux #
#########
.PHONY: initrd linux linux-menuconfig vmlinux

initrd: $(initramfs)
	@echo "initramfs cpio file is generated into $<"

linux: $(linux_wrkdir)/.config
	cp $(initramfs) $(linux_srcdir)
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) \
		CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
		CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
		ARCH=riscv \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		CFLAGS=-g \
		-j $(NPROC) \
		vmlinux Image
		
linux-menuconfig: $(linux_wrkdir)/.config
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) menuconfig
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) savedefconfig
	cp $(dir $<)/defconfig $(linux_defconfig)
	
vmlinux: $(vmlinux)

$(linux_wrkdir)/.config: $(linux_defconfig) $(target_gcc)
	mkdir -p $(dir $@)
	cp -p $< $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) olddefconfig

$(vmlinux): linux

$(linux_image): linux
	@echo "Linux image is generated $@"

#######
# DTS #
#######
.PHONY: gen-dts gen-dtb

gen-dts: $(platform_dts) $(target_gcc)
	$(target_gcc) -E -nostdinc -undef -x assembler-with-cpp $(DTS_DEFINES) $(platform_dts) -o $(platform_preproc_dts)
	
gen-dtb: $(platform_dtb)
	dtc -O dtb -o $(platform_dtb) $(platform_preproc_dts)

$(platform_preproc_dts): gen-dts
	echo "Platform preprocessed dts located in $(platform_preproc_dts), processed with defines $(DTS_DEFINES)"
	
$(platform_dtb) : $(platform_preproc_dts) $(target_gcc)
	dtc -O dtb -o $(platform_dtb) $(platform_preproc_dts)

###########
# OpenSBI #
###########
.PHONY: opensbi

opensbi: $(target_gcc) $(opensbi_plat_deps)
	mkdir -p $(opensbi_plat_srcdir)
	cp -u $(opensbi_plat_confdir)/* $(opensbi_plat_srcdir)
	$(MAKE) -C $(opensbi_srcdir) O=$(opensbi_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) PLATFORM_RISCV_ABI=$(ABI) PLATFORM_RISCV_ISA=$(ISA) PLATFORM=bosc/$(SOC) -j $(NPROC)

$(opensbi_jumpbin): opensbi

#########
# clean #
#########
.PHONY: clean-toolchain cleanlinux cleanopensbi
clean-toolchain:
	rm -rf $(toolchain_srcdir)
	
cleanlinux:
	rm -rf $(linux_wrkdir)
	
cleanopensbi:
	rm -rf $(opensbi_wrkdir)