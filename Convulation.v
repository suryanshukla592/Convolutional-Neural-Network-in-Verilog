`timescale 1ns / 1ps
module Convulation#(parameter SIZE=8)
(
input clk,
input reset,
// the window may not be ready at the start of conv., pixel data would be wrong.
input pixel_valid_in,//input form window is correct
input [SIZE-1:0]p0,p1,p2,p3,p4,p5,p6,p7,p8,
input signed [SIZE-1:0]w0,w1,w2,w3,w4,w5,w6,w7,w8,
input signed [SIZE-1:0] bias,
output reg [SIZE-1:0]out,// new pixel size
output reg valid_out
    );
// +4 bits, since on addition of 9 such numbers, r_net will overflow
reg signed [2*SIZE-1+4:0]r_sum,sum0, sum1, sum2;
reg valid_stage0, valid_stage1,valid_stage2;
reg signed [2*SIZE-1:0]r0,r1,r2,r3,r4,r5,r6,r7,r8;
//stage0: Multiplication
reg signed [SIZE-1:0] bias_reg;// bias acts as the sensitivity dial for the filter
always @(posedge clk)
begin
    if(!reset) begin
        valid_stage0<=0;
        bias_reg<=0;
        r0<=0; r1<=0; r2<=0; r3<=0; r4<=0; r5<=0; r6<=0; r7<=0; r8<=0;
    end
    else begin
        r0<=$signed({1'b0,p0})*w0;
        r1<=$signed({1'b0,p1})*w1;
        r2<=$signed({1'b0,p2})*w2;
        r3<=$signed({1'b0,p3})*w3;
        r4<=$signed({1'b0,p4})*w4;
        r5<=$signed({1'b0,p5})*w5;
        r6<=$signed({1'b0,p6})*w6;
        r7<=$signed({1'b0,p7})*w7;
        r8<=$signed({1'b0,p8})*w8;
        bias_reg<=bias;
        valid_stage0<=pixel_valid_in; 
    end  
end
//stage1: Addition tree, to facilitate the hardware implementation
//breaking down 9 addition over 3 clock cycles.
always @(posedge clk)
begin
    if(!reset) begin
        sum0<=0; sum1<=0; sum2<=0; valid_stage1<=0;
    end
    else begin
        sum0<=r0+r1+r2;
        sum1<=r3+r4+r5;
        sum2<=r6+r7+r8+bias_reg;
        valid_stage1<=valid_stage0;
    end
end
always @(posedge clk)
begin
    if(!reset) begin
        r_sum<=0; valid_stage2<=0;
    end
    else begin
        r_sum<=sum0+sum1+sum2;
        valid_stage2<=valid_stage1;
    end
end
// stage2: ReLu and saturation
always @(posedge clk)
begin
    if(!reset) begin
        valid_out<=0;
        out<=0;
    end
    else begin
        valid_out<=valid_stage2;
        if(valid_stage2) begin
            if(r_sum[2*SIZE+3]==1) out<=0; // ReLu, r_net is negative
            else if(|r_sum[2*SIZE+3:SIZE]) out<={SIZE{1'b1}};//number is big
            else out<=r_sum[SIZE-1:0];
        end
    end
end
endmodule
