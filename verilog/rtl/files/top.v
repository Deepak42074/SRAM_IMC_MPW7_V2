module top #(
	parameter WIDTH_WB_DATA = 32,
	parameter WIDTH_ADD = 32,
	parameter IMC_OUT_WIDTH = 64,
	parameter SRAM_OUT_WIDTH = 16,
	parameter MEM_ROW = 16
)(

	//~~~~~~~~~~~~~~
	// CLK, Resets
	//~~~~~~~~~~~~~~
	input clk,
	input reset_n,

	//~~~~~~~~~~~~~~
	// Control Signals
	//~~~~~~~~~~~~~~
	input wbs_we_i,
	//input trig,				// commented-28/11/22-Deepak		// RICHA : NEW!


	//~~~~~~~~~~~~~~~~~~~~~
	// Wishbone Data, Address Busses
	//~~~~~~~~~~~~~~~~~~~~~
	input  [WIDTH_WB_DATA-1 : 0] wishbone_buffer_data_in,
	input  [WIDTH_ADD  -  1 : 0] wishbone_rw_addr,
	output [WIDTH_WB_DATA-1 : 0] wishbone_databus_out,

	//~~~~~~~~~~~~~~~~~~~~~~~~~
	// Memory Side Data Busses		
	//~~~~~~~~~~~~~~~~~~~~~~~~~
	input [IMC_OUT_WIDTH -1 : 0] IMC_out,
	input [SRAM_OUT_WIDTH-1 : 0] SA_out,
	output [MEM_ROW  -    1 : 0] SRAM_Din,     		// RICHA : New!!

	//~~~~~~~~~~~~~~~~~~~~~~~~~
	// MEMORY CONTROLS S/Gs : All From Controller		
	//~~~~~~~~~~~~~~~~~~~~~~~~~
	output  PRE_SRAM,
	output  [MEM_ROW - 1 : 0] WWL,
	output  WE,
	output  PRE_VLSA, 
	output  PRE_CLSA, 
	output  PRE_A,
	output  [MEM_ROW - 1 : 0] RWL, 
	output  [MEM_ROW - 1 : 0] RWLB,
	output  SAEN, 
	output  en,				// RICHA : enable for EN and VCLP
	output  reg [7:0]WWLD,
	output  full_IB, full_WB, full_SA, full_OB,
	output  empty_IB, empty_WB, empty_SA, empty_OB
);

	wire IB_wr_en, WB_wr_en, IM_wr_en, OB_rd_en, SA_rd_en;

	// All Below From Controller
	// Buffer rd/wr controls
	wire IM_controller_rd_en, WB_controller_rd_en, IB_controller_rd_en, OB_controller_wr_en, SA_controller_wr_en;
	// Buffer Data to Controller
	wire [31:0] IM_controller_data;
	wire [15:0] IB_controller_data;
	// Buffer Address From Controller
	wire [5:0] IM_controller_addr;
	wire [3:0] BUF_controller_addr;

	// SA_OB_outut Mux:
	wire [15:0]w_SA_data_out;
	wire [63:0]w_OB_data_out;

	// Controller FSM Input Output Signals
	wire IM_empty;
	wire IM_full;
	wire operating;					// RICHA : Status of Controller : Can Be Ported Out.
	wire reading_IM;				// RICHA : Status of Controller : Can be ported out.

	//=============================
	// wishbone wr, rd to buffers
	//=============================
	wb_rd_wr_buf rd_wr_en_decoder(
	.wb_rd_wr(wbs_we_i),
	.wb_buf_address(wishbone_rw_addr[31:24]),
	.IB_wr_en(IB_wr_en),
	.WB_wr_en(WB_wr_en),
	.IM_wr_en(IM_wr_en),
	.OB_rd_en(OB_rd_en),
	.SA_rd_en(SA_rd_en) );



	//=============================
	// Instruction Memory
	//=============================
	sync_fifo#(
		.DATA_WIDTH('d32),
		.DATA_DEPTH('d64),
		.ADDR_WIDTH('d6)
	) DUT_sync_fifo_instruction_memory (
	.clk		   (clk),
	.rst_n		   (reset_n),

	// From Wishbone
	.wr_en		   (IM_wr_en),
	.data_in	   (wishbone_buffer_data_in),
	.wr_addr	   (wishbone_rw_addr[5:0]),

	// From Controller
	.rd_en		   (IM_controller_rd_en),
	.rd_addr	   (IM_controller_addr),
	.data_out	   (IM_controller_data),

	// Flags
	.full		   (IM_full),
	.empty		   (IM_empty)				);




	//=============================
	// Input Buffer
	//=============================
	sync_fifo#(
		.DATA_WIDTH('d16),
		.DATA_DEPTH('d16)) DUT_sync_fifo_input_buffer (
	.clk		   (clk),
	.rst_n		   (reset_n),

	// From Wishbone
	.wr_en		   (IB_wr_en),
	.data_in	   (wishbone_buffer_data_in[15:0]),
	.wr_addr	   (wishbone_rw_addr[3:0]),

	// From Controller
	.rd_en		   (IB_controller_rd_en),
	.rd_addr	   (BUF_controller_addr),
	.data_out	   (IB_controller_data),

	// Flags
	.full		   (full_IB),
	.empty		   (empty_IB)				);





	//=============================
	// Weight Buffer
	//=============================
	sync_fifo#(
		.DATA_WIDTH('d16),
		.DATA_DEPTH('d16)) DUT_sync_fifo_weight_buffer (
	.clk		   (clk),
	.rst_n		   (reset_n),

	// From Wishbone
	.wr_en		   (WB_wr_en),
	.data_in	   (wishbone_buffer_data_in[15:0]),
	.wr_addr	   (wishbone_rw_addr[3:0]),

	// From Controller
	.rd_en		   (WB_controller_rd_en),
	.rd_addr	   (BUF_controller_addr),
	.data_out	   (SRAM_Din),			// Connected Directly with SRAM

	// Flags
	.full		   (full_WB),
	.empty		   (empty_WB)				);



	//=============================
	// SA_Out Buffer
	//=============================
	sync_fifo#(
		.DATA_WIDTH('d16),
		.DATA_DEPTH('d16),
		.ADDR_WIDTH('d4)
	
	) DUT_sync_fifo_SA_OUT (
	.clk		   (clk),
	.rst_n		   (reset_n),

	// From Wishbone
	.rd_en		   (SA_rd_en),
	.data_out	   (w_SA_data_out),
	.rd_addr	   (wishbone_rw_addr[3:0]),

	// From Controller
	.wr_en		   (SA_controller_wr_en),
	.wr_addr	   (BUF_controller_addr),
	.data_in	   (SA_out),

	// Flags
	.full		   (full_SA),
	.empty		   (empty_SA)				);


	//=============================
	// Output Buffer
	//=============================
	sync_fifo#(
		.DATA_WIDTH('d64),
		.DATA_DEPTH('d16),
		.ADDR_WIDTH('d4)
	
	) DUT_sync_fifo_output_buffer (
	.clk		   (clk),
	.rst_n		   (reset_n),

	// From Wishbone
	.rd_en		   (OB_rd_en),
	.data_out	   (w_OB_data_out),
	.rd_addr	   (wishbone_rw_addr[3:0]),

	// From Controller
	.wr_en		   (OB_controller_wr_en),
	.wr_addr	   (BUF_controller_addr),
	.data_in	   (IMC_out),

	// Flags
	.full		   (full_OB),
	.empty		   (empty_OB)				);



	

	//=============================
	// Wishbone Data Out Mux
	//=============================
	
	SA_OB_mux #(.WIDTH_SA('d16),
		    .WIDTH_OB ('d64),
		    .WIDTH_WB_OUT('d32)
	    )SA_OB_mux_inst(
	    .sel(wishbone_rw_addr[21:19]),
	    .sa_data(w_SA_data_out),
	    .ob_data(w_OB_data_out),
	    .wb_data_out(wishbone_databus_out) 
	    );

	    
	    
	//=============================
	// CONTROLLER
	//=============================
	
	controller_4 controller(
	//.trig(trig),				//commented-28/11/22-Deepak
	.clk(clk),
	.resetn(reset_n),

	.IM_data_in(IM_controller_data),
	.IB_data_in(IB_controller_data),
	.IM_addr(IM_controller_addr),
	.BUF_addr(BUF_controller_addr),
	.IM_rd_en(IM_controller_rd_en),
	.IB_rd_en(IB_controller_rd_en),
	.WB_rd_en(WB_controller_rd_en),
	.SA_wr_en(SA_controller_wr_en),
	.OB_wr_en(OB_controller_wr_en),

	.PRE_SRAM(PRE_SRAM),
	.WWL(WWL),
	.WE(WE),
	.PRE_VLSA(PRE_VLSA), 
	.PRE_CLSA(PRE_CLSA), 
	.PRE_A(PRE_A),
	.RWL(RWL), 
	.WWLD(WWLD),		
	.RWLB(RWLB),
	.SAEN(SAEN),
	.en(en),
        .IM_empty(IM_empty),
	.IM_full(IM_full),
	.reading_IM(reading_IM),
	.operating(operating)	
		
	
);



endmodule





// NOTE : WB_ADD[19] Should never be 1 except when reading OB_lsb
// 	  WB_ADD[20] Should never be 1 except when reading OB_msb
// 	  WB_ADD[21] Should never be 1 except when reading SA_weight.

// 	  WB_ADD[21:19] Should Never be 100 (SA_weight_out), 010 (OB_msb),
// 	  001(OB_lsb). In all other cases, WB_data_out is kept at 0. 
//
//
// 	  Possible Trigger For Controller : All Outputs of rd_wr_decoder = 0.
// 	  (wr enabled and output buffer or SA at address.)
// 	  Decoder, Address Incrementer Moved Inside Controller.
//
//
// 	  WB_data_out Connected to Din of SRAM. WWL[addr] activated wherever
// 	  data to be written.
// 	  Controller reads IM --> Writes one weight --> Reads IM --> writes
// 	  second weight. 
// 	  Can be changed to continuous writing : 
// 	  	Read IM -->
// 	  	Write all 16 weights one by one --> 
// 	  	Read IM --> 
// 	  	Apply all 16 Inputs in MAC one by one -->
// 	  	Write to Output Buffer.  
//
// 	  Input for MAC goes through Controller to not write by mistake
// 	  at the wrong time, IB not directly connected with SRAM RWL.
// 	  Not sure if directly connecting gives controller enough power
// 	  through any enable signal to apply at the correct time. 
//
// 	  MAC Op Sequence : Read IB Once --> Apply [15:0]RWL as per 16
// 	  digits of IB --> Assert/ Deassert pre_a, pre_clsa, sa_en -->
// 	  Write into OB Once --> Read IM : If MAC : COntinue Cycle. Else
// 	  : break. COntinuous Operation for 16 cycles without reading
// 	  MAC also possible. 
//
// 	  ADC Connected to OB_Data_in directly. 
	








	
