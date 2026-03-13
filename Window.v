`timescale 1ns / 1ps
module Window_3x3 #(parameter DATA_WIDTH= 16,IMAGE_WIDTH= 28)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [DATA_WIDTH-1:0] in,
    output reg [DATA_WIDTH-1:0] p_0_0, p_0_1, p_0_2,
    output reg [DATA_WIDTH-1:0] p_1_0, p_1_1, p_1_2,
    output reg [DATA_WIDTH-1:0] p_2_0, p_2_1, p_2_2,
    output reg valid_out);
wire [DATA_WIDTH-1:0] lb1_out,lb2_out;
//lb_count will ensure that it will stream data only when both line buffers are filled
reg [$clog2(IMAGE_WIDTH)+1:0]lb_count;
reg [$clog2(IMAGE_WIDTH):0]count;
// 3rd row is used and  being stored at same time simulaneouly in the LB1.
FIFO #(.Data_size(DATA_WIDTH),.Depth(IMAGE_WIDTH)) 
    LB1(.in(in),.clk(clk),.write(valid_in),.out(lb1_out));
FIFO #(.Data_size(DATA_WIDTH),.Depth(IMAGE_WIDTH)) //output of lb1 to input of lb2
    LB2(.in(lb1_out),.clk(clk),.write(valid_in),.out(lb2_out));
always @(posedge clk) 
begin
    if(!rst) begin valid_out<=0; count<=0; lb_count<=0; end
    else if(valid_in) begin
         //Since the lb1 and lb2 are in series, therefore
        //Row 0(output of lb2)
        p_0_0<=p_0_1;
        p_0_1<=p_0_2;
        p_0_2<=lb2_out;
        //Row 1(output of lb1)
        p_1_0<=p_1_1;
        p_1_1<=p_1_2;
        p_1_2<=lb1_out;
        //Row 2
        p_2_0<=p_2_1;
        p_2_1<=p_2_2;
        p_2_2<=in;
        //logic for valid out
        if (lb_count<2*IMAGE_WIDTH) begin
            lb_count<=lb_count+1;
        end
        if (count==IMAGE_WIDTH-1) begin
            count<=0;
        end else begin
            count<=count+1;
        end
        if(lb_count>=2*IMAGE_WIDTH) begin
            if(count>=2) valid_out<=1;
            else valid_out<=0;
            end
        else valid_out<=0;
    end
end
endmodule
