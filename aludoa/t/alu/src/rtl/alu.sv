//ALU : p2v0
module alu(`include "alu_ports_declaration.sv");
  `include "alu_params.sv"
  `include "alu_ports_definition.sv"
  logic [ALU_WIDTH:0]       adder_output, subtractor_output;
  logic [ALU_WIDTH-1:0]     input_set1_local, input_set2_local;
  logic [ALU_WIDTH:0]       output_set12_local;
  logic                 select_local;
  logic [3:0]           input_binary_local;
  logic [3:0]           output_gray_local;
  logic [ALU_WIDTH-1:0]     input_set3_local, input_set4_local;
  logic [(2*ALU_WIDTH)-1:0] output_set34_local;

  generate
    if((ALU_ENABLE_ADDER == 0) && (ALU_ENABLE_SUBTRACTOR == 0)) begin
      logic [ALU_WIDTH-1:0] input_set1, input_set2;
      logic [ALU_WIDTH:0]   output_set12;
      assign input_set1_local = input_set1;
      assign input_set2_local = input_set2;
      assign output_set12     = output_set12_local;
      assign select_local     = select;
    end
  endgenerate

  generate
    if((ALU_ENABLE_ADDER == 1) || (ALU_ENABLE_SUBTRACTOR == 1)) begin
      assign input_set1_local = input_set1;
      assign input_set2_local = input_set2;
      assign output_set12     = output_set12_local;
      assign select_local     = select;
    end
  endgenerate

  generate
    if(ALU_ENABLE_GRAYCODE == 0) begin
      logic [3:0] input_binary;
      logic [3:0] output_gray;
      assign input_binary_local = input_binary;
      assign output_gray        = output_gray_local;
    end
  endgenerate

  generate
    if(ALU_ENABLE_MULTIPLIER == 0) begin
      logic [ALU_WIDTH-1:0] input_set3, input_set4;
      logic [ALU_WIDTH:0]   output_set34;
      assign input_set3_local = input_set3;
      assign input_set4_local = input_set4;
      assign output_set34     = output_set34_local;
    end
  endgenerate

  generate
  if(ALU_ENABLE_ADDER == 1)
    begin: adder
      alu_adder #(.ALU_WIDTH(ALU_WIDTH))
      alu_adder_inst (
        .input_set1(input_set1_local),
        .input_set2(input_set2_local),
        .adder_output(adder_output));
    end
  endgenerate

  generate
  if(ALU_ENABLE_SUBTRACTOR == 1)
    begin: subtractor
      alu_subtractor #(.ALU_WIDTH(ALU_WIDTH))
      alu_subtractor_inst (
        .input_set1(input_set1_local),
        .input_set2(input_set2_local),
        .subtractor_output(subtractor_output));
    end
  endgenerate

  generate
    if((ALU_ENABLE_ADDER == 1) && (ALU_ENABLE_SUBTRACTOR == 1)) begin
      alu_mux #(.ALU_ENABLE_ADDER      (ALU_ENABLE_ADDER),
                .ALU_ENABLE_SUBTRACTOR (ALU_ENABLE_SUBTRACTOR))
      alu_mux_inst (.adder_output(adder_output),
                    .subtractor_output(subtractor_output),
                    .select(select_local),
                    .output_set12(output_set12_local));
    end else if ((ALU_ENABLE_ADDER == 1) && (ALU_ENABLE_SUBTRACTOR == 0)) begin
      assign output_set12_local = adder_output;
    end else if ((ALU_ENABLE_ADDER == 0) && (ALU_ENABLE_SUBTRACTOR == 1)) begin
      assign output_set12_local = subtractor_output;
    end else if ((ALU_ENABLE_ADDER == 0) && (ALU_ENABLE_SUBTRACTOR == 0)) begin
      assign output_set12_local = {(ALU_WIDTH){1'b0}};
    end

  endgenerate

  generate
    if(ALU_ENABLE_GRAYCODE == 1) begin
      assign input_binary_local = input_binary;

      alu_gray_code #(.ALU_ENABLE_GRAYCODE(ALU_ENABLE_GRAYCODE))
      alu_gray_code_inst (.input_binary(input_binary_local),
                          .output_gray(output_gray_local));
      assign output_gray        = output_gray_local;
    end
  endgenerate

  generate
  if(ALU_ENABLE_MULTIPLIER == 1)
    begin: multiplier
    assign input_set3_local = input_set3;
    assign input_set4_local = input_set4;

      alu_multiplier #(.ALU_WIDTH(ALU_WIDTH))
      alu_multiplier_inst (
        .input_set3(input_set3_local),
        .input_set4(input_set4_local),
        .multiplier_output(output_set34_local));
    assign output_set34     = output_set34_local;
    end
  endgenerate

endmodule
