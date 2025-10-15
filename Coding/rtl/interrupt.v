module	interrupt	(
		input		wire			sys_clk,
		input		wire			sys_rst_n,
		input		wire			int_en,
		input 	wire			int_st,

		output	wire			tim_int
);

		assign	tim_int	=	int_en	&	int_st;

endmodule
