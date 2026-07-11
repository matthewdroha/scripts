//ALU : p2v0
module alu_mux(
  adder_output,
  subtractor_output,
  output_set12,
  select);
  
  parameter ALU_WIDTH=4;
  parameter ALU_ENABLE_ADDER = 1;
  parameter ALU_ENABLE_SUBTRACTOR = 1;

  input  logic [ALU_WIDTH:0] adder_output,subtractor_output;
  input  logic           select;
  output logic [ALU_WIDTH:0] output_set12;

  generate
    if((ALU_ENABLE_ADDER == 1) && (ALU_ENABLE_SUBTRACTOR == 1)) begin
      assign output_set12 = (select == 1)? adder_output : subtractor_output;
    end else if (ALU_ENABLE_ADDER == 1) begin
      assign output_set12 = adder_output;
    end else if (ALU_ENABLE_SUBTRACTOR == 1) begin
      assign output_set12 = subtractor_output;
    end else begin
      assign output_set12 = {(ALU_WIDTH){1'b0}};
    end
  endgenerate

endmodule
