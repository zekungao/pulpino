// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/* Scheduler include files. */
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"
#include "int.h"
#include "timer.h"
#include "utils.h"

#define DELAY_LOOP 10000
#define TRUE 1

uint8_t ucHeap[ configTOTAL_HEAP_SIZE ];

void task1 (void *pvParameters) {

	while(TRUE) {

		printf("Task 1\n");

		taskYIELD();

		for(int i = 0; i < DELAY_LOOP; i++)
			portNOP();
	}

	vTaskDelete(NULL);

}

void task2 (void *pvParameters) {
	while(TRUE) {

		printf("Task 2\n");

		taskYIELD();

		for(int i = 0; i < DELAY_LOOP; i++)
			portNOP();
	}

	vTaskDelete(NULL);
}

void task3 (void *pvParameters) {
        int count = 0;
	while(count < 10) {

		printf("Task 3 count %d \n", count);

		taskYIELD();

		for(int i = 0; i < DELAY_LOOP; i++)
			portNOP();

                count++;
	}

	vTaskDelete(NULL);
}

int main( void )
{
	int_enable();
    EER = 0x30000000; // enable A timer events;
    IER = 0x30000000; // enable A timer interrupts

	BaseType_t task1_rst;
    BaseType_t task2_rst;
    BaseType_t task3_rst;        

	printf("Starting FreeRTOS\n");

	task1_rst = xTaskCreate(task1, "Task1", 100, NULL, 3, NULL);
	printf("create task1 rst %d \n",(int)task1_rst);
 	task2_rst = xTaskCreate(task2, "Task2", 100, NULL, 3, NULL);
	printf("create task2 rst %d \n",(int)task2_rst);

    task3_rst = xTaskCreate(task3, "Task3", 100, NULL, 4, NULL);
    printf("create task3 rst %d \n",(int)task3_rst);

	vTaskStartScheduler();
	

	return 0;
}


void vPortSetupTimerInterrupt( void )
{
    unsigned int CompareMatch;

    CompareMatch = configCPU_CLOCK_HZ / configTICK_RATE_HZ;

    /* Setup Timer A */
    TOCRA = CompareMatch;
    TPRA  = 0x01; // set prescaler, enable interrupts and start timer. 
}

/*
Different RISC-V implementations provide different handlers for external interrupts, 
so it is necessary to tell the FreeRTOS kernel which external interrupt handler to call. 
To set the name of the external interrupt handler:
*/
void external_interrupt_handler(int cause, unsigned int epc){
    unsigned int prev_ipr = IPR;
	// Clear all ICP for testing only
	// Must handle all IRQs in production 
    ICP = IPR;
    printf("external_interrupt_handler %x %x \n", cause, prev_ipr);
    BaseType_t xTaskIncrementTick( void );
    void vTaskSwitchContext( void );
	if( cause < 0 ){
	    if( xTaskIncrementTick() != 0 ){
		    vTaskSwitchContext();
	    }
	}
}
