module Integrated_bitcell_with_dummy_cells (
WWL,
WWLD,
RWL,
RWLB,
Din, 
WE, PRE_SRAM,PRE_VLSA, 
SA_OUT, 
SAEN,VCLP,PRE_CLSA, 
PRE_A, EN,
VDD,VSS,
ADC0_OUT,
ADC1_OUT,
ADC2_OUT,
ADC3_OUT,
ADC4_OUT,
ADC5_OUT,
ADC6_OUT,
ADC7_OUT,
ADC8_OUT,
ADC9_OUT,
ADC10_OUT,
ADC11_OUT,
ADC12_OUT,
ADC13_OUT,
ADC14_OUT,
ADC15_OUT,
Iref0,
Iref1, 
Iref2,
Iref3
);

input [15:0] WWL;
input [7:0] WWLD;
input [15:0] RWL;
input [15:0] RWLB; 
input [15:0]Din;
input WE;
input PRE_SRAM ;
input PRE_VLSA;
input PRE_CLSA;
input PRE_A;
input SAEN;
inout VCLP;
inout EN;
inout Iref0; 
inout Iref1; 
inout Iref2;
inout Iref3;
inout VSS, VDD;
output reg [3:0] ADC0_OUT;
output reg [3:0] ADC1_OUT;
output reg [3:0] ADC2_OUT;
output reg [3:0] ADC3_OUT;
output reg [3:0] ADC4_OUT;
output reg [3:0] ADC5_OUT;
output reg [3:0] ADC6_OUT;
output reg [3:0] ADC7_OUT;
output reg [3:0] ADC8_OUT;
output reg [3:0] ADC9_OUT;
output reg [3:0] ADC10_OUT;
output reg [3:0] ADC11_OUT;
output reg [3:0] ADC12_OUT;
output reg [3:0] ADC13_OUT;
output reg [3:0] ADC14_OUT;
output reg [3:0] ADC15_OUT;
output reg [15:0]  SA_OUT;

endmodule
