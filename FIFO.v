`timescale 1ns / 1ps
module FIFO #(parameter Data_size=16,Depth=28 )
(input [Data_size-1:0]in,
input clk,
input write,
output  [Data_size-1:0]out);
integer i;
reg [Data_size-1:0] memory[0:Depth-1];//memory 
always @(posedge clk)
begin
    if(write) begin
        for( i=0;i<Depth-1;i=i+1) begin
            memory[i+1]<=memory[i];
        end
        memory[0]<=in;
    end
end
assign out=memory[Depth-1];
endmodule
