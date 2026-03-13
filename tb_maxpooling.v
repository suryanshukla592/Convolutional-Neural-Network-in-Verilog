`timescale 1ns / 1ps
module tb_maxpooling #(parameter Data_size=8, b_size=26);
    wire [Data_size-1:0]out;
    wire valid_out;
    reg [Data_size-1:0]pixel_in;
    reg clk;
    reg valid_in;
    reg reset;
    
Pooling #(.Data_size(Data_size),.b_size(b_size))
          P(.clk(clk),.reset(reset),.valid_out(valid_out),
          .valid_in(valid_in),.pixel_in(pixel_in),.out(out));
initial begin
    clk=0;
    forever #1 clk=~clk;
end
integer i=0;
initial begin
    reset=0;
    valid_in=0;
    pixel_in=0;
    #5;
    reset=1;
    #2;
    valid_in=1;
    for (i=0;i<b_size*b_size;i=i+1) // max value of i=255
    begin
        pixel_in=i;
        #2;
    end
    valid_in=0;
    pixel_in=0;
    #5;
    $finish;
end

always @(posedge clk)
begin
    if(valid_out) begin
        $display("Time: %0t ns ", $time);
        $display("MAX_POOL: %3d \n", out);
    end
end
endmodule
