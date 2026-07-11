//ALU : p2v0
module alu_adder(
  input_set1,
  input_set2,
  adder_output);
  
  parameter ALU_WIDTH=4;

  input  logic [ALU_WIDTH-1:0]     input_set1,input_set2;
  output logic [ALU_WIDTH:0]       adder_output;

  assign adder_output = input_set1 + input_set2;

endmodule
