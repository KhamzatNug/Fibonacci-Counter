`timescale 1ns/100ps


module Fibo_Counter(result, Ready,data1, data2, data3, Start, clock, reset);
	parameter R_size = 16, C_size = 8;
	output [R_size-1:0] result;
	output Ready;
	input [R_size-1:0] data1, data2;
	input [C_size-1:0] data3;
	input Start, clock, reset;
	wire  Load_regs, Decr_C, Change_regs, Start, Zero;
	Controller C0(Ready, Load_regs, Decr_C, Change_regs, Start, Zero, clock, reset);
	DataPath D0(result, Zero, data1, data2, data3, Load_regs, Decr_C, Change_regs, clock);

endmodule 


module Controller(Ready, Load_regs, Decr_C, Change_regs, Start, Zero, clock, reset);
 output reg Ready, Load_regs, Decr_C, Change_regs;
 input Start, Zero, clock, reset;

 reg [2:0] state, next_state;
 parameter S0 = 3'b001, S1 = 3'b010, S2 = 3'b100;

 always @(posedge clock, negedge reset)
 	if (reset==0) state <= S0;
 	else state <= next_state;

 always @* begin 
 	next_state = S0;
 	case (state)
 		S0: if (Start) next_state = S1; else next_state = S0;
 		S1: if (Zero) next_state = S0; else next_state = S2;
 		S2: next_state = S1;
 	endcase
 end

 always @* begin
 	Ready = 0;
 	Load_regs = 0;
 	Decr_C = 0;
 	Change_regs = 0;
 	case (state)
 		S0: begin Ready = 1; if (Start) Load_regs = 1; end
 		S1: if (!Zero) Decr_C = 1;
 		S2: Change_regs = 1;
 	endcase
 end 

endmodule 

module DataPath(result, Zero, data1, data2, data3, Load_regs, Decr_C, Change_regs, clock);
	parameter R_size = 16, C_size = 8;
	output [R_size-1:0] result;
	output Zero;
	input [R_size-1:0] data1, data2;
	input [C_size-1:0] data3;
	input Load_regs, Decr_C, Change_regs, clock;

	reg [R_size-1:0] R1, R2;
	reg [C_size-1:0] C;

	always @(posedge clock) begin
		if (Load_regs) begin 
			R1 <= data1;
			R2 <= data2;
			C <= data3;
		end 

		if (Decr_C) 
			C <= C-1;

		if (Change_regs) begin 
			R1 <= R2;
			R2 <= R1+R2;
		end 
	end

	assign result = R2;
	assign Zero = (C == 0);

endmodule 



module test_bench;
	parameter R_size = 16, C_size = 8;
	reg [R_size-1:0] data1, data2;
	reg [C_size-1:0] data3;
	reg Start, clock, reset;
	wire [R_size-1:0] result;
	wire Ready;
	Fibo_Counter F0(result, Ready, data1, data2, data3, Start, clock, reset);

	initial #200 $finish;

	initial begin clock = 0; forever #5 clock = ~clock; end

	initial fork
		reset = 0;
		data1 = 16'b0000_0000_0000_0100;
		data2 = 16'b0000_0000_0000_0101;
		data3 = 8'b0000_0110;

		#3 reset = 1;
		#10 Start = 1;
		#20 Start = 0;
	join

	initial begin 
		$monitor("R1 = 16%b R2 = 16%b result = %16b", F0.D0.R1, F0.D0.R2, result);
	end 

endmodule

