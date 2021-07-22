#include <stdio.h>
#include "gpio.h"
#include "int.h"
#include "utils.h"

#define USED_GPIO_WIDTH 21
#define ALL_GPIO_WIDTH 32


#define TEST_SUCCESS 0
#define TEST_FAIL -1

const char *gpio_direction_str(int direction);

void mset_gpio_pin_direction(int pin, int direction);

void mset_gpio_pin_value(int pin, int value);

void wait_gpio_pin_value(int pin, int expect);

void enable_gpio_pin_interrupt(int pin, int type);

void enable_gpio_interrupt();
void disable_all_gpio_pin_interrupt();
void enable_used_gpio_pin_interrupt(int type);

void test_input_seq(int pin, int expect);
void test_input();
void test_output_seq(int pin, int value);
void test_output();

int test_gpio_interrupt_edge(int type);
int test_gpio_interrupt_level(int type);

int interrupt_type;
int wait_output_seq;
int edge_interrupt_count[USED_GPIO_WIDTH];

int is_second;
int lev_interrupt_count[2][USED_GPIO_WIDTH];
int GPIO_SEQ_AND_EXIT_FLAG;

/*
 * It looks zeroriscy and ri5cy interruption handling behaviors are not the same.
 * After mret, before the next user-mode instruction:
 * - zeroriscy: will NOT go into interruption handler on pending interruption.
 * - ri5cy:     will go into interruption handler on pending interruption.
 *              And when the interruption always pends, 
 *              it is not possible to run user-mode code at all.
 */
#if USE_ZERO_RISCY == 0

// Core is RI5CY
#define DISABLE_PIN_IRQ_WHEN_CORE_IS_ZERORISCY(i) do { \
} while(0)

#define DISABLE_PIN_IRQ_WHEN_CORE_IS_RI5CY(i) do {     \
    set_gpio_pin_irq_en((i), 0);                       \
} while(0)

#define LEV_INT_COUNT_DIFF 0

#elif USE_ZERO_RISCY == 1 

// Core is ZeroRiscy
#define DISABLE_PIN_IRQ_WHEN_CORE_IS_ZERORISCY(i) do { \
    set_gpio_pin_irq_en((i), 0);                       \
} while(0)

#define DISABLE_PIN_IRQ_WHEN_CORE_IS_RI5CY(i) do {     \
} while(0)

#define LEV_INT_COUNT_DIFF 6

#else
    #error("Unsuported USE_ZERO_RISCY value")
#endif

int run_gpio_test(){
    enable_gpio_interrupt();
    disable_all_gpio_pin_interrupt();
    test_input();
    printf("gpio test input done \n");

    test_output();
    printf("gpio test output done \n"); 

    int result;
    result = test_gpio_interrupt_edge(GPIO_IRQ_RISE);
    if(result == TEST_SUCCESS){
        printf("gpio test interrupt rise success\n");
    }else{
        printf("gpio test interrupt rise fail\n");
        return result;
    }

    result = test_gpio_interrupt_edge(GPIO_IRQ_FALL);
    if(result == TEST_SUCCESS){
        printf("gpio test interrupt fall success\n");
    }else{
        printf("gpio test interrupt fall fail\n");
        return result;
    }

    result = test_gpio_interrupt_level(GPIO_IRQ_LEV0);
    if(result == TEST_SUCCESS){
        printf("gpio test interrupt lev0 success\n");
    }else{
        printf("gpio test interrupt lev0 fail\n");
        return result;
    }

    result = test_gpio_interrupt_level(GPIO_IRQ_LEV1);
    if(result == TEST_SUCCESS){
        printf("gpio test interrupt lev1 success\n");
    }else{
        printf("gpio test interrupt lev1 fail\n");
        return result;
    }
    return TEST_SUCCESS;
}

int main(){
    printf("main run \n");

    GPIO_SEQ_AND_EXIT_FLAG = 8;

    int result;
    result = run_gpio_test();
    if(result != TEST_SUCCESS){
        return result;
    }

    GPIO_SEQ_AND_EXIT_FLAG = 9;
    result = run_gpio_test();
    if(result != TEST_SUCCESS){
        return result;
    }

    mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
    mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
 
    return 0;
}



void ISR_GPIO(void){
    // Must get_gpio_irq_status first and then set ICP.
    // because get_gpio_irq_status only clear gpio prepheral interrupt status, ICP is not cleared.
    // if clear ICP first, ISR_GPIO will trigger another time.
    int status = get_gpio_irq_status();
    ICP = 0x1 << GPIO_EVENT;
    int i = 0;
    while (status > 1)
    {
        status >>= 1;
        i++;
    }
    if(interrupt_type > 1){
        edge_interrupt_count[i] += 1;
    }else{
        lev_interrupt_count[is_second][i]+=1;
    }
        
    wait_output_seq = i; 
    if (interrupt_type == GPIO_IRQ_LEV0 || interrupt_type == GPIO_IRQ_LEV1) {
        DISABLE_PIN_IRQ_WHEN_CORE_IS_RI5CY(i);
    }
}

void enable_gpio_interrupt(){
    IER = 0x1 << GPIO_EVENT;
    int_enable();
}

void disable_all_gpio_pin_interrupt(){
    int i;
    for (i = 0; i < ALL_GPIO_WIDTH; i++){
	set_gpio_pin_irq_en(i, 0);
    }
}

void enable_used_gpio_pin_interrupt(int type){
    int i;
    for (i = 0; i < USED_GPIO_WIDTH; i++){
	if( i != GPIO_SEQ_AND_EXIT_FLAG){
	    mset_gpio_pin_direction(i, DIR_IN);
	    enable_gpio_pin_interrupt(i, type);
	}else{
            set_gpio_pin_irq_en(i, 0);
        }
    }	
}

int test_gpio_interrupt_edge(int type){
    interrupt_type = type;
    int i;
    for (i = 0; i < USED_GPIO_WIDTH; i++){
        edge_interrupt_count[i] = 0;
    }
    wait_output_seq = -1;
    enable_used_gpio_pin_interrupt(type);
    mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
    mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
   
    for (i = 0; i < USED_GPIO_WIDTH; i++){
        if (i == GPIO_SEQ_AND_EXIT_FLAG) {
            continue;
        }
        mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
        mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
	while(wait_output_seq != i);
    }
    for (i = 0; i < USED_GPIO_WIDTH; i++){
        if (i == GPIO_SEQ_AND_EXIT_FLAG) {
            continue;
        }
        if(edge_interrupt_count[i] != 1){
            printf("gpio itr %d pin %d count %d\n", type, i, edge_interrupt_count[i]);
            return TEST_FAIL;
        }
    }
    return TEST_SUCCESS;
}


int test_gpio_interrupt_level(int type){
    interrupt_type = type;
    is_second = 0;
    int i;
    int level = !type;// type_lev0:0x01  type_lev1:0x00
    for (i = 0; i < USED_GPIO_WIDTH; i++){
        lev_interrupt_count[0][i] = 0;
        lev_interrupt_count[1][i] = 0;
    }
    wait_output_seq = -1;
    disable_all_gpio_pin_interrupt();
    mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
    mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
    for (i = 0; i < USED_GPIO_WIDTH; i++){
        if (i == GPIO_SEQ_AND_EXIT_FLAG) {
            continue;
        }
        mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
        mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
	wait_gpio_pin_value(i, level);

        set_gpio_pin_irq_type(i, type);
        set_gpio_pin_irq_en(i, 1);
        asm volatile("nop;nop;nop;nop;nop;nop");
        DISABLE_PIN_IRQ_WHEN_CORE_IS_ZERORISCY(i);
        mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
        mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
    }
    disable_all_gpio_pin_interrupt();
    is_second++;
    mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
    mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
    for (i = 0; i < USED_GPIO_WIDTH; i++){
        if (i == GPIO_SEQ_AND_EXIT_FLAG) {
            continue;
        }
        mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
        mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
	wait_gpio_pin_value(i, level);

        set_gpio_pin_irq_type(i, type);
        set_gpio_pin_irq_en(i, 1);
        asm volatile("nop;nop;nop;nop;nop;nop");
        asm volatile("nop;nop;nop;nop;nop;nop");
        DISABLE_PIN_IRQ_WHEN_CORE_IS_ZERORISCY(i);
        mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
        mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
    }
    for (i = 0; i < USED_GPIO_WIDTH; i++){
        if (i == GPIO_SEQ_AND_EXIT_FLAG) {
            continue;
        }
        if(lev_interrupt_count[1][i]-lev_interrupt_count[0][i] != LEV_INT_COUNT_DIFF){
            printf("gpio itr %d pin %d count_first %d count_second %d\n", type, i, lev_interrupt_count[0][i], lev_interrupt_count[1][i]);
            return TEST_FAIL;
        }
    }
    return TEST_SUCCESS;
}


void enable_gpio_pin_interrupt(int pin, int type){
    set_gpio_pin_irq_en(pin, 1);
    set_gpio_pin_irq_type(pin, type);
}


void test_input_seq(int pin, int expect){
    if (pin != GPIO_SEQ_AND_EXIT_FLAG){
	mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
    	mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
        wait_gpio_pin_value(pin, expect);
    }
}

void test_input(){
    int i;
    for (i = 0; i < USED_GPIO_WIDTH; i++){
        test_input_seq(i, 1);
        test_input_seq(i, 0);
        test_input_seq(i, 1);
        test_input_seq(i, 0);
    }
}

void test_output_seq(int pin, int value){
    if (pin != GPIO_SEQ_AND_EXIT_FLAG){
	mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
    	mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);
        mset_gpio_pin_value(pin, value);
    }
}

void test_output(){
    mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 0);
    mset_gpio_pin_value(GPIO_SEQ_AND_EXIT_FLAG, 1);

    int i;
    for (i = 0; i < USED_GPIO_WIDTH; i++){
        test_output_seq(i, 1);
        test_output_seq(i, 0);
        test_output_seq(i, 1);
        test_output_seq(i, 0);
    }
}

const char *gpio_direction_str(int direction){
    if (direction == DIR_IN){
        return "DIR_IN";
    }else if (direction == DIR_OUT){
        return "DIR_OUT";
    }
    return "DIR_UNKNOWN";
}

void mset_gpio_pin_direction(int pin, int direction){
    set_pin_function(pin, FUNC_GPIO);
    set_gpio_pin_direction(pin, direction);
}

void mset_gpio_pin_value(int pin, int value){
    mset_gpio_pin_direction(pin, DIR_OUT);
    set_gpio_pin_value(pin, value);
    return;
}

void wait_gpio_pin_value(int pin, int expect){
    mset_gpio_pin_direction(pin, DIR_IN);
    while (get_gpio_pin_value(pin) != expect);
    return;
}
