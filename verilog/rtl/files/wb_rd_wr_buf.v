module wb_rd_wr_buf#(
	parameter WIDTH_ADD = 8

)(
	input wb_rd_wr,
	input [WIDTH_ADD - 1 : 0] wb_buf_address,
	
	output reg IB_wr_en,
	output reg WB_wr_en,
	output reg IM_wr_en,
	output reg OB_rd_en,
	output reg SA_rd_en


);
	always @(*) 							// RICHA : To be converted to Combinational Logic.
	begin
		case(wb_buf_address)
			8'h31:
			begin
				IB_wr_en = wb_rd_wr;
				WB_wr_en = 0;
				IM_wr_en = 0;
				OB_rd_en = 0;
				SA_rd_en = 0;
			end

			8'h32:
			begin
				IB_wr_en = 0;
				WB_wr_en = wb_rd_wr;
				IM_wr_en = 0;
				OB_rd_en = 0;
				SA_rd_en = 0;
			end

			8'h33:
			begin
				IB_wr_en = 0;
				WB_wr_en = 0;
				IM_wr_en = 0;
				OB_rd_en = ~wb_rd_wr;
				SA_rd_en = 0;
			end

			8'h40:
			begin
				IB_wr_en = 0; 
				WB_wr_en = 0;
				IM_wr_en = wb_rd_wr;
				OB_rd_en = 0;
				SA_rd_en = 0;
			end

			8'h41:
			begin
				IB_wr_en = 0; 
				WB_wr_en = 0;
				IM_wr_en = 0;
				OB_rd_en = 0;
				SA_rd_en = ~wb_rd_wr;
			end
			default:
			begin
				IB_wr_en = 0; 
				WB_wr_en = 0;
				IM_wr_en = 0;
				OB_rd_en = 0;
				SA_rd_en = 0;
			end

		endcase
	end				// always ended

endmodule

					








		
