#include "xparameters.h"
#include "sleep.h"
#include "xil_printf.h"

// AXI GPIO - hellofpga IO 보드 LED (E19=LED1, K17=LED2, H18=LED3)
#define GPIO_DATA  (*(volatile unsigned int *)(XPAR_AXI_GPIO_0_BASEADDR + 0x00))
#define GPIO_TRI   (*(volatile unsigned int *)(XPAR_AXI_GPIO_0_BASEADDR + 0x04))

#define LED1  (1 << 0)  // E19
#define LED2  (1 << 1)  // K17
#define LED3  (1 << 2)  // H18

int main(void)
{
    xil_printf("NexEBAZ4205 AD9248 PS firmware start\r\n");

    int count = 0;
    while (1) {
        xil_printf("count [%d]\r\n", count++);
        usleep(1000000);
    }

    return 0;
}
