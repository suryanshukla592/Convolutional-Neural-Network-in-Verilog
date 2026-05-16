`timescale 1ns / 1ps
module conv_layer1 #(parameter SIZE=8, IMAGE_WIDTH=28, FILTER=8, b_size=26)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [SIZE-1:0] in,
    output reg [SIZE-1:0] out1, out2, out3,out4,out5,out6,out7,out8,
    output reg [FILTER-1:0] valid_out
    );
//pixcel generated from the window_sliding
wire [SIZE-1:0] p_0_0, p_0_1, p_0_2, p_1_0, p_1_1, p_1_2, p_2_0, p_2_1, p_2_2;
wire [FILTER-1:0]valid_out_filter;
wire valid_out_sw;
wire signed [SIZE-1:0]out_filter [0:FILTER-1];
reg signed [SIZE-1:0]conv1_weights[0:10*FILTER-1];
// weight reading
initial begin
$readmemh("conv1_weights.mem", conv1_weights);// array name should be same as the .mem file name
end
// Module instantiation  
//Sliding Window  
Window_3x3 #(.SIZE(SIZE), .IMAGE_WIDTH(IMAGE_WIDTH)) W(.clk(clk),.rst(rst),.valid_in(valid_in),
        .in(in),.p_0_0(p_0_0), .p_0_1(p_0_1), .p_0_2(p_0_2), .p_1_0(p_1_0), .p_1_1(p_1_1),
         .p_1_2(p_1_2), .p_2_0(p_2_0), .p_2_1(p_2_1), .p_2_2(p_2_2), .valid_out(valid_out_sw));
//FILTER
genvar i;
generate 
    for(i=0; i<FILTER; i=i+1) begin
        wire signed [SIZE-1:0]w0,w1,w2,w3,w4,w5,w6,w7,w8,bias;
        assign w0=conv1_weights[i];
        assign w1=conv1_weights[i+8];
        assign w2=conv1_weights[i+16];
        assign w3=conv1_weights[i+24];
        assign w4=conv1_weights[i+32];
        assign w5=conv1_weights[i+40];
        assign w6=conv1_weights[i+48];
        assign w7=conv1_weights[i+56];
        assign w8=conv1_weights[i+64];
        assign bias=conv1_weights[i+72];
        Filter #( .SIZE(SIZE), .b_size(b_size)) F(.clk(clk),.rst(rst),
                .valid_in(valid_out_sw),.w0(w0),.w1(w1),.w2(w2),.w3(w3),.w4(w4),.w5(w5),.w6(w6),
                .w7(w7),.w8(w8),.bias(bias),.p_0_0(p_0_0), .p_0_1(p_0_1), .p_0_2(p_0_2), .p_1_0(p_1_0),
                .p_1_1(p_1_1),.p_1_2(p_1_2),.p_2_0(p_2_0), .p_2_1(p_2_1), .p_2_2(p_2_2),
                .out(out_filter[i]), .valid_out(valid_out_filter[i]));
    end
endgenerate
always @(posedge clk)
begin
    if(!rst) begin
       out1<=0; out2<=0; out3<=0; out4<=0; out5<=0; out6<=0; out7<=0; out8<=0;
       valid_out<=0; 
    end
    else if(&valid_out_filter) begin
        out1<=out_filter[0]; out2<=out_filter[1]; out3<=out_filter[2]; out4<=out_filter[3];
        out5<=out_filter[4]; out6<=out_filter[5]; out7<=out_filter[6]; out8<=out_filter[7];
        valid_out<=valid_out_filter;   
    end
    else begin
        valid_out<=0;
    end
end    
endmodule
