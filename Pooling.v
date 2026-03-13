`timescale 1ns / 1ps

module Pooling #(parameter Data_size=8, b_size=26)
(
    input clk,
    input reset,
    input [Data_size-1:0] pixel_in,
    input valid_in,
    output reg [Data_size-1:0] out,
    output reg valid_out
);
// Buffer to store the even row 
reg [Data_size-1:0] Buffer0 [0:b_size-1]; 
// Registers
reg [Data_size-1:0] previous_odd_pixel, previous_even_pixel;
reg [$clog2(b_size):0] row_count, col_count; // Range: 0 to 25
// Wires for combinational logic
wire [Data_size-1:0] current_odd_pixel, current_even_pixel;
wire [Data_size-1:0] max_even, max_odd;
// Current pixels (Right side of the 2x2 window)
assign current_even_pixel = Buffer0[col_count];
assign current_odd_pixel  = pixel_in;
// Max logic for the rows
assign max_even = (current_even_pixel > previous_even_pixel) ? current_even_pixel : previous_even_pixel;
assign max_odd  = (current_odd_pixel > previous_odd_pixel) ? current_odd_pixel : previous_odd_pixel;
// Final max logic combining both rows
wire [Data_size-1:0] final_max = (max_even > max_odd) ? max_even : max_odd;
always @(posedge clk) begin
    if(!reset) begin
        row_count <=0;
        col_count <=0;
        valid_out <=0;
        out <= 0;
        previous_even_pixel <= 0;
        previous_odd_pixel <= 0;
    end
    else if(valid_in) begin  
        //Grid Counter Update
        if(col_count == b_size-1) begin
            col_count <= 0;
            row_count <= row_count + 1;
        end
        else begin
            col_count <= col_count + 1;
        end
        //Pooling Logic
        if(row_count[0] == 1'b0) begin // Row is even
            //Just stream data into the buffer
            Buffer0[col_count] <= pixel_in;
            valid_out <= 0;
        end
        else begin
            // ODD ROW: Computation Time
            if(col_count[0] == 1'b0) begin
                //LEFT SIDE OF WINDOW (Column is Even)
                previous_even_pixel <= current_even_pixel; //Top-Left
                previous_odd_pixel  <= current_odd_pixel;  //Bottom-Left
                valid_out <= 0;
            end
            else begin
                // Right Side of the Window
                out <= final_max;
                valid_out <= 1;
            end
        end
    end
    else begin
        valid_out <= 0;
    end
end
endmodule