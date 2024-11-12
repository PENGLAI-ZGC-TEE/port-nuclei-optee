# Compiler flags
platform-cppflags-y =
platform-cflags-y =
platform-asflags-y =
platform-ldflags-y =

# Command for platform specific "make run"
platform-runcmd = 

# Firmware load address configuration. This is mandatory.
FW_TEXT_START ?= 0x80000000

# Dynamic firmware configuration.
FW_DYNAMIC=y

# Jump firmware configuration.
FW_JUMP=y
FW_JUMP_ADDR=$(shell printf "0x%X" $$(($(FW_TEXT_START) + 0x1000000))) # This needs to be 2MB aligned for 64-bit support
FW_JUMP_FDT_ADDR=$(shell printf "0x%X" $$(($(FW_TEXT_START) + 0x8000000)))

# Firmware with payload configuration.
FW_PAYLOAD=y
FW_PAYLOAD_OFFSET=0x1000000	 # This needs to be 2MB aligned for 64-bit support
FW_PAYLOAD_FDT_ADDR=$(FW_JUMP_FDT_ADDR)

# OPTEE OS and Share MEM Address for PMP memory isolation
FW_OPTEE_TZDRAM_BASE=0x80800000
FW_OPTEE_TZDRAM_SIZE=0x800000
FW_OPTEE_SHMEM_BASE=0x80200000
FW_OPTEE_SHMEM_SIZE=0x200000

# PLIC base address and size
FW_OPTEE_PLIC_BASE=0x3c000000
FW_OPTEE_PLIC_SIZE=0x400000

# Secure device address and size
FW_OPTEE_SECURE_DEVICE_BASE=0x40000000
FW_OPTEE_SECURE_DEVICE_SIZE=0x1000

# If ISA has F/D extensions, enable FPU support
ifneq (,$(findstring f,$(PLATFORM_RISCV_ISA)))
CFG_WITH_VFP=y
endif
