module e_ppn_add_257 (
   input wire           clk,
   input wire           reset_n,
	input wire           c_i,
   input wire  [256:0]  a_i,
   input wire  [256:0]  b_i,
	
   output wire          c_o,
   output wire [256:0]  s_o
   );
	parameter N = 257;
	
	wire         c_o_temp;
	wire [N-1:0] s_o_temp;
		 
	BKAA add_0 (.clk(clk),
	               .rst_ni(reset_n),
						.A(a_i[N-2:0]),
						.B(b_i[N-2:0]),
						.C_in(c_i),
						.Cout(c_o_temp),
						.Sum(s_o_temp[N-2:0])
					  );
	assign s_o[N-2:0] = s_o_temp[N-2:0];			 
	assign {c_o,s_o[N-1]} = a_i[N-1] +b_i[N-1] + c_o_temp;	
endmodule
