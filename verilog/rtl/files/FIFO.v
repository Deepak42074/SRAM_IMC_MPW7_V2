//Realization of synchronous FIFO by counter method	
// Instruction Buffer
module	sync_fifo		
#(	parameter   DATA_WIDTH = 'd32  ,		//FIFO bit width
        parameter   DATA_DEPTH = 'd64  ,		//FIFO depth
	parameter   ADDR_WIDTH = 'd4
)

(	input	clk,		       		//System clock
	input	rst_n,       	       		//Low level active reset signal
	input	wr_en,      		     		//Write enable signal, high level active
	input	rd_en,       		     		//Read enable signal, high level active		   
	input	[DATA_WIDTH-1:0]data_in,           	//Data written 	
	input  [ADDR_WIDTH-1 : 0]	wr_addr,			//Write address
	input  [ADDR_WIDTH-1 : 0]	rd_addr,			//Read address
	output	full,      	             		//Full flag, high level indicates that the current FIFO has been read empty
	output	empty	,   	 		   	//Empty flag, high level indicates that the current FIFO is full
	output	reg	[DATA_WIDTH-1:0]data_out,	//Output data
	output  	[DATA_WIDTH -1 : 0] fifo_buf_out 

			
); 



//reg define
reg [DATA_WIDTH - 1 : 0] fifo_buffer[DATA_DEPTH - 1 : 0];	                //Implementation of RAM with two-dimensional array
reg [5:0]fifo_cnt;								//$clog2 is the base 2 logarithm
reg sample;
//assign case_working = sample;
		
//Read operation, update read address
always @ (posedge clk ) begin
	 if (!empty && rd_en)begin							//The read enable is valid and not empty
		data_out <= fifo_buffer[rd_addr];
	end
end
//Write operation, update write address
always @ (posedge clk ) begin
	 if (!full && wr_en)begin							//Write enable is valid and not full
		fifo_buffer[wr_addr]<=data_in;
		
	end;
end
//Update counter
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n)
	begin
		fifo_cnt <= 0;
		sample <= 1'b0;
	end
	else begin
		case({wr_en,rd_en})							//Splicing read-write enable signal for judgment
			2'b00:fifo_cnt <= fifo_cnt;					//No reading, no writing
			2'b01:	                               			//Just read
				if(fifo_cnt != 0)				   	//fifo is not read empty
					fifo_cnt <= fifo_cnt - 1'b1;   		//Number of fifo - 1
			2'b10:begin                                 			//Just write
				if(fifo_cnt != DATA_DEPTH)				//fifo is not full
				begin
					fifo_cnt <= fifo_cnt + 1'b1;   		//Number of fifo + 1
				end
				sample <= 1'b1;
			end		
			2'b11:fifo_cnt <= fifo_cnt;	           			//Simultaneous reading and writing
			default:;                              	
		endcase
	end
end
//Update the indication signal according to the counter status
//According to different thresholds, you can also design half empty, half full, almost empty and almost full

assign full  = (fifo_cnt == DATA_DEPTH) ? 1'b1 : 1'b0;		//Null signal
assign empty = (fifo_cnt == 0)? 1'b1 : 1'b0;				//Full signal
assign fifo_buf_out = fifo_buffer[0]; 
endmodule
