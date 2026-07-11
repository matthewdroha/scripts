//ALU : p2v0
module alu_gray_code(
  input_binary,
  output_gray);
  
  parameter ALU_ENABLE_GRAYCODE = 1;

  input  logic [3:0] input_binary;
  output logic [3:0] output_gray;

  generate
    if(ALU_ENABLE_GRAYCODE == 1)
      begin: gray_converter
        assign output_gray[3] = input_binary[3];
        assign output_gray[2] = input_binary[3] ^ input_binary[2];
        assign output_gray[1] = input_binary[2] ^ input_binary[1];
        assign output_gray[0] = input_binary[1] ^ input_binary[0];
    end
  endgenerate

endmodule
