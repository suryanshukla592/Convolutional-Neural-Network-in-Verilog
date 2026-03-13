`timescale 1ns / 1ps

module tb_convulation;

    // Parameters
    parameter SIZE = 8;

    // Inputs
    reg clk;
    reg reset;
    reg pixel_valid_in;
    reg [SIZE-1:0] p0, p1, p2, p3, p4, p5, p6, p7, p8;
    reg signed [SIZE-1:0] w0, w1, w2, w3, w4, w5, w6, w7, w8;
    reg signed [SIZE-1:0] bias;

    // Outputs
    wire [SIZE-1:0] out;
    wire valid_out;

    // Output tracking for display
    reg [3:0] test_count;

    // Instantiate the Unit Under Test (UUT)
    Convulation #(
        .SIZE(SIZE)
    ) uut (
        .clk(clk), .reset(reset), .pixel_valid_in(pixel_valid_in),
        .p0(p0), .p1(p1), .p2(p2), .p3(p3), .p4(p4), .p5(p5), .p6(p6), .p7(p7), .p8(p8),
        .w0(w0), .w1(w1), .w2(w2), .w3(w3), .w4(w4), .w5(w5), .w6(w6), .w7(w7), .w8(w8),
        .bias(bias), .out(out), .valid_out(valid_out)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus block
    initial begin
        // Initialize
        reset = 0;
        pixel_valid_in = 0;
        test_count = 1;
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = 0;
        {w0,w1,w2,w3,w4,w5,w6,w7,w8} = 0;
        bias = 0;

        // Release Reset
        #15;
        reset = 1;
        @(posedge clk); 
        pixel_valid_in = 1;

        // --- Case 1: Normal Math --- (Expected: 95)
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = {9{8'd10}};
        {w0,w1,w2,w3,w4,w5,w6,w7,w8} = {9{8'sd1}};
        bias = 8'sd5;
        @(posedge clk); 

        // --- Case 2: Negative (ReLU) --- (Expected: 0)
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = {9{8'd20}};
        {w0,w1,w2,w3,w4,w5,w6,w7,w8} = {9{-8'sd1}}; 
        bias = -8'sd10;
        @(posedge clk); 

        // --- Case 3: Large (Saturation) --- (Expected: 255)
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = {9{8'd50}};
        {w0,w1,w2,w3,w4,w5,w6,w7,w8} = {9{8'sd2}};
        bias = 8'sd0;
        @(posedge clk); 

        // --- Case 4: Absolute Zeros --- (Expected: 0)
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = {9{8'd0}};
        {w0,w1,w2,w3,w4,w5,w6,w7,w8} = {9{8'sd0}};
        bias = 8'sd0;
        @(posedge clk); 

        // --- Case 5: Max Possible Positives --- (Expected: 255)
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = {9{8'd255}};
        {w0,w1,w2,w3,w4,w5,w6,w7,w8} = {9{8'sd127}};
        bias = 8'sd127;
        @(posedge clk); 

        // --- Case 6: Max Possible Negatives --- (Expected: 0)
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = {9{8'd255}};
        {w0,w1,w2,w3,w4,w5,w6,w7,w8} = {9{-8'sd128}};
        bias = -8'sd128;
        @(posedge clk); 

        // --- Case 7: Mixed Weights Cancellation --- (Expected: 10)
        // 5 positive weights (+50), 4 negative weights (-40). Total = 10.
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = {9{8'd10}};
        w0=1; w1=-1; w2=1; w3=-1; w4=1; w5=-1; w6=1; w7=-1; w8=1;
        bias = 8'sd0;
        @(posedge clk); 

        // --- Case 8: Exact Upper Boundary (255) --- (Expected: 255)
        // 9 pixels of 25 * 1 = 225. Plus 30 bias = 255 exactly.
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = {9{8'd25}};
        {w0,w1,w2,w3,w4,w5,w6,w7,w8} = {9{8'sd1}};
        bias = 8'sd30;
        @(posedge clk); 

        // --- Case 9: Exact Lower Boundary (0) --- (Expected: 0)
        // Four +1s (80), four -1s (-80), one 0 (0). Total = 0 exactly.
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = {9{8'd20}};
        w0=1; w1=1; w2=1; w3=1; w4=-1; w5=-1; w6=-1; w7=-1; w8=0;
        bias = 8'sd0;
        @(posedge clk); 

        // --- Case 10: Realistic Edge Detection Filter --- (Expected: 210)
        // Top row dark (50), middle row black (0), bottom row bright (100).
        // Applied to a Sobel Horizontal Edge filter.
        p0=50;  p1=50;  p2=50;
        p3=0;   p4=0;   p5=0;
        p6=100; p7=100; p8=100;
        w0=-1; w1=-2; w2=-1; 
        w3=0;  w4=0;  w5=0;  
        w6=1;  w7=2;  w8=1;  
        bias = 8'sd10;
        // Math: 50*(-4) + 0 + 100*(4) + 10 = -200 + 400 + 10 = 210.
        
        @(posedge clk);
        pixel_valid_in = 0; // Stop feeding data

        // Wait for pipeline to empty
        #50;
        $finish;
    end

    // Monitor Block
    always @(posedge clk) begin
        if (valid_out) begin
            $display("Test Case %0d | Output = %d", test_count, out);
            test_count = test_count + 1;
        end
    end

endmodule