`timescale 1ns / 1ps

module Filter#(parameter  SIZE=8, b_size=26)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input [SIZE-1:0] p_0_0, p_0_1, p_0_2, p_1_0, p_1_1, p_1_2, p_2_0, p_2_1, p_2_2,
    //filter
    input signed [SIZE-1:0]w0,w1,w2,w3,w4,w5,w6,w7,w8,bias,
    output reg [SIZE-1:0] out,
    output reg valid_out
    );    
//output of convolution
wire [SIZE-1:0]con_out, pool_out;
wire valid_out_con, valid_out_pool;
//module instantiation
// Convolution          
Convulation #(.SIZE(SIZE)) C(.clk(clk),.reset(rst),.pixel_valid_in(valid_in),.p0(p_0_0), .p1(p_0_1),
         .p2(p_0_2), .p3(p_1_0), .p4(p_1_1),.p5(p_1_2), .p6(p_2_0), .p7(p_2_1),
         .p8(p_2_2),.w0(w0),.w1(w1),.w2(w2),.w3(w3),.w4(w4),.w5(w5),.w6(w6),.w7(w7),.w8(w8),
         .bias(bias),.valid_out(valid_out_con), .out(con_out));
//Down-Sampling: Max Pooling
Pooling #(.Data_size(SIZE), .b_size(b_size)) P(.clk(clk),.reset(rst),.valid_in(valid_out_con),
        .pixel_in(con_out), .out(pool_out), .valid_out(valid_out_pool));

always @(posedge clk)
begin
    if(!rst) begin
        out<=0; valid_out<=0;
    end
    else if(valid_out_pool) begin
        out<=pool_out;
        valid_out<=1;
    end
    else begin
        valid_out<=0;out<=0;
    end    
end
endmodule
