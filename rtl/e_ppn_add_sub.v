module e_ppn_add_sub (
   input wire           clk,
   input wire           reset_n,
	input wire           start_add_sub,
   input wire  [256:0]  a_i,
   input wire  [256:0]  b_i,
   input wire           add_sub_sel, // 0 = +, 1 = -
   output wire          c_o,
	output wire           done_add,
   output wire [256:0]  s_o
   );
	parameter N = 257;
	
	reg  [N-1:0] a_i_temp;
	reg  [N-1:0] b_i_temp;
	reg          add_sub_sel_temp;
	
 //  assign b_i_temp = (add_sub_sel) ? ~b_i : b_i;
	 
	e_ppn_add_257 add_0 (.clk(clk),
	                     .reset_n(reset_n),
								.a_i(a_i_temp),
								.b_i(b_i_temp),
								.c_i(add_sub_sel_temp),
								.c_o(c_o),
								.s_o(s_o)
					  );
					  	
   always @(*) begin
		if(start_add_sub == 1) begin
			a_i_temp <= a_i;
			b_i_temp = (add_sub_sel) ? ~b_i : b_i;
			add_sub_sel_temp <= add_sub_sel;
      end
      else begin
         a_i_temp <= a_i;
			b_i_temp <= b_i;
			add_sub_sel_temp <= add_sub_sel;
      end
   end
/*	
   always @(posedge clk or negedge reset_n) begin
      if(!reset_n) begin
         done_add <= 1'b0;
      end
      else begin
         done_add <= start_add_sub;
      end
   end
*/
assign done_add = start_add_sub;
	endmodule
