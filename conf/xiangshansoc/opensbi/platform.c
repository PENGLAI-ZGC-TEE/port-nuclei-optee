#include <libfdt.h>
#include <sbi/riscv_asm.h>
#include <sbi/riscv_io.h>
#include <sbi/riscv_encoding.h>
#include <sbi/sbi_console.h>
#include <sbi/sbi_const.h>
#include <sbi/sbi_platform.h>
#include <sbi_utils/fdt/fdt_fixup.h>
#include <sbi_utils/fdt/fdt_domain.h>
#include <sbi_utils/fdt/fdt_helper.h>
#include <sbi_utils/irqchip/plic.h>
#include <sbi_utils/sys/clint.h>
#include <sbi_utils/irqchip/fdt_irqchip.h>
#include <sbi_utils/serial/fdt_serial.h>
#include <sbi_utils/timer/fdt_timer.h>
#include <sbi_utils/ipi/fdt_ipi.h>
#include <sbi_utils/reset/fdt_reset.h>

/* clang-format off */
#define BOSC_HART_COUNT                   1

static int bosc_early_init(bool cold_boot)
{
    if (cold_boot) {
        // do some early init such as pinmux initialization or clock init
    }
    return 0;
}

static void bosc_modify_dt(void *fdt)
{
    fdt_cpu_fixup(fdt);
    fdt_fixups(fdt);
    fdt_domain_fixup(fdt);
}

extern void sm_init(bool cold_boot);
extern void opteed_cpu_on_handler(uint32_t linear_id);
static int bosc_final_init(bool cold_boot)
{
    void *fdt;

    if (!cold_boot) {
        /* warm boot to setup optee ctx for secondary cpu */
        unsigned int secondary_hartid;

        secondary_hartid = current_hartid();
        opteed_cpu_on_handler(secondary_hartid);

        return 0;
    }

    fdt = sbi_scratch_thishart_arg1_ptr();
    bosc_modify_dt(fdt);
    sm_init(cold_boot);

    return 0;
}

static int bosc_system_reset_check(u32 type, u32 reason)
{
    return 1;
}

static void bosc_system_reset(u32 type, u32 reason)
{
    while(1);
}

static int bosc_domains_init(void)
{
    return fdt_domains_populate(sbi_scratch_thishart_arg1_ptr());
}

const struct sbi_platform_operations platform_ops = {
    .early_init         = bosc_early_init,
    .final_init         = bosc_final_init,
    .domains_init       = bosc_domains_init,
    .console_putc       = fdt_serial_putc,
    .console_getc       = fdt_serial_getc,
    .console_init       = fdt_serial_init,
    .irqchip_init       = fdt_irqchip_init,
    .irqchip_exit       = fdt_irqchip_exit,
    .ipi_send           = fdt_ipi_send,
    .ipi_clear          = fdt_ipi_clear,
    .ipi_init           = fdt_ipi_init,
    .ipi_exit           = fdt_ipi_exit,
    .timer_value        = fdt_timer_value,
    .timer_event_stop   = fdt_timer_event_stop,
    .timer_event_start  = fdt_timer_event_start,
    .timer_init         = fdt_timer_init,
    .timer_exit         = fdt_timer_exit,
    .system_reset_check = bosc_system_reset_check,
    .system_reset       = bosc_system_reset
};

static u32 bosc_hart_index2id[BOSC_HART_COUNT] = {
    [0] = 0
};

const struct sbi_platform platform = {
    .opensbi_version    = OPENSBI_VERSION,
    .platform_version   = SBI_PLATFORM_VERSION(0x0U, 0x01U),
    .name               = "BOSC Xiangshan SoC",
    .features           = SBI_PLATFORM_DEFAULT_FEATURES,
    .hart_count         = BOSC_HART_COUNT,
    .hart_stack_size    = SBI_PLATFORM_DEFAULT_HART_STACK_SIZE,
    .platform_ops_addr  = (unsigned long)&platform_ops,
    .hart_index2id      = bosc_hart_index2id
};
