`timescale 1ns / 1ps
module argsmax (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire signed [31:0] n0, n1, n2, n3, n4, n5, n6, n7, n8, n9,
    output reg [3:0] prediction,
    output reg valid_out
);
reg signed [31:0] max_val;
reg [3:0] max_idx;
always @(posedge clk) begin
    if (!rst) begin
        prediction <= 4'd0;
        valid_out  <= 1'b0;
    end else begin
        valid_out <= valid_in;
        if (valid_in) begin
            max_val=n0;
            max_idx=4'd0;
            // Compare against all other numbers
            if (n1 > max_val) begin max_val=n1; max_idx= 4'd1; end
            if (n2 > max_val) begin max_val=n2; max_idx= 4'd2; end
            if (n3 > max_val) begin max_val=n3; max_idx= 4'd3; end
            if (n4 > max_val) begin max_val=n4; max_idx= 4'd4; end
            if (n5 > max_val) begin max_val=n5; max_idx= 4'd5; end
            if (n6 > max_val) begin max_val=n6; max_idx= 4'd6; end
            if (n7 > max_val) begin max_val=n7; max_idx= 4'd7; end
            if (n8 > max_val) begin max_val=n8; max_idx= 4'd8; end
            if (n9 > max_val) begin max_val=n9; max_idx= 4'd9; end
            prediction <= max_idx;
        end
    end
end
endmodule
