// Design name : SRAM_top

module SRAM_Wrapper_top #(
	parameter WIDTH_WB_DATA = 32,
	parameter WIDTH_ADD = 32,
	parameter IMC_OUT_WIDTH = 64,
	parameter SRAM_OUT_WIDTH = 16,
	parameter MEM_ROW = 16
) (

inout VCLP,							// connect to Analog IO
inout EN,							// connect to Analog IO			
inout Iref0,							// connect to Analog IO
inout Iref1,							// connect to Analog IO
inout Iref2,							// connect to Analog IO
inout Iref3,							// connect to Analog IO
inout VDD,
inout VSS,

input clk,							//Common clock
input reset_n,							//wb_rst_i	
input wbs_we_i ,						//wbs_we_i=0 for read ;wbs_we_i=1 for write		
input [WIDTH_WB_DATA - 1 : 0] wishbone_buffer_data_in, 	//wbs_dat_i
input [WIDTH_ADD - 1 : 0] wishbone_rw_addr,			//wishbone_addr

output [WIDTH_WB_DATA - 1 : 0] wishbone_databus_out,	 	//wbs_dat_o
output EN_VCLP							//Deepak_28/11/22: needs to be passed to analog_DUT for EN & VCLP enable
								//currently taking out to LA
);

//=============================== Signal Declaration =========================================
			
wire [IMC_OUT_WIDTH -1 : 0] IMC_out;
wire [SRAM_OUT_WIDTH -1 : 0] SA_out;
wire [MEM_ROW -1 : 0] SRAM_Din;   				// RICHA : New!!
wire  PRE_SRAM;
wire  [MEM_ROW -1: 0] WWL;
wire  WE;
wire  PRE_VLSA;
wire  PRE_CLSA;
wire  PRE_A;
wire  [MEM_ROW -1: 0] RWL; 
wire  [MEM_ROW -1: 0] RWLB;
wire  SAEN; 
wire  EN_VCLP;							// RICHA : enable for EN and VCLP				
reg [7:0] WWLD;

//===========================================================================

//===========SRAM Controller Instantiation  =================================
top Digital_DUT(
.clk(clk),
.reset_n(reset_n),
.wbs_we_i(wbs_we_i),
.wishbone_buffer_data_in(wishbone_buffer_data_in),
.wishbone_rw_addr(wishbone_rw_addr),
.wishbone_databus_out(wishbone_databus_out),
.IMC_out(IMC_out),
.SA_out(SA_out),
.SRAM_Din(SRAM_Din),
.PRE_SRAM(PRE_SRAM),
.WWL(WWL),
.WE(WE),
.PRE_VLSA(PRE_VLSA), 
.PRE_CLSA(PRE_CLSA), 
.PRE_A(PRE_A),
.RWL(RWL), 
.RWLB(RWLB),
.SAEN(SAEN), 
.en(EN_VCLP),	
.WWLD(WWLD)
);

//===========================================================================
//============================ SRAM Array Analog part instantiation =========

Integrated_bitcell_with_dummy_cells  Analog_DUT (
.WWL(WWL),
.WWLD(WWLD),
.RWL(RWL),
.RWLB(RWLB),
.Din(SRAM_Din),
.WE(WE), 
.PRE_SRAM(PRE_SRAM),
.PRE_VLSA(PRE_VLSA), 
.PRE_CLSA(PRE_CLSA),
.PRE_A(PRE_A), 
.SAEN(SAEN),
.VCLP(VCLP),
.EN(EN),
.Iref0(Iref0), 
.Iref1(Iref1), 
.Iref2(Iref2),
.Iref3(Iref3),
.VSS(VSS),
.VDD(VDD),
.ADC0_OUT(IMC_out[3:0]),
.ADC1_OUT(IMC_out[7:4]),
.ADC2_OUT(IMC_out[11:8]),
.ADC3_OUT(IMC_out[15:12]),
.ADC4_OUT(IMC_out[19:16]),
.ADC5_OUT(IMC_out[23:20]),
.ADC6_OUT(IMC_out[27:24]),
.ADC7_OUT(IMC_out[31:28]),
.ADC8_OUT(IMC_out[35:32]),
.ADC9_OUT(IMC_out[39:36]),
.ADC10_OUT(IMC_out[43:40]),
.ADC11_OUT(IMC_out[47:44]),
.ADC12_OUT(IMC_out[51:48]),
.ADC13_OUT(IMC_out[55:52]),
.ADC14_OUT(IMC_out[59:56]),
.ADC15_OUT(IMC_out[63:60]),
.SA_OUT(SA_out)
);

//===========================================================================
endmodule
