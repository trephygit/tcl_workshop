module memory (CLK,ADDR,DIN,DOUT);
parameter WordSize = 1;
parameter addressSize =1;

input ADDR,CLK;
input [WordSize-1:0] DIN;
output reg [WordSize-1:0] DOUT;
reg [WordSize:0] mem [0:(1<<addressSize)-1];

always @(posedge CLK) begin 
	mem[ADDR] <= DIN;
	DOUT <= mem[ADDR];
end
endmodule

