module SA_OB_mux #(
	parameter WIDTH_SA = 16,
	parameter WIDTH_OB = 64,
	parameter WIDTH_WB_OUT = 32

)(
	input [2:0]sel,
	input [WIDTH_SA-1 : 0] sa_data,
	input [WIDTH_OB-1 : 0] ob_data,
	output reg [WIDTH_WB_OUT-1:0] wb_data_out );   // RICHA : The elaborator necessitates this to be a reg, but it shouldnt be as per logic.
	
	always @(*)
	begin
		case(sel)
			3'b100 :
			begin	
				wb_data_out[15:0] = sa_data;
				wb_data_out[31:16] = 16'd0;
			end
			3'b001:
				wb_data_out = ob_data[31:0];
			3'b010:
				wb_data_out = ob_data[63:32];
			default:
				wb_data_out = 32'd0;
		endcase
	end
endmodule


	

