module	counter_ctrl (
		input 	wire					sys_clk,
		input 	wire					sys_rst_n,
		input 	wire					div_en,
		input		wire	[3:0]		div_val,
		input		wire					timer_en,
		input		wire					halt_req,
		input		wire					dbg_mode,
		
		output	wire					cnt_en,
		output	reg						halt_ack
);

		wire		[7:0]	limit;
		reg			[7:0] int_cnt;
		wire					cnt_rst, cond_cnt;

		assign	limit		=	(1 << div_val) - 1;
		assign	cnt_rst	=	~timer_en	|	~div_en	|	(limit == int_cnt);
		assign 	cond_cnt = timer_en & div_en & (div_val != 0);
		assign	cond_halt	=	halt_req & dbg_mode;

		always @(posedge sys_clk or negedge sys_rst_n) begin
				if (!sys_rst_n) begin
						int_cnt	<=	8'h0;
				end	else begin
						if (cond_halt) begin
								int_cnt	<=	int_cnt;
						end else begin 
								if (cnt_rst) begin
										int_cnt	<=	0;
								end else begin
										if (cond_cnt) begin
												int_cnt <=	int_cnt + 1;
										end 
								end
						end
				end
		end	

		assign	cnt_en	=	(~cond_halt)
											&	((~div_en & timer_en)
											|	((div_val != 0) & div_en & timer_en & (int_cnt == limit))
											|	((div_val == 0) & div_en & timer_en));	
	
		always @(posedge sys_clk or negedge sys_rst_n) begin
				if (!sys_rst_n) begin
						halt_ack <= 0;
				end else begin
						halt_ack <= cond_halt;
				end
		end
endmodule
