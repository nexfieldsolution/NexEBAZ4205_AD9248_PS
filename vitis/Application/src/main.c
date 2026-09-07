#include "FreeRTOS.h"
#include "task.h"
#include "xil_printf.h"

static void uart_task(void *pvParameters)
{
    int count = 0;
    while (1) {
        xil_printf("count [%d]\r\n", count++);
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

int main(void)
{
    xil_printf("NexEBAZ4205 FreeRTOS start\r\n");

    xTaskCreate(uart_task, "uart", 512, NULL, 1, NULL);
    vTaskStartScheduler();

    while (1);
    return 0;
}
