module inv #(parameter WIDTH = 256)
   (
   input wire               clk,
   input wire               reset_n,
   input wire               start_inv,
   input wire [WIDTH - 1:0] a,  //sua
   input wire [WIDTH - 1:0] P,
	
   output wire              done_inv,
   output wire [WIDTH:0]    result
   ); 

   ////////////////////////////
   //INTERNAL WIRES DECLARATION
   reg [WIDTH -1 :0] k; 
   reg [WIDTH - 1:0] nu_in;  //sua
   reg               start;

   wire [WIDTH:0]      u;
   wire [WIDTH:0]      v;
   wire [WIDTH:0]      r;
   wire [WIDTH:0]      s;
   	
   wire [WIDTH:0]     u_cal;
   wire [WIDTH:0]     v_cal;
   wire [WIDTH:0]     r_cal;
   wire [WIDTH:0]     s_cal;
   
   wire               done_denta;
   wire               done_sigma;

   wire [1:0]         sel_u;
   wire [1:0]         sel_v;
   wire [1:0]         sel_r;
   wire [1:0]         sel_s;
   wire [2:0]         sel_denta;
   wire [1:0]         sel_sigma;

   wire               start_denta;
   wire               start_sigma;

   reg  [WIDTH:0] 	 nu1_denta; 
   reg  [WIDTH:0]     nu2_denta;
   wire               c_denta;
	wire [WIDTH:0]     denta_result;
   
   
   reg  [WIDTH:0] 	 nu1_sigma;
   reg  [WIDTH:0] 	 nu2_sigma;
   wire               c_sigma;
	wire [WIDTH:0]     sigma_result;
   
//	reg [WIDTH:0]      u1;
//   reg [WIDTH:0]      v1;
//   reg [WIDTH:0]      r1;
//   reg [WIDTH:0]      s1;
//	reg [WIDTH:0]      denta_result1;
//   reg                done_denta1;
//   reg                done_sigma1;
	
   always @(posedge clk or negedge reset_n) begin
      if(!reset_n) begin
         start  <= 'b0;
         nu_in  <= 'd0;
//			u1 <= 'd0;
//			v1 <= 'd0;
//			r1 <= 'd0;
//			s1 <= 'd0;
//			denta_result1 <= 'd0;
//			done_denta1   <= 'd0;
//			done_sigma1   <= 'd0;
      end
      else begin
         start  <= start_inv;
         nu_in  <= a;
//			u1 <= u;
//			v1 <= v;
//			r1 <= r;
//			s1 <= s;
//			denta_result1 <= denta_result;
//			done_denta1   <= done_denta;
//			done_sigma1   <= done_sigma;
      end
   end
   
	
	
   inv_control inv_ctrl (
										.clk(clk),
										.reset_n(reset_n),
										.u(u),
										.v(v),
										.r(r),
										.s(s),
										.nu_in(nu_in),
										.P(P),
										.start_inv(start),
										.denta_result(denta_result),
										.done_denta(done_denta),
										.done_sigma(done_sigma),
										
										.u_cal(u_cal),
										.v_cal(v_cal),
										.r_cal(r_cal),
										.s_cal(s_cal),
										.sel_u(sel_u),
										.sel_v(sel_v),
										.sel_r(sel_r),
										.sel_s(sel_s),
										.sel_denta(sel_denta),
										.sel_sigma(sel_sigma),
										.start_denta(start_denta),
										.start_sigma(start_sigma),
										.done_inv(done_inv),
										.inv(result)
   );

      e_ppn_add_sub u_denta (
										.clk(clk),
										.reset_n(reset_n),
										.start_add_sub(start_denta),
										.a_i(nu1_denta),
										.b_i(nu2_denta),
										.add_sub_sel(1'b1),
										.done_add(done_denta),
										.s_o(denta_result),
										.c_o(c_denta)
   );
   
      e_ppn_add_sub u_sigma (
										.clk(clk),
										.reset_n(reset_n),
										.start_add_sub(start_sigma),
										.a_i(nu1_sigma),
										.b_i(nu2_sigma),
										.add_sub_sel(1'b0),
										.done_add(done_sigma),
										.s_o(sigma_result),
										.c_o(c_sigma)
   );

assign u = (sel_u == 0) ? u_cal: ((sel_u == 1) ? {1'b0,u_cal[WIDTH:1]}: {1'b0,denta_result[WIDTH:1]});
assign v = (sel_v == 0) ? v_cal: ((sel_v == 1) ? {1'b0,v_cal[WIDTH:1]}: {1'b0,denta_result[WIDTH:1]});
assign r = (sel_r == 0) ? r_cal: ((sel_r == 1) ? {r_cal[WIDTH - 1:0],1'b0}: ((sel_r == 2) ? sigma_result[WIDTH:0]: {denta_result[WIDTH - 1:0],1'b0}));
assign s = (sel_s == 0) ? s_cal: ((sel_s == 1) ? {s_cal[WIDTH - 1:0],1'b0}: ((sel_s == 2) ? sigma_result[WIDTH:0]: {1'b0,sigma_result[WIDTH:1]}));
   
	always @(*) begin                           //sel denta
         case (sel_denta)
            'd0: begin // r - s
                nu1_denta <= r_cal;
                nu2_denta <= s_cal;
            end
            'd1: begin // s - r
                nu1_denta <= s_cal;
                nu2_denta <= r_cal;
            end
				'd2: begin // u - v
                nu1_denta <= u_cal;
                nu2_denta <= v_cal;
            end
				'd3: begin // v - u
                nu1_denta <= v_cal;
                nu2_denta <= u_cal;
            end
				'd4: begin // r - p
                nu1_denta <= r_cal;
                nu2_denta <= {1'b0,P[WIDTH-1:0]};
            end
				'd5: begin // p - r
                nu1_denta <= {1'b0,P[WIDTH-1:0]};
                nu2_denta <= r_cal;
            end
				'd6: begin // 2* p - r
                nu1_denta <= {P[WIDTH-1:0],1'b0};
                nu2_denta <= r_cal;
            end				
            default: begin
                nu1_denta <= 'd0;
                nu2_denta <= 'd0;
            end
         endcase
   end

   always @(*) begin //sel_sigma 
         case (sel_sigma)
            'd0: begin // denta + s
                nu1_sigma <= denta_result;
                nu2_sigma <= s_cal;
            end
            'd1: begin // denta + r
                nu1_sigma <= denta_result;
                nu2_sigma <= r_cal;
            end
            'd2: begin // r + s
                nu1_sigma <= r_cal;
                nu2_sigma <= s_cal;
            end
            'd3: begin // s + P
                nu1_sigma <= s_cal;
                nu2_sigma <= {1'b0,P[WIDTH-1:0]};
            end		
         endcase
   end

	always @(posedge clk or negedge reset_n) begin
		if(!reset_n) begin                           
			k <= 0;
		end
		else begin
			if (start_inv) begin
				k <= k + 1;
			end
			else begin
				k <= k;
			end
			
		end
	end

endmodule