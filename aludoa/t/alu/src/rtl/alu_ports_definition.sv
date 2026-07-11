//ALU : p2v0
input  logic [ALU_WIDTH-1:0]     input_set1,input_set2;
input  logic [ALU_WIDTH-1:0] input_set3,input_set4; 
input  logic                 select;
input  logic [3:0]           input_binary;
output logic [ALU_WIDTH:0]       output_set12;
output logic [3:0]           output_gray;
output logic [(2*ALU_WIDTH)-1:0] output_set34;
