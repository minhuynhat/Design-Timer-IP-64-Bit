module	timer_top (
		input		wire					sys_clk,
		input		wire					sys_rst_n,
		input		wire					dbg_mode,
		input		wire	[3:0]		tim_pstrb,
		input		wire					tim_psel,
		input		wire					tim_pwrite,
		input		wire					tim_penable,
		input		wire	[31:0]	tim_pwdata,
		input		wire	[11:0]	tim_paddr,
		
		output	wire	[31:0]	tim_prdata,
		output	wire					tim_pready,
		output	wire					tim_pslverr,
		output	wire					tim_int					
);

		wire	[31:0]	rdata;
		wire	[3:0]		div_val;
		wire	wr_en, rd_en,	div_en, timer_en, halt_req, halt_ack, int_en, int_st, cnt_en;

		apb_slave		u0	(
				.sys_clk				(sys_clk),
				.sys_rst_n			(sys_rst_n),
				.psel						(tim_psel),
				.pwrite					(tim_pwrite),
				.penable				(tim_penable),
				.rdata					(rdata),

				.wr_en					(wr_en),
				.rd_en					(rd_en),
				.prdata					(tim_prdata),
				.pready					(tim_pready)
		);

		
		reg_file	u1	(
				.sys_clk				(sys_clk),
				.sys_rst_n			(sys_rst_n),
				.wr_en					(wr_en),
				.rd_en					(rd_en),
				.wdata					(tim_pwdata),
				.addr						(tim_paddr),
				.pstrb					(tim_pstrb),
				.cnt_en					(cnt_en),
				.halt_ack				(halt_ack),	

				.rdata					(rdata),
				.pslverr				(tim_pslverr),
				.int_en					(int_en),
				.int_st					(int_st),
				.div_en					(div_en),
				.div_val				(div_val),
				.timer_en				(timer_en),
				.tim_int				(tim_int),
				.halt_req				(halt_req)
		);


		counter_ctrl	u2	(
				.sys_clk				(sys_clk),
				.sys_rst_n			(sys_rst_n),
				.div_en					(div_en),
				.div_val				(div_val),
				.timer_en				(timer_en),
				.halt_req				(halt_req),
				.dbg_mode				(dbg_mode),
				
				.halt_ack				(halt_ack),	
				.cnt_en					(cnt_en)
		);

		interrupt		u4	(
				.sys_clk				(sys_clk),
				.sys_rst_n			(sys_rst_n),
				.int_en					(int_en),
				.int_st					(int_st),

				.tim_int				(tim_int)
		);
endmodule
