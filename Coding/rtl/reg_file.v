module reg_file	(
		input 	wire					sys_clk,
		input 	wire					sys_rst_n,
		input		wire	[31:0]	wdata,
		input		wire	[11:0]	addr,
		input		wire					wr_en,
		input		wire					rd_en,
		input		wire	[3:0]		pstrb,	
		input 	wire					halt_ack,
		input		wire					cnt_en,

		output	wire	[31:0]	rdata,
		output	reg						div_en,
		output	reg		[3:0]		div_val,
		output	reg						halt_req,
		output	reg						timer_en,
		output	wire					pslverr,
		output	wire					tim_int,	
		output	reg						int_en,
		output	reg						int_st
);

		parameter	ADDR_TCR		=	12'h000;
		parameter	ADDR_TDR0		=	12'h004;
		parameter	ADDR_TDR1 	= 12'h008;
		parameter	ADDR_TCMP0	=	12'h00c;
		parameter	ADDR_TCMP1	=	12'h010;
		parameter	ADDR_TIER		=	12'h014;
		parameter	ADDR_TISR		=	12'h018;
		parameter	ADDR_THCSR	=	12'h01c;
		
		wire		[31:0]	addr_tcr, addr_tdr0, addr_tdr1, addr_tcmp0, addr_tcmp1, addr_tier, addr_tisr, addr_thcsr;
		wire						tcr_wr_sel;
		wire						tmp_tcr_wr_sel;	

		assign	tcr_wr_sel	= wr_en & (addr ==	ADDR_TCR);
		assign	tmp_tcr_wr_sel	=	(wdata[11:8] < 9) & tcr_wr_sel;	

//-------------------TCR Register-----------------------------------

		always @(posedge sys_clk or negedge sys_rst_n) begin
				if (!sys_rst_n) begin	
						timer_en <= 0;
						div_en <= 0;
						div_val <= 4'b0001;
				end else begin
						if (tcr_wr_sel & (!pslverr)) 	begin
								if (pstrb[0]) begin
										timer_en	<=	wdata[0];
										div_en 		<=	wdata[1];
								end	else begin
										timer_en	<=	timer_en;
										div_en		<=	div_en;
								end
						end else begin
										timer_en	<=	timer_en;
										div_en		<=	div_en;
						end	 

						if (tmp_tcr_wr_sel & (!pslverr)) begin
								if (pstrb[1]) begin
										div_val	<= wdata[11:8];
								end else begin
										div_val	<=	div_val;
								end
						end else begin
										div_val	<=	div_val;
						end														
				end
		end

		assign	addr_tcr	=	{20'h0, div_val, 6'h0, div_en, timer_en};				

//--------------------TDR0/1 Register------------------------------------
	
		reg		[31:0]	tdr0, tdr1;
		reg						timer_en_d;
		wire					timer_en_fall, tdr0_wr_sel, tdr1_wr_sel;

		assign	tdr0_wr_sel	=	wr_en	&	(addr	==	ADDR_TDR0);
		assign	tdr1_wr_sel	=	wr_en	&	(addr	==	ADDR_TDR1);		

		always	@(posedge sys_clk or negedge	sys_rst_n) begin
				if (!sys_rst_n) begin
						timer_en_d	<=	0;
				end else begin
						timer_en_d	<=	timer_en;
				end
		end

		assign	timer_en_fall	=	~timer_en	&	timer_en_d;

		always @(posedge sys_clk or negedge sys_rst_n) begin
				if (!sys_rst_n) begin
						tdr0	<= 	32'h0;
						tdr1	<=	32'h0;	
				end else begin
						if (!timer_en_fall) begin
								if (tdr0_wr_sel) begin				
												if (pstrb[0])	tdr0[7:0] <= wdata[7:0]; else tdr0[7:0]	<= tdr0[7:0];
												if (pstrb[1])	tdr0[15:8] <= wdata[15:8]; else tdr0[15:8]	<= tdr0[15:8];	
												if (pstrb[2])	tdr0[23:16] <= wdata[23:16]; else tdr0[23:16]	<= tdr0[23:16];	
												if (pstrb[3])	tdr0[31:24] <= wdata[31:24];	else tdr0[31:24]	<= tdr0[31:24];
								end else begin
										if (cnt_en) begin 
												if (tdr0	==	32'hffffffff) begin
														tdr0	<=	32'h0;
												end else begin
														tdr0	<=	tdr0	+ 1;
												end
										end else begin
												tdr0	<= tdr0;
										end 
								end

								if (tdr1_wr_sel) begin
												if (pstrb[0])	tdr1[7:0] <= wdata[7:0];	else tdr1[7:0]	<= tdr1[7:0];
												if (pstrb[1])	tdr1[15:8] <= wdata[15:8];	else tdr1[15:8]	<= tdr1[15:8];
												if (pstrb[2])	tdr1[23:16] <= wdata[23:16];	else tdr1[23:16]	<= tdr1[23:16];
												if (pstrb[3])	tdr1[31:24] <= wdata[31:24];	else tdr1[31:24]	<= tdr1[31:24];	
								end else begin
										if (cnt_en) begin
												if (tdr0 == 32'hffffffff) begin
														tdr1	<=	tdr1	+	1;
												end else begin
														tdr1	<=	tdr1;
												end
										end else begin
												tdr1	<=	tdr1;
										end
								end
						end else begin
								tdr0	<= 0;
								tdr1	<= 0;
						end 
				end
		end 

		assign 	addr_tdr1 = tdr1;
		assign	addr_tdr0	=	tdr0;
	
//--------------------TCMP0/1 Register------------------------------------

		wire		tcmp0_wr_sel;
		wire		tcmp1_wr_sel;
		reg	[31:0]	tcmp0, tcmp1;

		assign	tcmp0_wr_sel	=	wr_en	&	(addr	==	ADDR_TCMP0);
		assign	tcmp1_wr_sel	=	wr_en	&	(addr	==	ADDR_TCMP1);

		always @(posedge sys_clk or negedge sys_rst_n) begin
				if (!sys_rst_n) begin
						{tcmp1, tcmp0}	<=	64'hffffffffffffffff;
				end else begin
						if (tcmp0_wr_sel) begin
								if (pstrb[0])	tcmp0[7:0] <= wdata[7:0];	else tcmp0[7:0]	<=	tcmp0[7:0];
								if (pstrb[1])	tcmp0[15:8] <= wdata[15:8];	else tcmp0[15:8]	<=	tcmp0[15:8];
								if (pstrb[2])	tcmp0[23:16] <= wdata[23:16]; else tcmp0[23:16]	<=	tcmp0[23:16];
								if (pstrb[3])	tcmp0[31:24] <= wdata[31:24];	else tcmp0[31:24]	<=	tcmp0[31:24];
						end else begin
								tcmp0	<=	tcmp0;
						end

						if (tcmp1_wr_sel) begin
								if (pstrb[0])	tcmp1[7:0] <= wdata[7:0]; else tcmp1[7:0]	<=	tcmp1[7:0];
								if (pstrb[1])	tcmp1[15:8] <= wdata[15:8]; else tcmp1[15:8]	<=	tcmp1[15:8];
								if (pstrb[2])	tcmp1[23:16] <= wdata[23:16]; else tcmp1[23:16]	<=	tcmp1[23:16];
								if (pstrb[3])	tcmp1[31:24] <= wdata[31:24]; else tcmp1[31:24]	<=	tcmp1[31:24];
						end else begin
								tcmp1	<=	tcmp1;
						end
				end
		end

		assign	addr_tcmp0 = tcmp0;
		assign	addr_tcmp1 = tcmp1;
	

//--------------------TIER Register------------------------------------
	
		wire		tier_wr_sel;
		assign	tier_wr_sel	=	wr_en	&	(addr	==	ADDR_TIER);

		always @(posedge sys_clk or negedge sys_rst_n) begin
				if (!sys_rst_n) begin
						int_en		<=	0;
				end	else	begin
						if (tier_wr_sel & pstrb[0]) begin
								int_en	<=	wdata[0];
						end else begin
								int_en	<=	int_en;
						end
				end
		end

		assign	addr_tier = {31'h0, int_en};


//--------------------TISR Register------------------------------------

		wire		int_set, int_clr, int_st_pre; 
		wire		tisr_wr_sel;

		assign	tisr_wr_sel	=	wr_en	&	(addr	==	ADDR_TISR);
		assign	int_set			=	({addr_tdr1, addr_tdr0} == {addr_tcmp1, addr_tcmp0});
		assign	int_clr			=	tisr_wr_sel	&	(wdata[0] == 1'b1) & pstrb[0];	

		assign	int_st_pre	=	int_clr ? 1'b0 : (int_set ? 1'b1 : int_st);

		always @(posedge sys_clk or negedge sys_rst_n) begin
				if (!sys_rst_n) begin	
						int_st		<= 1'b0;
				end	else begin
						int_st	<=	int_st_pre;
				end
		end 

		assign	addr_tisr	=	{31'h0, int_st};


//--------------------THCSR Register------------------------------------

		wire		thcsr_wr_sel;

		assign	thcsr_wr_sel	=	wr_en	&	(addr	==	ADDR_THCSR);

		always @(posedge sys_clk or negedge sys_rst_n) begin
				if (!sys_rst_n) begin
						halt_req	<=	0;
				end	else	begin
						if (thcsr_wr_sel & pstrb[0]) begin
								halt_req	<=	wdata[0];
						end	else begin
								halt_req	<=	halt_req;
						end
				end
		end

		assign addr_thcsr = {30'h0, halt_ack, halt_req};

//-------------------Pslave error------------------------------------

		assign	pslverr	=	tcr_wr_sel
										&	((timer_en & pstrb[0] & (wdata[1] != div_en))
										|	(timer_en & pstrb[1] & (div_val != wdata[11:8]))
										| ( pstrb[1] & (wdata[11:8] > 8))); 	

//-------------------Read Transfer-----------------------------------

		reg	[31:0]	tmp_rdata;	

		always	@(*)	begin
				if (rd_en) begin
						case (addr)
								ADDR_TCR		:	tmp_rdata	=	addr_tcr;
								ADDR_TDR0		:	tmp_rdata	=	addr_tdr0;
								ADDR_TDR1		:	tmp_rdata	=	addr_tdr1;
								ADDR_TCMP0	:	tmp_rdata	=	addr_tcmp0;
								ADDR_TCMP1	:	tmp_rdata	=	addr_tcmp1;
								ADDR_TIER		:	tmp_rdata	=	addr_tier;
								ADDR_TISR		:	tmp_rdata	=	addr_tisr;
								ADDR_THCSR	:	tmp_rdata	=	addr_thcsr;
								default			:	tmp_rdata	=	32'h0;
						endcase
				end	else	begin
						tmp_rdata	=	32'h0;
				end
		end

		assign	rdata	=	tmp_rdata;

endmodule
