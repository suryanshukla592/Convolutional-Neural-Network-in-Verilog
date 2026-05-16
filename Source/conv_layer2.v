`timescale 1ns / 1ps
module conv_layer2 #(parameter SIZE=8, IMAGE_WIDTH=13, FILTER=16, b_size=11, FRAC_BITS=8)(
    input wire clk,
    input wire rst,
    input wire [7:0] valid_in,
    input wire [SIZE-1:0] in1,in2,in3,in4,in5,in6,in7,in8,
    output reg [SIZE-1:0] out1, out2, out3,out4,out5,out6,out7,out8,
                          out9,out10,out11,out12, out13, out14, out15, out16,
    output reg [FILTER-1:0] valid_out
    );
// 8(layers)*9(weights in one filter)+1(bias)=73
reg signed [SIZE-1:0]w2[0:73*FILTER-1]; //wieghts and biases
wire [SIZE-1:0] valid_out_sw;
wire [SIZE-1:0] p [0:73-1];//All pixels for one filter, from the window
//filter wires
wire [SIZE-1:0]filter_out[0:FILTER-1];
wire [FILTER-1:0]filter_out_valid;
initial begin
    $readmemh("w2.mem", w2);
end
wire [SIZE-1:0] in [0:7];
assign in[0]=in1;
assign in[1]=in2;
assign in[2]=in3;
assign in[3]=in4;
assign in[4]=in5;
assign in[5]=in6;
assign in[6]=in7;
assign in[7]=in8;
genvar i;
generate 
for(i=0; i<8 ; i=i+1) begin 
    Window_3x3 #(.SIZE(SIZE), .IMAGE_WIDTH(IMAGE_WIDTH)) W(.clk(clk),.rst(rst),.valid_in(valid_in[i]),
        .in(in[i]),.p_0_0(p[i+0]), .p_0_1(p[i+8]), .p_0_2(p[i+16]), .p_1_0(p[i+24]), .p_1_1(p[i+32]),
         .p_1_2(p[i+40]), .p_2_0(p[i+48]), .p_2_1(p[i+56]), .p_2_2(p[i+64]), .valid_out(valid_out_sw[i]));
     end
endgenerate 
genvar f;
generate 
    for(f=0;f<FILTER;f=f+1) begin : FILTER_LOGIC
        //Addition Tree Approch
        reg signed [2*SIZE-1:0] sum0[0:71];//All multiplication, Total=72
        reg signed [2*SIZE-1+1:0] sum1[0:35];//2 addtion at a time
        reg signed [2*SIZE-1+2:0] sum2[0:17];//2 addtion at a time
        reg signed [2*SIZE-1+3:0] sum3[0:8];//2 addtion at a time
        reg signed [2*SIZE-1+5:0] sum4[0:2];//3 addtion at a time(1 bit extra, since 3 addition)
        reg signed [2*SIZE-1+7:0] sum;//total sum + bias
        wire signed [2*SIZE-1+7:0] shifted_sum;// weights are multiplied by 256, therefore scaling down is needed
        assign shifted_sum = (sum >>> FRAC_BITS)+w2[f+72*16];
        // Valid pipeline shift registers
        reg v1, v2, v3, v4, v5, v6;
        reg final_valid;
        reg [SIZE-1:0] final_sum;
        wire [SIZE-1:0] final_out;
        wire final_valid_pool;
        integer k,l,m,n,q; 
        always @(posedge clk) 
        begin
            if(!rst) begin
                v1<=0;v2<=0;v3<=0;v4<=0;v5<=0;v6<=0;
            end
            else begin
                 for(k=0;k<72;k=k+1) begin//72 multiplication
                    sum0[k]<=$signed({1'b0,p[k]})*w2[f+16*k];
                 end
                 v1<=(&valid_out_sw);
                 
                 for(l=0;l<36;l=l+1) begin//36 addition
                    sum1[l]<=sum0[2*l]+sum0[2*l+1];
                 end
                 
                 v2<=v1;
                 for(m=0;m<18;m=m+1) begin//18 addition
                    sum2[m]<=sum1[2*m]+sum1[2*m+1];
                 end
                 v3<=v2;
                 
                 for(n=0;n<9;n=n+1) begin//9 addition
                    if (2*n+1<18)
                        sum3[n]<=sum2[2*n]+sum2[2*n+1];
                    else
                        sum3[n]<=sum2[2*n]; //Catch the odd one out
                 end
                 v4<=v3;
                 
                 for(q=0;q<3;q=q+1) begin//6 addition
                    sum4[q]<=sum3[3*q]+sum3[3*q+1]+sum3[3*q+2];
                 end
                 v5<=v4;
                 sum<=sum4[0]+sum4[1]+sum4[2];//bias
                 v6<=v5;
                 //ReLu
                 final_valid<=v6;
                 if(shifted_sum[2*SIZE-1+7]==1'b1) begin// sum is negative
                    final_sum<=0;
                    end
                 else if(|shifted_sum[2*SIZE-1+6:SIZE]==1'b1) begin// sum is big positive number
                    final_sum<={SIZE{1'b1}};
                    end  
                 else begin
                    final_sum<=shifted_sum[SIZE-1:0];
                 end 
            end 
        end
        //Down-Sampling: Max Pooling
        Pooling #(.Data_size(SIZE), .b_size(b_size)) P(.clk(clk),.reset(rst),.valid_in(final_valid),
                .pixel_in(final_sum), .out(final_out), .valid_out(final_valid_pool));
        assign filter_out[f]=final_out;
        assign filter_out_valid[f]=final_valid_pool;
    end
endgenerate
// wires to output registers
always @(posedge clk) 
begin
    if (!rst) begin
       out1<=0; out2<=0; out3<=0; out4<=0; out5<=0; out6<=0; out7<=0; out8<=0;
       out9<=0; out10<=0; out11<=0; out12<=0; out13<=0; out14<=0; out15<=0; out16<=0;
       valid_out<=0; 
    end
    else if (&filter_out_valid)begin
        out1<=filter_out[0];
        out2<=filter_out[1];
        out3<=filter_out[2];
        out4<=filter_out[3];
        out5<=filter_out[4];
        out6<=filter_out[5];
        out7<=filter_out[6];
        out8<=filter_out[7];
        out9<=filter_out[8];
        out10<=filter_out[9];
        out11<=filter_out[10];
        out12<=filter_out[11];
        out13<=filter_out[12];
        out14<=filter_out[13];
        out15<=filter_out[14];
        out16<=filter_out[15];
        valid_out<=filter_out_valid;
    end
    else begin
        valid_out<=0;
    end
end          
endmodule
