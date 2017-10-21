module LPC_POSTCODE
(
  input lclk				, // Clock
  input lreset_n			, // Reset - Active Low (Same as PCI Reset)
  input lpc_en				, //
  input device_cs			,
  input [15:0] addr			, //
  input [7:0] din           ,
  output wire [7:0] dout     ,
  input io_rden				,
  input io_wren				,

  output reg [7:0] postcode

);

assign dout = 8'hzz;

//
always @ (posedge lclk or negedge lreset_n) begin
	$display("cs=%x, io_wren=%x, reset=%x, lpc_en=%x\n", device_cs, io_wren, lreset_n, lpc_en);
	if(!lreset_n)
		postcode <= 0;
	else if(device_cs & io_wren/* & lpc_en */) begin
		postcode <= din;
		$display("postcode=%x\n", postcode);
	end
	else
		postcode <= postcode;
end

endmodule
