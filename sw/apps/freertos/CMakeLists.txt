set(FREERTOS_SOURCES main.c Source/croutine.c Source/event_groups.c Source/stream_buffer.c Source/timers.c Source/list.c Source/queue.c Source/tasks.c Source/portable/GCC/RI5CY/port.c Source/portable/GCC/RI5CY/portASM.S Source/portable/MemMang/heap_2.c)

include_directories(. Source/portable/GCC/RI5CY Source/include)

add_application(freertos "${FREERTOS_SOURCES}")


