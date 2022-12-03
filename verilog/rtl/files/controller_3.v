module controller_2 #(
	parameter WIDTH_IM = 32,
	parameter WIDTH_IB = 16,
	parameter WIDTH_OB = 16,
	parameter WIDTH_WB = 16,
	parameter WIDTH_IM_ADDR = 6,
	parameter WIDTH_BUF_ADDR = 4,
	parameter WWLD_WIDTH = 8,
	parameter MEM_ROW = 16,
	parameter ROW_ADDR_WIDTH = 4,			// Decoder (IM[3:0] --> WWL[15:0]) is hardcoded
	parameter TMUL_WIDTH = 8

)(
//	input trig,					//commented-28/11/22-Deepak
	input clk,
	input resetn,

	// Buffer Inputs
	input [WIDTH_IM-1:0] IM_data_in,
	input [WIDTH_IB-1:0] IB_data_in,

	// Buffer Addresses
	output reg [WIDTH_IM_ADDR-1 : 0] IM_addr,
	output reg [WIDTH_BUF_ADDR-1: 0] BUF_addr,

	// Buffer Controls
	output reg IM_rd_en, WB_rd_en, IB_rd_en, OB_wr_en, SA_wr_en,

	// Memory Controls
	output reg PRE_SRAM,
	output reg [MEM_ROW - 1 : 0] WWL,
	output reg WE,
	output reg PRE_VLSA, 
	output reg PRE_CLSA, 
	output reg PRE_A,
	output     [MEM_ROW - 1 : 0] RWL, 
	output     [MEM_ROW - 1 : 0] RWLB,
	output reg SAEN, 
	output reg en,					// RICHA : Added to time EN and VCLP During MAC.
	//output reg [WWLD_WIDTH-1:0]WWLD,		// RICHA : Throwing Error : To be Rectified 				
	input  IM_empty,
	input IM_full,
	output reg operating,
	output reg reading_IM
);
	
	reg [1:0] EXT_STATE;
	reg [1:0] INT_STATE;
	reg [WIDTH_IM_ADDR-1:0] cnt_IM;
	reg [WIDTH_BUF_ADDR-1:0] cnt_BUF;
	reg [WIDTH_BUF_ADDR-1:0] cnt_BUF_MAC;
	reg IM_reading_done, IM_executed;     // When IM Operation Done
	wire [2:0]opcode;
	assign opcode = IM_data_in[31:29];
	wire [ROW_ADDR_WIDTH-1:0] sram_row_addr;
	wire [MEM_ROW-1:0] w_wwl;
	assign sram_row_addr = IM_data_in[ROW_ADDR_WIDTH-1:0];
	reg I_1;   // Added to incorporate more states wherever required for waveforms

	reg [TMUL_WIDTH-1:0]cnt_tmul;
	reg [TMUL_WIDTH-1:0]t_mul;
	reg [31:0] dbg;
	reg [31:0] dbg_pos;
	reg [31:0] dbg_neg;
		


	// EXTERNAL STATES
	localparam IDLE      = 2'b00;
	localparam READ_IM   = 2'b01;
	localparam OPERATE   = 2'b10;

	// INTERNAL STATES
	// Write into SRAM
	localparam RD_BUF    = 3'b000;
        localparam WR_SRAM_0 = 3'b001;
	localparam WR_SRAM_1 = 3'b010;
	localparam WR_SRAM_2 = 3'b011;
	localparam WR_SRAM_3 = 3'b100;
	localparam WR_SRAM_4 = 3'b101;

	// Read SRAM
	localparam RD_SRAM_0 = 3'b000;
	localparam RD_SRAM_1 = 3'b001;
	localparam RD_SRAM_2 = 3'b010;
	localparam RD_SRAM_3 = 3'b011;
	localparam RD_SRAM_4 = 3'b100;
	localparam RD_SRAM_5 = 3'b101;

	// MAC
	localparam MAC_0     = 3'b000;
	localparam MAC_1     = 3'b001;
	localparam MAC_2     = 3'b010;
	localparam MAC_3     = 3'b011;

	

	//==========================================
	// Decoder for IM[row_addr] --> WWL
	//==========================================
	
	assign w_wwl[0]  = (~(sram_row_addr[3])) & (~(sram_row_addr[2])) & (~(sram_row_addr[1])) & (~(sram_row_addr[0]));
	assign w_wwl[1]  = (~(sram_row_addr[3])) & (~(sram_row_addr[2])) & (~(sram_row_addr[1])) & ( (sram_row_addr[0]));
	assign w_wwl[2]  = (~(sram_row_addr[3])) & (~(sram_row_addr[2])) & ( (sram_row_addr[1])) & (~(sram_row_addr[0]));
	assign w_wwl[3]  = (~(sram_row_addr[3])) & (~(sram_row_addr[2])) & ( (sram_row_addr[1])) & ( (sram_row_addr[0]));
	assign w_wwl[4]  = (~(sram_row_addr[3])) & ( (sram_row_addr[2])) & (~(sram_row_addr[1])) & (~(sram_row_addr[0]));
	assign w_wwl[5]  = (~(sram_row_addr[3])) & ( (sram_row_addr[2])) & (~(sram_row_addr[1])) & ( (sram_row_addr[0]));
	assign w_wwl[6]  = (~(sram_row_addr[3])) & ( (sram_row_addr[2])) & ( (sram_row_addr[1])) & (~(sram_row_addr[0]));
	assign w_wwl[7]  = (~(sram_row_addr[3])) & ( (sram_row_addr[2])) & (~(sram_row_addr[1])) & ( (sram_row_addr[0]));
	assign w_wwl[8]  = ( (sram_row_addr[3])) & (~(sram_row_addr[2])) & (~(sram_row_addr[1])) & (~(sram_row_addr[0]));
	assign w_wwl[9]  = ( (sram_row_addr[3])) & (~(sram_row_addr[2])) & ( (sram_row_addr[1])) & ( (sram_row_addr[0]));
	assign w_wwl[10] = ( (sram_row_addr[3])) & (~(sram_row_addr[2])) & ( (sram_row_addr[1])) & (~(sram_row_addr[0]));
	assign w_wwl[11] = ( (sram_row_addr[3])) & (~(sram_row_addr[2])) & (~(sram_row_addr[1])) & ( (sram_row_addr[0]));
	assign w_wwl[12] = ( (sram_row_addr[3])) & ( (sram_row_addr[2])) & (~(sram_row_addr[1])) & (~(sram_row_addr[0]));
	assign w_wwl[13] = ( (sram_row_addr[3])) & ( (sram_row_addr[2])) & ( (sram_row_addr[1])) & ( (sram_row_addr[0]));
	assign w_wwl[14] = ( (sram_row_addr[3])) & ( (sram_row_addr[2])) & ( (sram_row_addr[1])) & (~(sram_row_addr[0]));
	assign w_wwl[15] = ( (sram_row_addr[3])) & ( (sram_row_addr[2])) & ( (sram_row_addr[1])) & ( (sram_row_addr[0]));


	//==========================================
	// Assign For RWL and RWLB, else clock 
	// latency arrives when reg.
	// =========================================
	
	assign RWL = IB_data_in & {MEM_ROW{en}};
	assign RWLB = ~IB_data_in & {MEM_ROW{en}};
//	assign BUF_addr = {WIDTH_IM_ADDR{1'b0}};			// RICHA : COMMENTING IM_ADDR TO SEE WHERE THE SYNTHESIS IS FAILING.
//	assign IM_addr = {WIDTH_IM_ADDR{1'b0}};			// RICHA : COMMENTING IM_ADDR TO SEE WHERE THE SYNTHESIS IS FAILING.

	//==========================================
	// EXTERNAL FSM
	//__________________________________________
	// STATES : IDLE --> READ_IM --> OPERATE
	// 			     <--
	// 		<---------------
	//__________________________________________

	always @(posedge clk or negedge resetn)
	begin
		if(!resetn)
		begin
			dbg = 32'd0;
			EXT_STATE = IDLE;
			operating = 1'b0;
			INT_STATE = 2'b00;
			reading_IM = 1'b0;
		end
		else
		begin
			if(IM_empty==0 && EXT_STATE == IDLE)					// IDLE --> READ_IM
			begin
				EXT_STATE <= READ_IM;
				reading_IM <= 1'b1;
				dbg = 32'd1;
			end
			if(EXT_STATE == READ_IM && IM_reading_done == 1)			// IM_READ --> OPERATE
			begin
				EXT_STATE = OPERATE;
				operating = 1'b1;
				INT_STATE = 2'b00;
				reading_IM = 0;
				dbg = 32'd2;
			end
			if(EXT_STATE == OPERATE && IM_executed == 1 && IM_empty == 0)		// OPERATE --> READ_IM
			begin
				EXT_STATE = READ_IM;
				operating = 1'b0;
				INT_STATE = 2'b00;
				reading_IM = 1'b1;
				dbg = 32'd3;
			end
			if(EXT_STATE == OPERATE && IM_empty == 1 && IM_executed == 1)		// OPERATE --> IDLE
			begin
				EXT_STATE = IDLE;
				INT_STATE = 2'b00;
				operating = 1'b0;
				reading_IM = 1'b0;
				dbg = 32'd4;
			end
		end
	end

	//==========================================
	// INTERNAL FSM
	//__________________________________________
	// STATES : 0 --> 1 --> 2 --> 3
	// 	      <--------------
	//__________________________________________

	
	always @(posedge clk or negedge resetn)
	begin
		if(!resetn)
		begin
			OB_wr_en = 0;

			
			PRE_SRAM = 1'b1;					// RICHA : PRE_SRAM set to 1'b1 instead of 1'bz at reset.
			WWL = {MEM_ROW{1'b0}};
			WE = 1'b0;
			PRE_VLSA = 1'b1;
			PRE_CLSA = 1'b1;
			PRE_A = 1'b1;
			SAEN = 1'b0;
			//WWLD = {WWLD_WIDTH{1'b0}};
			dbg_pos = 32'd0;
			IM_reading_done = 1'b0;
			I_1 = 0;

			en = 1'b0;
		end
		else 
		begin
			case(EXT_STATE)
				IDLE:
				begin
					PRE_SRAM = 1'b1;					// RICHA : PRE_SRAM set to 1'b1 instead of 1'bz at reset.
					WWL = {MEM_ROW{1'b0}};					// RICHA : States to reset at IDLE as well. 
					WE = 1'b0;
					PRE_VLSA = 1'b1;
					PRE_CLSA = 1'b1;
					PRE_A = 1'b1;
					SAEN = 1'b0;
					//WWLD = {WWLD_WIDTH{1'b0}};
					dbg_pos = 32'd0;
					IM_reading_done = 1'b0;
					I_1 = 0;

					en = 1'b0;
				end
				
				//~~~~~~~~~~~~~~~~~~~~~~~~~~
				// READ IM
				//~~~~~~~~~~~~~~~~~~~~~~~~~~
				
				READ_IM:
				begin

				case(INT_STATE)
					2'b00:
					begin
							INT_STATE = 2'b01;
							dbg_pos <= 32'd1;
					end
					2'b01:
					begin

							INT_STATE = 2'b00;
							dbg_pos <= 32'd2;
					end
				endcase
				end
				
				
				//~~~~~~~~~~~~~~~~~~~~~~~~~~
				// EXECUTE
				//~~~~~~~~~~~~~~~~~~~~~~~~~~
		
				OPERATE:
				begin
					case(opcode)
						
						
						//~~~~~~~~~~~~~~~~~~~~~~~~~~
						// Write WEIGHT
						//~~~~~~~~~~~~~~~~~~~~~~~~~~
						3'b000:
						begin		
							case({I_1,INT_STATE})
								RD_BUF:
								begin
									PRE_SRAM = 1'b0;
									{I_1,INT_STATE} = WR_SRAM_0;
									dbg_pos = 32'd3;
								end
								
								WR_SRAM_0:
								begin
									PRE_SRAM = 1'b1;
									WE = 1'b1;
									{I_1, INT_STATE} = WR_SRAM_1;
									dbg_pos = 32'd4;
								end
								WR_SRAM_1:
								begin
									WWL = w_wwl;
									{I_1,INT_STATE} = WR_SRAM_2;
									dbg_pos = 32'd5;
								end
								WR_SRAM_2:
								begin
									WE = 1'b0;
									{I_1,INT_STATE} = WR_SRAM_3;
									dbg_pos = 32'd6;
								end
								WR_SRAM_3:
								begin
									WWL = 0;
									dbg_pos = 32'd7;
									{I_1, INT_STATE} = WR_SRAM_4;
								end
								WR_SRAM_4:
								begin
									{I_1,INT_STATE} = 3'b000;
									dbg_pos = 32'd21;

								end
							endcase
						end
		
						//~~~~~~~~~~~~~~~~~~~~~~~
						// Read Weight SRAM Array
						//~~~~~~~~~~~~~~~~~~~~~~~
						3'b001:
						begin
							case({I_1, INT_STATE})
								RD_SRAM_0:
								begin
												
									PRE_SRAM = 1'b0;
									{I_1, INT_STATE} = 3'b001;
									dbg_pos = 32'd9;
								end
								RD_SRAM_1:
								begin
									PRE_SRAM = 1'b1;
									WWL = w_wwl;
									{I_1, INT_STATE} = 3'b010;
									dbg_pos = 32'd10;
								end
								RD_SRAM_2:
								begin
									PRE_VLSA = 1'b0;
									{I_1, INT_STATE} = 3'b011;

									dbg_pos = 32'd11;
								end
								RD_SRAM_3:
								begin
									WWL  = 0;
									{I_1, INT_STATE} = RD_SRAM_4;
									dbg_pos = 32'd12;
								end
								RD_SRAM_4:
								begin
									PRE_VLSA  = 1'b1;
									{I_1, INT_STATE} = RD_SRAM_5;
									dbg_pos = 32'd13;
								end
								RD_SRAM_5:
									{I_1, INT_STATE} = 3'b000;

							endcase
						end


						//~~~~~~~~~~~~~~~~~~~~~~~
						// MAC
						//~~~~~~~~~~~~~~~~~~~~~~~
						3'b010:
						begin
							case({I_1, INT_STATE})
								MAC_0:
								begin
												
									PRE_A = 1'b0;
									en = 1'b1;
									{I_1, INT_STATE} = 3'b001;
									PRE_CLSA = 1'b0;
									dbg_pos = 32'd14;
								end
								MAC_1:
								begin
									PRE_CLSA = 1'b1;
									dbg_pos = 32'd15;
									if(t_mul == 1)
									begin
										dbg_pos = 32'd16;
										SAEN = 1'b1;

									end
									if(t_mul == 0)
									begin
										dbg_pos = 32'd17;
										{I_1, INT_STATE} = MAC_2;
										PRE_A = 1'b1;
										en = 1'b0;

									end
								end
									
								MAC_2:
								begin
									if(clk)
									begin
										dbg_pos = 32'd18;
										SAEN = 1'b0;
										{I_1, INT_STATE} = 3'b000;
									end

								end
							endcase
						end
						3'b011:
						begin
							case (INT_STATE)
								2'b00:
								begin	
									dbg_pos = 32'd19;
									INT_STATE = 2'b01;

								end
								2'b01:
								begin
									dbg_pos = 32'd20;
									INT_STATE = 2'b00;
								end
							endcase
						end

					endcase
				end
			endcase
		end
	end
	


	always @(negedge clk or negedge resetn)
	begin
		if(!resetn)
										// RICHA
									// : EXT_STATE
									// Condition
									// removed.
		begin
			IM_rd_en = 0;
			IB_rd_en = 0;
			WB_rd_en = 0;
			SA_wr_en = 0;
			OB_wr_en = 0;

			IM_addr = {WIDTH_IM_ADDR{1'b0}};			// Making high z to 0. Shouldnt affect anything
			BUF_addr = {WIDTH_BUF_ADDR{1'b0}};
			//WWLD = {WWLD_WIDTH{1'b0}};

			cnt_BUF = 0;
			I_1 = 0;
			cnt_IM = 0;
			cnt_BUF_MAC = 0;

			IM_executed = 1'b0; 			
			cnt_tmul = 8'd3;					// RICHA : Hardcoded t_mul width.
			t_mul = 8'd3;						// RICHA : Hardcoded t_mul width.
			dbg_neg = 32'd0;
		end
		//~~~~~~~~~~~~~~~~~~~~~~~~~~
		// READ IM
		//~~~~~~~~~~~~~~~~~~~~~~~~~~
		else 
		begin
			case(EXT_STATE)
				IDLE:
				begin
					IM_rd_en = 0;
					IB_rd_en = 0;
					WB_rd_en = 0;
					SA_wr_en = 0;
					OB_wr_en = 0;

					IM_addr = {WIDTH_IM_ADDR{1'b0}};			// Making high z to 0. Shouldnt affect anything
					BUF_addr = {WIDTH_BUF_ADDR{1'b0}};
					//WWLD = {WWLD_WIDTH{1'b0}};

					cnt_BUF = 0;
					I_1 = 0;
					cnt_IM = 0;
					cnt_BUF_MAC = 0;

					IM_executed = 1'b0; 			
					cnt_tmul = 8'd3;					// RICHA : Hardcoded t_mul width.
					t_mul = 8'd3;						// RICHA : Hardcoded t_mul width.
					dbg_neg = 32'd0;	
				end

				READ_IM:
				begin

				case(INT_STATE)
					2'b00:
					begin
						IM_rd_en = 1'b1;
						IM_addr = cnt_IM;
						IM_executed = 1'b0; 			// carries from last cycle of operating
						cnt_IM ++;
						dbg_neg = 32'd1;
					end
					2'b01:
					begin
						IM_rd_en = 1'b0;
						cnt_BUF = IM_data_in[7:4];		// RICHA : Weight Depth kept at 16. Need to change this when changing depth. 
						IM_reading_done = 1'b1;
						cnt_BUF_MAC = IM_data_in[27:22];
						dbg_neg = 32'd2;


					end
				endcase
				end
				
				
				//~~~~~~~~~~~~~~~~~~~~~~~~~~
				// EXECUTE
				//~~~~~~~~~~~~~~~~~~~~~~~~~~
		
				OPERATE:
				begin
					case(opcode)
						
						
						//~~~~~~~~~~~~~~~~~~~~~~~~~~
						// Write WEIGHT
						//~~~~~~~~~~~~~~~~~~~~~~~~~~
						3'b000:
						begin		
							case({I_1,INT_STATE})
								RD_BUF:
								begin
									IM_reading_done = 1'b0;
									WB_rd_en = 1'b1;
									BUF_addr = cnt_BUF;
									dbg_neg = 32'd3;
								end
								
								WR_SRAM_0:
								begin
									dbg_neg = 32'd4;
									WB_rd_en = 1'b0;
								end
								WR_SRAM_3:
								begin
									dbg_neg = 32'd5;

								end
								WR_SRAM_4:
								begin
									IM_executed = 1'b1;
									dbg_neg = 32'd23;
								end
									
							endcase
						end
		
						//~~~~~~~~~~~~~~~~~~~~~~~
						// Read Weight SRAM Array
						//~~~~~~~~~~~~~~~~~~~~~~~
						3'b001:
						begin
							case({I_1, INT_STATE})
								RD_SRAM_0:
								begin
												
									IM_reading_done = 1'b0;
									dbg_neg = 32'd6;
								end
								RD_SRAM_3:
								begin
									SA_wr_en  = 1'b1;
									BUF_addr = IM_data_in[7:4];
									dbg_neg = 32'd7;
								end
								RD_SRAM_4:
								begin
									SA_wr_en = 1'b0;
									dbg_neg = 32'd8;
								end
								RD_SRAM_5:
									IM_executed = 1'b1;



							endcase
						end


						//~~~~~~~~~~~~~~~~~~~~~~~
						// MAC
						//~~~~~~~~~~~~~~~~~~~~~~~
						3'b010:
						begin
							case({I_1, INT_STATE})
								MAC_0:
								begin
												
									IM_reading_done = 1'b0;
									IB_rd_en = 1'b1;
									BUF_addr = cnt_BUF_MAC;	
									t_mul = cnt_tmul;
									dbg_neg = 32'd9;
								end
								MAC_1:
								begin
									t_mul--;
									dbg_neg = 32'd10;
									IB_rd_en = 1'b0;
									if(t_mul == 1)
									begin
										dbg_neg = 32'd11;
										OB_wr_en = 1'b1;
									end
									
									
								end
								MAC_2:
								begin
									dbg_neg = 32'd12;
									OB_wr_en  = 1'b0;
									if(cnt_BUF_MAC == IM_data_in[21:16]) 			// RICHA : Hardcoded as per ISA
									begin
										dbg_neg = 32'd13;
										IM_executed = 1'b1;
									end
									cnt_BUF_MAC++; 			// Address of OB the result written into = address of IB. BUF_addr remains same despite increment in cnt_BUF

								end
							endcase
						end
						

						3'b011:
						begin
							case(INT_STATE)
								2'b00:
								begin
									dbg_neg = 32'd14;
									IM_reading_done = 1'b0;
									cnt_tmul = IM_data_in[7:0];				// RICHA : Hardcoded as per ISA
									
								end
								2'b01: 
								begin
									IM_executed = 1'b1;
									dbg_neg = 32'd15;
								end

							endcase
						end


					endcase
				end
			endcase
		end
	end

	endmodule

			
