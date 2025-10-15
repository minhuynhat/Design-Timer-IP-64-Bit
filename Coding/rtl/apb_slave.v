module	apb_slave (
		input 	wire					sys_clk,
		input 	wire					sys_rst_n,
		input 	wire					psel,
		input		wire					pwrite,
		input		wire					penable,
		input		wire	[31:0]	rdata,

		output	wire					wr_en,
		output	wire					rd_en,			
		output	wire	[31:0]	prdata,
		output	wire					pready
);

//------------------------------------

		reg wr_en_pre, rd_en_pre;
 
		always @(posedge sys_clk or negedge sys_rst_n) begin
				if (!sys_rst_n) begin
						wr_en_pre	<= 0;
				end else begin
						wr_en_pre	<= psel & pwrite & penable & (~wr_en);
				end
		end

		assign	wr_en 	= wr_en_pre;

//--------------------------------------------------------

		always @(posedge sys_clk or negedge sys_rst_n) begin
				if (!sys_rst_n) begin
						rd_en_pre	<= 0;
				end else begin
						rd_en_pre	<= psel & (~pwrite) & penable & (~rd_en);
				end
		end

		assign	rd_en 	=	rd_en_pre;

//--------------------------------------------------------

		assign	prdata	=	rdata;

		assign	pready	=	wr_en_pre | rd_en_pre;


endmodule		
