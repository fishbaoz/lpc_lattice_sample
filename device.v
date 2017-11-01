//`timescale 1ns / 1ps

`define LPC_POST_ADD    16'h080
`define LPC_COM0_ADD    16'h3F8

module device (
	LPC_CLK,
	LPC_RST_n,
//	LPC_D0,
//	LPC_D1,
//	LPC_D2,
//	LPC_D3,
	LPC_AD,
	LPC_FRAME,

	UART_TX,
	UART_RX,
	SEG7_LED		// 主板前面板LED控制 低电平灯亮

//	LED_0, LED_1, LED_2, LED_3,
);
	input LPC_CLK;
	input LPC_RST_n;
//	inout LPC_D0;
//	inout LPC_D1;
//	inout LPC_D2;
//	inout LPC_D3;
	inout wire [3:0] LPC_AD;    		// Address/Data Bus
	input LPC_FRAME;

	output UART_TX;
	input UART_RX;
	output wire [7:0] SEG7_LED;

//	output LED_0, LED_1, LED_2, LED_3;

	wire [7:0] tx_data;
	wire tx_data_valid;
	wire [7:0] rx_data;
	wire rx_data_valid;
	wire tx_busy;

//	reg    sim_clk = 0;
//	wire [3:0] led_value;// = 4'b1001;
	wire addr_hit;
	wire [15:0] lpc_addr;
	wire [7:0] lpc_din;
	wire [7:0] lpc_dout;

	wire [7:0] postcode;
	//always #15 sim_clk = ~sim_clk;
	assign addr_hit =
//	`ifdef POST_CODE
			 (lpc_addr == `LPC_POST_ADD) ||
//	`endif
//	`ifdef COM0_UART
			 //((lpc_addr >= `LPC_COM0_ADD) && (lpc_addr <= (`LPC_COM0_ADD+7))) ||
			 (lpc_reg[0] && (lpc_addr >= `LPC_COM0_ADD) && (lpc_addr <= (`LPC_COM0_ADD+7)));// ||
//	`endif

	LPC_Peri LPC_Peri_0(
		// LPC Interface
		.lclk(LPC_CLK),					// Clock
		.lreset_n(LPC_RST_n),			// Reset - Active Low (Same as PCI Reset)
		.lframe_n(LPC_FRAME),			// Frame - Active Low
		.lad_in(LPC_AD),				// Address/Data Bus

//	.lpc_data_out(),				// 用于测试
//
	.lpc_en(lpc_en),				// 后端总线使能信号,高电平时总线有效
	.addr_hit(addr_hit),			// 地址匹配置1,不匹配置0
	.lpc_addr(lpc_addr),			// LPC地址
	.din(lpc_din),					// LPC读的时候后端输入的数据
	.lpc_data_in(lpc_dout),         // LPC写的时候给后端的输出数据
	.io_rden_sm(lpc_io_rden),       // 读使能信号
	.io_wren_sm(lpc_io_wren)       // 写使能信号
//	.int_serirq(int_serirq),		// 串行中断输入
//	//.serirq({3'b000,com0_irq,4'b0000})							// 中断输入 高电平有效
//	.serirq({3'b000,com0_irq,4'b000})
);

//	lpc lpc0 (LPC_CLK, LPC_RST, { LPC_D3, LPC_D2, LPC_D1, LPC_D0 }, LPC_FRAME, tx_data, tx_data_valid, rx_data, rx_data_valid, tx_busy);
//	uart_tx uart_tx0 (LPC_CLK, tx_data, tx_data_valid, UART_TX, tx_busy /*, led_value */);
//	uart_rx uart_rx0 (LPC_CLK, rx_data, rx_data_valid, UART_RX);

//	assign {LED_3, LED_2, LED_1, LED_0} = led_value;

//	always @(posedge LPC_CLK)
//	begin
//		led_value <= 4'b1010;
//	end

	LPC_POSTCODE LPC_POSTCODE_7(
		.lclk(LPC_CLK), // Clock
		.lreset_n(LPC_RST_n), // Reset - Active Low (Same as PCI Reset)
		.lpc_en(lpc_en), // 后端总线使能信号,高电平时总线有效
		.device_cs(addr_hit & (lpc_addr == `LPC_POST_ADD)),
//		.addr(index_add), // 地址
		.din(lpc_dout),
		.dout(),
		.io_rden(),
		.io_wren(lpc_io_wren),
		.postcode(postcode)
	);
	LPC_COM LPC_COM0(
		.lclk(LPC_CLK),					// Clock 33MHz
		.lreset_n(LPC_RSTn),				// Reset - Active Low (Same as PCI Reset)
//		.lpc_en(lpc_en),				// 后端总线使能信号,高电平时总线有效
		.device_cs(addr_hit && (lpc_addr >= `LPC_COM0_ADD) && (lpc_addr <= `LPC_COM0_ADD+7)),
		.addr(lpc_addr - `LPC_COM0_ADD),			// 地址
		.din(lpc_dout),
		.dout(lpc_din),
		.io_rden(lpc_io_rden),
		.io_wren(lpc_io_wren),
//		.com_irq(com0_irq),
//
//		.clk_24mhz(clk_24mhz),			// 24MHz时钟输入
		.tx(UART_TX),
		.rx(UART_RX)
//		.baud_clk()			// 波特率时钟输出
	);

endmodule
