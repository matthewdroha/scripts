//ALU : p2v0
module alu_multiplier (
  input_set3,
  input_set4,
  multiplier_output);
  
  parameter ALU_WIDTH=4;

  input  logic [ALU_WIDTH-1:0]     input_set3,input_set4;
  output logic [(2*ALU_WIDTH)-1:0] multiplier_output;

  assign multiplier_output = input_set3 * input_set4;

endmodule
