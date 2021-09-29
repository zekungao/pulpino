task test_input
(
    input int gpio_sync_pin,
    input int gpio_width
);
    int i;
    for (i = 0; i < gpio_width; ++i) begin
        if(i != gpio_sync_pin)begin
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1);// Wait for software req
            gpio_in[i] = 1'b1;
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            gpio_in[i] = 1'b0;
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            gpio_in[i] = 1'b1;
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            gpio_in[i] = 1'b0;
        end
    end
endtask 


task test_output
(
    input int gpio_sync_pin,
    input int gpio_width
);
    int i;
    wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
    for (i = 0; i < gpio_width; ++i) begin
        if(i != gpio_sync_pin)begin
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            wait(gpio_o[i] === 1);
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            wait(gpio_o[i] === 0);
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            wait(gpio_o[i] === 1);
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            wait(gpio_o[i] === 0);
        end
    end
endtask

task test_interrupt_rise
(
    input int gpio_sync_pin,
    input int gpio_width
);
    int i;
    wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
    for (i = 0; i < gpio_width; ++i) begin
        if(i != gpio_sync_pin)begin
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            gpio_in[i] = 1'b0;
            #100ns;
            gpio_in[i] = 1'b1;
        end
    end
endtask 

task test_interrupt_fall
(
    input int gpio_sync_pin,
    input int gpio_width
);
    int i;
    wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
    for (i = 0; i < gpio_width; ++i) begin
        if(i != gpio_sync_pin)begin
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            gpio_in[i] = 1'b1;
            #100ns;
            gpio_in[i] = 1'b0;
        end
    end
endtask 

task test_interrupt_lev0
(
    input int gpio_sync_pin,
    input int gpio_width
);
    int i;
    wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
    for (i = 0; i < gpio_width; ++i) begin
        if(i != gpio_sync_pin)begin
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            gpio_in[i] = 1'b0;
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
        end
    end
    gpio_in = 'bz;
    #100ns;
    wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
    for (i = 0; i < gpio_width; ++i) begin
        if(i != gpio_sync_pin)begin
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            gpio_in[i] = 1'b0;
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
        end
    end
endtask 

task test_interrupt_lev1
(
    input int gpio_sync_pin,
    input int gpio_width
);
    int i;
    wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
    for (i = 0; i < gpio_width; ++i) begin
        if(i != gpio_sync_pin)begin
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            gpio_in[i] = 1'b1;
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
        end
    end
    gpio_in = 'bz;
    #100ns;
    wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
    for (i = 0; i < gpio_width; ++i) begin
        if(i != gpio_sync_pin)begin
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
            gpio_in[i] = 1'b1;
            wait(gpio_o[gpio_sync_pin] === 0); wait(gpio_o[gpio_sync_pin] === 1); // Wait for software req
        end
    end
endtask 
