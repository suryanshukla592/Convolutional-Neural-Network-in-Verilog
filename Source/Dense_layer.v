`timescale 1ns / 1ps

module Dense_layer #(parameter SIZE=8, FRAC_BITS=8)(
    input clk,
    input rst,
    input [SIZE-1:0] in1,in2,in3,in4,in5,in6,in7,in8,
                     in9,in10,in11,in12,in13,in14,in15,in16,
    input  valid_in,
    output  reg signed [31:0]n0,n1,n2,n3,n4,n5,n6,n7,n8,n9,//Enough space, such that it does not overflow
    output reg valid_out
    );
reg signed [SIZE-1:0]dense_weights[0:4009];// 10*(16X5X5=400)+bias(10)=4010
initial begin
    $readmemh("dense_weights.mem", dense_weights);// weights are signed
end
reg [SIZE-1:0] FLATTEN[0:399];//Store all 400 pixels in a single array
reg signed [31:0] PRODUCT[0:9];//Store all 10 products in a single array
localparam IDEAL=0, FLAT=1 , MULTIPLY=2, ADD=3, DONE=4;
reg [2:0]stage;
integer i,j;
always @(posedge clk)
begin
    if(!rst) begin
        n0<=0; n1<=0; n2<=0; n3<=0; n4<=0; n5<=0; n6<=0; n7<=0; n8<=0; n9<=0;
        valid_out<=0; stage<=IDEAL;
        i<=0;
        for(j=0; j<10; j=j+1) PRODUCT[j] <= 0;
    end
    else begin
        case(stage)
        IDEAL: begin
               valid_out<=0;
               i<=0;
               for(j=0; j<10; j=j+1) PRODUCT[j] <= 0;
               if (valid_in) begin
                    //Capture the first bit at moment when valid_in is high
                    FLATTEN[0] <= in1; FLATTEN[1] <= in2; FLATTEN[2] <= in3;
                    FLATTEN[3] <= in4; FLATTEN[4] <= in5; FLATTEN[5] <= in6;
                    FLATTEN[6] <= in7; FLATTEN[7] <= in8; FLATTEN[8] <= in9;
                    FLATTEN[9] <= in10; FLATTEN[10] <= in11; FLATTEN[11] <= in12;
                    FLATTEN[12] <= in13; FLATTEN[13] <= in14; FLATTEN[14] <= in15;
                    FLATTEN[15] <= in16;
                    i<=1;
                    stage <= FLAT;
                end
                else begin
                    i<=0; end
               end
        FLAT: begin
               if(valid_in) begin
                   FLATTEN[0+16*i]<=in1;
                   FLATTEN[1+16*i]<=in2;
                   FLATTEN[2+16*i]<=in3;
                   FLATTEN[3+16*i]<=in4;
                   FLATTEN[4+16*i]<=in5;
                   FLATTEN[5+16*i]<=in6;
                   FLATTEN[6+16*i]<=in7;
                   FLATTEN[7+16*i]<=in8;
                   FLATTEN[8+16*i]<=in9;
                   FLATTEN[9+16*i]<=in10;
                   FLATTEN[10+16*i]<=in11;
                   FLATTEN[11+16*i]<=in12;
                   FLATTEN[12+16*i]<=in13;
                   FLATTEN[13+16*i]<=in14;
                   FLATTEN[14+16*i]<=in15;
                   FLATTEN[15+16*i]<=in16;
                   if(i==24) begin
                        stage<=MULTIPLY;
                        i<=0;
                   end
                   else begin
                        i<=i+1;
                   end
               end
           end
        MULTIPLY: begin
                  //10 multiplication per cycle, Total 400 cycles is required.
                  for(j=0; j<10; j=j+1) begin 
                      PRODUCT[j]<=PRODUCT[j]+ ($signed({1'b0,FLATTEN[i]})*dense_weights[j+10*i]);   
                  end  
                  if(i==399) begin
                      stage<=ADD;
                  end 
                  else i<=i+1;
                  end
             ADD: begin
                     for(j=0; j<10; j=j+1) begin
                          PRODUCT[j]<=(PRODUCT[j]>>> FRAC_BITS) + dense_weights[4000+j];
                      end
                      stage<=DONE;
                  end
             DONE: begin
                      n0<=PRODUCT[0]; n1<=PRODUCT[1]; n2<=PRODUCT[2]; n3<=PRODUCT[3]; n4<=PRODUCT[4];
                      n5<=PRODUCT[5]; n6<=PRODUCT[6]; n7<=PRODUCT[7]; n8<=PRODUCT[8]; n9<=PRODUCT[9];
                      valid_out<=1'b1;
                      stage<=IDEAL;
                   end
         default: begin
                  stage<=IDEAL;
                  end
        endcase
    end
end
endmodule
