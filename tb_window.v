`timescale 1ns / 1ps

module tb_window;

    // Parameters
    // We use a 5x5 image for testing to reach the valid state faster
    parameter DATA_WIDTH = 16;
    parameter IMAGE_WIDTH = 5; 

    // Inputs
    reg clk;
    reg rst;
    reg valid_in;
    reg [DATA_WIDTH-1:0] in;

    // Outputs
    wire [DATA_WIDTH-1:0] p_0_0, p_0_1, p_0_2;
    wire [DATA_WIDTH-1:0] p_1_0, p_1_1, p_1_2;
    wire [DATA_WIDTH-1:0] p_2_0, p_2_1, p_2_2;
    wire valid_out;

    // Instantiate the Unit Under Test (UUT)
    Window_3x3 #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMAGE_WIDTH(IMAGE_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .in(in),
        .p_0_0(p_0_0), .p_0_1(p_0_1), .p_0_2(p_0_2),
        .p_1_0(p_1_0), .p_1_1(p_1_1), .p_1_2(p_1_2),
        .p_2_0(p_2_0), .p_2_1(p_2_1), .p_2_2(p_2_2),
        .valid_out(valid_out)
    );

    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Stimulus process
    integer i;
    initial begin
        // 1. Initialize Inputs
        rst = 0; // Your module uses active-low reset (!rst)
        valid_in = 0;
        in = 0;

        // 2. Release Reset
        #15;
        rst = 1;
        #10;

        // 3. Stream a dummy 5x5 image
        // We will just feed the numbers 1 through 25 sequentially
        valid_in = 1;
        for (i = 1; i <= IMAGE_WIDTH * IMAGE_WIDTH; i = i + 1) begin
            in = i;
            #10; // Wait one clock cycle per pixel
        end

        // 4. Stop streaming
        valid_in = 0;
        in = 0;

        // 5. Wait a few cycles to observe the pipeline drain, then finish
        #2;
        $finish;
    end

    // Self-Checking / Monitoring Block
    // This will print the 3x3 window to the console whenever valid_out is high
    always @(posedge clk) begin
        if (valid_out) begin
            $display("Time: %0t ns | Window Valid!", $time);
            $display("[%3d, %3d, %3d]", p_0_0, p_0_1, p_0_2);
            $display("[%3d, %3d, %3d]", p_1_0, p_1_1, p_1_2);
            $display("[%3d, %3d, %3d]\n", p_2_0, p_2_1, p_2_2);
        end
    end

endmodule