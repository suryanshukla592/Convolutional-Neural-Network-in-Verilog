`timescale 1ns / 1ps
//Validation is done under specific input values
module tb_layer1();

    // Parameters (Matching the UUT)
    parameter SIZE = 8;
    parameter IMAGE_WIDTH = 28;
    parameter FILTER = 8;
    parameter b_size = 26; // 28 - 3 + 1 = 26

    // Inputs
    reg clk;
    reg rst;
    reg valid_in;
    reg [SIZE-1:0] in;

    // Outputs
    wire [SIZE-1:0] out1, out2, out3, out4, out5, out6, out7, out8;
    wire [FILTER-1:0] valid_out;

    // Memory array for MNIST image (28x28 = 784 pixels)
    reg [SIZE-1:0] mnist_image [0:783];

    // Instantiate the Unit Under Test (UUT)
    conv_layer1 #(
        .SIZE(SIZE), 
        .IMAGE_WIDTH(IMAGE_WIDTH), 
        .FILTER(FILTER), 
        .b_size(b_size)
    ) uut (
        .clk(clk), 
        .rst(rst), 
        .valid_in(valid_in), 
        .in(in), 
        .out1(out1), .out2(out2), .out3(out3), .out4(out4), 
        .out5(out5), .out6(out6), .out7(out7), .out8(out8), 
        .valid_out(valid_out)
    );

    // 1. Clock generation: 100MHz (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // 2. Load Image Data
    initial begin
        // Update this path to match exactly where your file is located
        $readmemh("mnist_7.mem", mnist_image);
        $display("--- Testbench: MNIST Image Loaded ---");
    end

    // Variables for looping and counting outputs
    integer i;
    integer out_count;

    // 3. Stimulus Generation
    initial begin
        // Initialize Inputs
        rst = 0;
        valid_in = 0;
        in = 0;
        out_count = 0;

        // Wait 100 ns for global reset to settle
        #100;
        
        // Release reset (Your module uses active-low reset: if(!rst))
        rst = 1; 
        
        // Wait a couple of clock cycles before starting
        @(posedge clk);
        @(posedge clk);

        $display("--- Starting 28x28 Image Transmission ---");
        
        // Feed the 784 image pixels sequentially from the memory array
        for (i = 0; i < 784; i = i + 1) begin
            valid_in = 1;
            in = mnist_image[i]; 
            @(posedge clk);
        end

        // Stop feeding input data once the image is complete
        valid_in = 0;
        in = 0;
        $display("--- Testbench: Image Data Sent. Waiting for Pipeline to Flush... ---");

        // Wait for remaining pipeline stages in the sliding window/filters to flush out
        #1000;
        
        $display("--- Simulation Complete ---");
        $display("Total Valid 3x3 Window Operations Captured: %0d", out_count);
        
        // Stop the simulation
        $finish;
    end


    // 4. Console Output Monitor
    // Trigger this block whenever data is ready on the positive edge of the clock
    always @(posedge clk) begin
        // Check if all bits of valid_out are 1 (which means &valid_out_filter in your UUT was true)
        if (&valid_out) begin 
            out_count = out_count + 1;
            
            // $signed() is used so that negative weights/outputs are displayed correctly in the console
            $display("Valid Output %0d | F1:%0d, F2:%0d, F3:%0d, F4:%0d, F5:%0d, F6:%0d, F7:%0d, F8:%0d", 
                      out_count, 
                      (out1), (out2), (out3), (out4), 
                      (out5), (out6), (out7), (out8));
        end
    end

endmodule
