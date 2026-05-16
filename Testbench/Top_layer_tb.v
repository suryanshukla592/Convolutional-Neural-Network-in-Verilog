`timescale 1ns / 1ps
module Top_conv_layer#(parameter SIZE=8, FILTER1=8, FILTER2=16)( 
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [SIZE-1:0] in,
    output wire signed [31:0] n0,n1,n2,n3,n4,n5,n6,n7,n8,n9,
    output wire [3:0] prediction,
    output wire valid_out
    );
localparam b_size1=26, b_size2=11, IMAGE_WIDTH1=28, IMAGE_WIDTH2=13;
wire [SIZE-1:0] wout1, wout2, wout3,wout4,wout5,wout6,wout7,wout8; //wire for output internal connections
wire [SIZE-1:0] out1, out2, out3,out4,out5,out6,out7,out8,
                out9,out10,out11,out12, out13, out14, out15, out16;
wire [FILTER1-1:0] valid_out_L1;
wire [FILTER2-1:0] valid_out_L2;
wire valid_out_DL;
//Convolution Layer 1
// Add this right before your conv_layer1 instantiation
wire [SIZE-1:0] safe_in;
assign safe_in = {1'b0, in[SIZE-1:1]}; // Divides by 2. FF becomes 7F.
conv_layer1 #(.SIZE(SIZE), .IMAGE_WIDTH(IMAGE_WIDTH1), .FILTER(FILTER1), .b_size(b_size1)) CL1(
        .clk(clk),.rst(rst),.valid_in(valid_in),.in(safe_in), .out1(wout1), .out2(wout2), .out3(wout3), .out4(wout4),
        .out5(wout5), .out6(wout6), .out7(wout7), .out8(wout8), .valid_out(valid_out_L1));
//Convolution Layer 2
conv_layer2 #(.SIZE(SIZE), .IMAGE_WIDTH(IMAGE_WIDTH2), .FILTER(FILTER2), .b_size(b_size2)) CL2(
           .clk(clk),.rst(rst),.valid_in(valid_out_L1), .in1(wout1), .in2(wout2), .in3(wout3),.in4(wout4), 
           .in5(wout5), .in6(wout6), .in7(wout7), .in8(wout8), .out1(out1), .out2(out2), .out3(out3), .out4(out4),
           .out5(out5), .out6(out6), .out7(out7), .out8(out8), .out9(out9), .out10(out10), .out11(out11),
           .out12(out12), .out13(out13), .out14(out14), .out15(out15), .out16(out16), .valid_out(valid_out_L2));
Dense_layer #(.SIZE(SIZE)) DL(.clk(clk),.rst(rst),.valid_in((&valid_out_L2)), .in1(out1), .in2(out2),
             .in3(out3), .in4(out4), .in5(out5), .in6(out6), .in7(out7), .in8(out8), .in9(out9),
             .in10(out10), .in11(out11), .in12(out12), .in13(out13), .in14(out14), .in15(out15),
             .in16(out16), .n0(n0), .n1(n1), .n2(n2), .n3(n3), .n4(n4), .n5(n5), .n6(n6),.n7(n7), .n8(n8),
             .n9(n9), .valid_out(valid_out_DL));   
argsmax AM(
    .clk(clk), .rst(rst), .valid_in(valid_out_DL), .n0(n0), .n1(n1), .n2(n2),
    .n3(n3), .n4(n4), .n5(n5), .n6(n6), .n7(n7), .n8(n8), .n9(n9), .prediction(prediction),
    .valid_out(valid_out) // The final valid out for the whole chip
);       
endmodule
