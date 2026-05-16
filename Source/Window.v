`timescale 1ns / 1ps
module Window_3x3 #(parameter SIZE= 8,IMAGE_WIDTH= 28)(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [SIZE-1:0] in,
    output reg [SIZE-1:0] p_0_0, p_0_1, p_0_2,
    output reg [SIZE-1:0] p_1_0, p_1_1, p_1_2,
    output reg [SIZE-1:0] p_2_0, p_2_1, p_2_2,
    output reg valid_out);
wire [SIZE-1:0] lb1_out,lb2_out;
//lb_count will ensure that it will stream data only when both line buffers are filled
reg [$clog2(IMAGE_WIDTH)+1:0]lb_count;
reg [$clog2(IMAGE_WIDTH):0]count;//column count
reg [$clog2(IMAGE_WIDTH):0]rowcount;
// 3rd row is used and  being stored at same time simulaneouly in the LB1.
FIFO #(.Data_size(SIZE),.Depth(IMAGE_WIDTH)) 
    LB1(.in(in),.clk(clk),.write(valid_in),.out(lb1_out));
FIFO #(.Data_size(SIZE),.Depth(IMAGE_WIDTH)) //output of lb1 to input of lb2
    LB2(.in(lb1_out),.clk(clk),.write(valid_in),.out(lb2_out));
always @(posedge clk) 
begin
    if(!rst) begin valid_out<=0; count<=0; lb_count<=0; rowcount<=0; end
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
        if (count==IMAGE_WIDTH-1) begin
            count<=0;
            // Row finished. Check if it's the end of the image!
            if (rowcount == IMAGE_WIDTH - 1) begin
                rowcount <= 0;
                //RESET: Pauses valid_out for the next image's first 2 rows
                lb_count <= 0;
            end else begin
                rowcount <= rowcount + 1;
                // Keep incrementing lb_count if buffers aren't full
                if (lb_count < 2*IMAGE_WIDTH) lb_count <= lb_count + 1;
            end
        end else begin
            count<=count+1;
            if (lb_count < 2 * IMAGE_WIDTH) lb_count <= lb_count + 1;
        end
        if(lb_count>=2*IMAGE_WIDTH) begin
            if(count>=2) valid_out<=1;
            else valid_out<=0;
            end
        else valid_out<=0;
    end
    else begin
        valid_out<=0;// 0, when data stream is off.(else no stop after start)
    end
end
endmodule
