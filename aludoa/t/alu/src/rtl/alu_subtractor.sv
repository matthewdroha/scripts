//ALU : p2v0
module alu_subtractor(
  input_set1,
  input_set2,
  subtractor_output);
  
  parameter ALU_WIDTH=4;

  input  logic [ALU_WIDTH-1:0]     input_set1,input_set2;
  output logic [ALU_WIDTH:0]       subtractor_output;

  assign subtractor_output = input_set1 - input_set2;

endmodule
