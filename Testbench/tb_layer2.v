`timescale 1ns / 1ps
//Validation is done under specific input values
module tb_layer2();

    // Parameters
    parameter SIZE = 8;
    parameter IMAGE_WIDTH = 13;
    parameter FILTER = 16;
    parameter b_size = 11;
    parameter FRAC_BITS = 8;

    // Inputs
    reg clk;
    reg rst;
    reg [7:0] valid_in;
    reg [SIZE-1:0] in1, in2, in3, in4, in5, in6, in7, in8;

    // Outputs
    wire [SIZE-1:0] out1, out2, out3, out4, out5, out6, out7, out8;
    wire [SIZE-1:0] out9, out10, out11, out12, out13, out14, out15, out16;
    wire [FILTER-1:0] valid_out;

    // Instantiate UUT
    conv_layer2 #(
        .SIZE(SIZE), 
        .IMAGE_WIDTH(IMAGE_WIDTH), 
        .FILTER(FILTER), 
        .b_size(b_size),
        .FRAC_BITS(FRAC_BITS)
    ) uut (
        .clk(clk), .rst(rst), .valid_in(valid_in),
        .in1(in1), .in2(in2), .in3(in3), .in4(in4),
        .in5(in5), .in6(in6), .in7(in7), .in8(in8),
        .out1(out1), .out2(out2), .out3(out3), .out4(out4),
        .out5(out5), .out6(out6), .out7(out7), .out8(out8),
        .out9(out9), .out10(out10), .out11(out11), .out12(out12),
        .out13(out13), .out14(out14), .out15(out15), .out16(out16),
        .valid_out(valid_out)
    );

    // --- DEBUG PROBES (Hierarchical paths for Filter 1) ---
    // These allow you to see the internal sums before the ReLU and Shift
    wire signed [22:0] f1_raw_sum    = uut.FILTER_LOGIC[0].sum;
    wire signed [7:0] f1_shiftedsum    = uut.FILTER_LOGIC[0].shifted_sum;
    wire signed [22:0] f2_raw_sum    = uut.FILTER_LOGIC[1].sum;
    wire signed [22:0] f3_raw_sum    = uut.FILTER_LOGIC[2].sum;
    wire signed [22:0] f4_raw_sum    = uut.FILTER_LOGIC[3].sum;
    wire signed [22:0] f1_shifted    = uut.FILTER_LOGIC[0].shifted_sum;
    wire [SIZE-1:0]    f1_pre_pool   = uut.FILTER_LOGIC[0].final_sum;

    // Clock Generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;
    integer out_count = 0;

    initial begin
        // Reset sequence
        rst = 0;
        valid_in = 8'h00;
        in1=0; in2=0; in3=0; in4=0; in5=0; in6=0; in7=0; in8=0;
        
        #100;
        rst = 1;
        #20;

        $display("--- Starting Layer 2 Transmission: 169 Cycles ---");
        
        // Loop for 169 cycles (13x13 dataset)
        for (i = 0; i < 169; i = i + 1) begin
            @(posedge clk);
            valid_in <= 8'hFF; // All 8 input streams are valid
            in1 <= 8'h09;
            in2 <= 8'h00;
            in3 <= 8'h2D;
            in4 <= 8'h16;
            in5 <= 8'h03;
            in6 <= 8'h00;
            in7 <= 8'h00;
            in8 <= 8'h01;
        end

        // End of data
        @(posedge clk);
        valid_in <= 8'h00;
        
        $display("--- Data Sent. Waiting for Pipeline Flush ---");
        #2000;
        
        $display("--- Simulation Finished. Total Outputs: %0d ---", out_count);
        $finish;
    end

    // Monitor Output
    always @(posedge clk) begin
        if (&valid_out[3:0]) begin // Triggering on Filter 1 valid
            out_count = out_count + 1;
            $display("OUT:%d | Out1:%d Out2:%d Out3:%d Out4:%d Out5:%d Out6:%d Out7:%d Out8:%d Out9:%d Out10:%d Out11:%d Out12:%d Out13:%d Out14:%d Out15:%d Out16:%d",
                      out_count, out1, out2, out3, out4, out5, out6, out7, out8,
                      out9, out10, out11, out12, out13, out14, out15, out16);
        end
    end

endmodule
