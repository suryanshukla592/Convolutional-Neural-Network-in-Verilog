`timescale 1ns / 1ps
//Custom input is used for validation
module tb_dense_layer();

    // Parameters
    parameter SIZE = 8;
    parameter FRAC_BITS = 8;

    // Inputs
    reg clk;
    reg rst;
    reg [SIZE-1:0] in1, in2, in3, in4, in5, in6, in7, in8;
    reg [SIZE-1:0] in9, in10, in11, in12, in13, in14, in15, in16;
    reg valid_in;

    // Outputs
    wire signed [31:0] n0, n1, n2, n3, n4, n5, n6, n7, n8, n9;
    wire valid_out;

    // Instantiate the Unit Under Test (UUT)
    Dense_layer #(
        .SIZE(SIZE), 
        .FRAC_BITS(FRAC_BITS)
    ) uut (
        .clk(clk), 
        .rst(rst),
        .in1(in1), .in2(in2), .in3(in3), .in4(in4),
        .in5(in5), .in6(in6), .in7(in7), .in8(in8),
        .in9(in9), .in10(in10), .in11(in11), .in12(in12),
        .in13(in13), .in14(in14), .in15(in15), .in16(in16),
        .valid_in(valid_in),
        .n0(n0), .n1(n1), .n2(n2), .n3(n3), .n4(n4),
        .n5(n5), .n6(n6), .n7(n7), .n8(n8), .n9(n9),
        .valid_out(valid_out)
    );

    // Clock Generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;

    // Stimulus process
    initial begin
        // 1. Initialize Inputs & Reset
        rst = 0;
        valid_in = 0;
        in1=0; in2=0; in3=0; in4=0; in5=0; in6=0; in7=0; in8=0;
        in9=0; in10=0; in11=0; in12=0; in13=0; in14=0; in15=0; in16=0;

        #100;
        rst = 1;
        #20;

        $display("--- Sending 25 cycles of 5x5 feature map data ---");
        
        // 2. Transmit 25 cycles of data to fill the FLATTEN arrays
        for (i = 0; i < 25; i = i + 1) begin
            @(posedge clk);
            valid_in <= 1'b1;
            in1  <= 8'd6;
            in2  <= 8'd6;
            in3  <= 8'd0;
            in4  <= 8'd0;
            in5  <= 8'd0;
            in6  <= 8'd5;
            in7  <= 8'd0;
            in8  <= 8'd0;
            in9  <= 8'd3;
            in10 <= 8'd0;
            in11 <= 8'd0;
            in12 <= 8'd0;
            in13 <= 8'd0;
            in14 <= 8'd0;
            in15 <= 8'd24;
            in16 <= 8'd0;
        end

        // 3. De-assert valid_in and wait for FSM to calculate
        @(posedge clk);
        valid_in <= 1'b0;

        $display("--- Data sent. Waiting ~400 cycles for MULTIPLY and ADD phases ---");

        // The MULTIPLY state takes 400 clock cycles alone. 
        // We wait long enough for the pipeline to hit the DONE state.
        #5000; 
        
        $display("--- Simulation Finished ---");
        $finish;
    end

    // Output Monitor
    always @(posedge clk) begin
        if (valid_out) begin
            $display("========================================");
            $display("DENSE LAYER VALID OUT TRIGGERED!");
            $display("Node 0: %0d", n0);
            $display("Node 1: %0d", n1);
            $display("Node 2: %0d", n2);
            $display("Node 3: %0d", n3);
            $display("Node 4: %0d", n4);
            $display("Node 5: %0d", n5);
            $display("Node 6: %0d", n6);
            $display("Node 7: %0d", n7);
            $display("Node 8: %0d", n8);
            $display("Node 9: %0d", n9);
            $display("========================================");
        end
    end

endmodule
