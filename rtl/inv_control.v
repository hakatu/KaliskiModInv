module inv_control #(
   parameter WIDTH = 256   //sua
) (
  // Global
  input                     clk,
  input                     reset_n,
  
  // Input
  input wire [WIDTH:0]      u,
  input wire [WIDTH:0]      v,
  input wire [WIDTH:0]      r,
  input wire [WIDTH:0]      s,
  input wire [WIDTH-1:0]    P,
  input wire [WIDTH-1:0]    nu_in,
  
  input wire                start_inv,
  
  input wire [WIDTH:0]	    denta_result,
  
  input wire                done_denta,
  input wire                done_sigma,
  // Output
  output reg [WIDTH:0]      u_cal,
  output reg [WIDTH:0]      v_cal,
  output reg [WIDTH:0]      r_cal,
  output reg [WIDTH:0]      s_cal,
  
  output reg [1:0]          sel_u,
  output reg [1:0]          sel_v,
  output reg [1:0]          sel_r,
  output reg [1:0]          sel_s,
  output reg [2:0]          sel_denta,
  output reg [1:0]          sel_sigma,
  
  output reg                start_denta,
  output reg                start_sigma,

  output reg                done_inv,
  output reg [WIDTH:0]      inv
);

  // local declarations

  localparam [4:0] IDLE        = 5'b00001;
  localparam [4:0] LOAD        = 5'b00010;
  localparam [4:0] CHECK       = 5'b00100;
  localparam [4:0] DONE        = 5'b01000;
  localparam [4:0] DONE2       = 5'b10000;
  
  //wire [WIDTH - 2:0] PRIME    = 256'd115792089237316195423570985008687907853269984665640564039457584007908834671663;
  //wire [WIDTH - 2:0] ADJUST_M = 256'd4294968273;     // do not change
  reg [4:0] state;
  reg [4:0] n_state;
  
  reg [10:0]  pi0;
  reg         sel;
  wire        uv_gt;
  wire        uv_eq;
  wire        uv_lt;
  wire        rp_gt;
  wire        rp_eq;
  wire        rp_lt;
  wire        p0_gt;
  wire        p0_eq;
  wire        p0_lt;
  //wire [WIDTH:0] P_t;
  // Conbinational Logic
   //assign P_t = {}
   compare_256bit compare_0 (.a(u), .b(v), .eq(uv_eq), .gt(uv_gt), .lt(uv_lt));
	compare_256bit compare_1 (.a(r), .b({1'b0,P}), .eq(rp_eq), .gt(rp_gt), .lt(rp_lt));
	compare_32bit  compare_2 (.a({21'd0,pi0}), .b(32'd512), .eq(p0_eq), .gt(p0_gt), .lt(p0_lt));	
   always @(*) begin
      case(state)
         IDLE: begin
            n_state = start_inv ? LOAD : IDLE;
         end
         LOAD: begin
            n_state = CHECK;
         end
         CHECK: begin
			   if (p0_lt) begin
					n_state = CHECK;
				end else begin
				   n_state <= DONE;
				end
         end
        DONE: begin
           n_state = done_denta ? DONE2 : DONE;
        end
		  DONE2: begin
           n_state = IDLE;
        end
        default: begin
           n_state = IDLE;
        end
     endcase
  end

  // State Register

  always @(posedge clk or negedge reset_n) begin
     if(!reset_n) begin
        state <= IDLE;
     end
	  else if (!start_inv) begin
		  state <= IDLE;	
	  end
     else begin
        state <= n_state;
     end
  end

 always @(posedge clk or negedge reset_n) begin
      if(!reset_n) begin
         sel <= 1'b0;
      end
      else begin
         sel <= (pi0 == 0 && ((state != CHECK))) ? 1'b1 : 1'b0;
      end
  end
  
  reg [3:0] debug;
  
  // Output Logic
  always @(posedge clk or negedge reset_n) begin
     if(!reset_n) begin
        pi0            <= 'd0;
        u_cal          <= 'd0;
        v_cal          <= 'd0;
        r_cal          <= 'd0;
        s_cal          <= 'd0;
        sel_u          <= 'd0;
        sel_v          <= 'd0;
        sel_r          <= 'd0;
        sel_s          <= 'd0;
        start_denta    <= 'd0;
        start_sigma    <= 'd0;
        done_inv       <= 'd0;
//        inv_nu         <= 'd0;
        sel_denta      <= 'd0;
        sel_sigma      <= 'd0; 
		  inv            <= 'd0;
     end
     else begin
        case(state)
           IDLE: begin
              pi0                <= 'd0;
              u_cal              <= 'd0;
              v_cal              <= 'd0;
              r_cal              <= 'd0;
              s_cal              <= 'd0;
              sel_u              <= 'd0;
              sel_v              <= 'd0;
              sel_r              <= 'd0;
              sel_s              <= 'd0;
              start_denta        <= 'd0;
              start_sigma        <= 'd0;
              done_inv           <= 'd0;
//              inv_nu             <= 256'd0;				  
              sel_denta          <= 'd0;
              sel_sigma          <= 'd0; 
				  inv                <= inv;
           end
           LOAD: begin
              pi0                <= pi0;
				  u_cal              <= sel ? {1'b0,P} : u;
              v_cal              <= sel ? {1'b0,nu_in} : v;
              r_cal              <= sel ? 'd0 : r;
              s_cal              <= sel ? 'd1 : s;
              sel_u              <= 'd0;
              sel_v              <= 'd0;
              sel_r              <= 'd0;  
              sel_s              <= 'd0;
              start_denta        <= 'd0;
              start_sigma        <= 'd0;
              done_inv           <= 'd0;
//              inv_nu             <= 256'd0;
              sel_denta          <= 'd0;
              sel_sigma          <= 'd0;
				  inv                <= inv;
           end
           CHECK: begin
						if(v > 'd0) begin
							if(u[0] == 'b0) begin
								pi0                <= pi0 + 11'd1;
								u_cal 					<= u_cal;
								v_cal 					<= v_cal;
								r_cal 					<= r_cal;
								s_cal 					<= s_cal;
								sel_u              <= 2'b01;       // u / 2 
								sel_v              <= 2'b00;       // giu nguyen
								sel_r              <= 2'b10;       // sigma
								sel_s              <= 2'b01;       // 2 * s
								start_denta        <= 'b1;
								start_sigma        <= 'b1;
								done_inv           <= 'd0;
//              inv_nu             <= 256'd0;
								sel_denta          <= 3'b000;   // r -s
								sel_sigma          <= 2'b00;    //denta + s
								inv                <= 'd0;
								debug <= 'd1;
							end else begin
								if(v[0] == 'b0) begin
									pi0                <= pi0 + 11'd1;
									u_cal 					<= u_cal;
									v_cal 					<= v_cal;
									r_cal 					<= r_cal;
									s_cal 					<= s_cal;
									sel_u              <= 2'b00;       // giu nguyen
									sel_v              <= 2'b01;       // v / 2
									sel_r              <= 2'b01;       // 2 * r
									sel_s              <= 2'b10;       // sigma    
									start_denta        <= 'b1;
									start_sigma        <= 'b1;
									done_inv           <= 'd0;
//              inv_nu             <= 256'd0;
									sel_denta          <= 3'b001;  // s - r
									sel_sigma          <= 2'b01;   // denta + r
									inv                <= 'd0;
									debug <= 'd2;
								end else begin
									if(uv_gt) begin
										pi0                <= pi0 + 11'd1;
										u_cal 					<= u_cal;
										v_cal 					<= v_cal;
										r_cal 					<= r_cal;
										s_cal 					<= s_cal;
										sel_u              <= 2'b10;       // denta / 2
										sel_v              <= 2'b00;       // giu nguyen
										sel_r              <= 2'b10;       // sigma
										sel_s              <= 2'b01;       // 2 * s 
										start_denta        <= 'b1;
										start_sigma        <= 'b1;
										done_inv           <= 'd0;
//              inv_nu             <= 256'd0;
										sel_denta          <= 3'b010;  // u - v
										sel_sigma          <= 2'b10;   // r + s
										inv                <= 'd0;
										debug <= 'd3;
									end else begin
										pi0                <= pi0 + 11'd1;
										u_cal 					<= u_cal;
										v_cal 					<= v_cal;
										r_cal 					<= r_cal;
										s_cal 					<= s_cal;
										sel_u              <= 2'b00;       // giu nguyen
										sel_v              <= 2'b10;       // denta / 2
										sel_r              <= 2'b01;       // 2 * r  
										sel_s              <= 2'b10;       // sigma    
										start_denta        <= 'b1;
										start_sigma        <= 'b1;
										done_inv           <= 'd0;
//              inv_nu             <= 256'd0;
										sel_denta          <= 3'b011;  // v - u
										sel_sigma          <= 2'b10;   // r + s
										inv                <= 'd0;
										debug <= 'd4;
									end
								end
							end
						end else begin
							if(rp_gt) begin
								pi0                <= pi0 + 11'd1;
								u_cal 					<= u_cal;
								v_cal 					<= v_cal;
								r_cal 					<= r_cal;
								s_cal 					<= s_cal;
								sel_u              <= 2'b00;       // giu nguyen
								sel_v              <= 2'b00;       // giu nguyen 
								sel_r              <= 2'b11;       // 2 * denta
								sel_s              <= 2'b11;       // sigma / 2     
								start_denta        <= 'b1;
								start_sigma        <= 'b1;
								done_inv           <= 'd0;
//              inv_nu             <= 256'd0;
								sel_denta          <= 3'b100;  // r - p
								sel_sigma          <= 2'b11;   // s + p
								inv                <= 'd0;
								debug <= 'd5;
							end else begin
								pi0                <= pi0 + 11'd1;
								u_cal 					<= u_cal;
								v_cal 					<= v_cal;
								r_cal 					<= r_cal;
								s_cal 					<= s_cal;
								sel_u              <= 2'b00;       // giu nguyen
								sel_v              <= 2'b00;       // giu nguyen
								sel_r              <= 2'b01;       // 2 * r
								sel_s              <= 2'b11;       // sigma / 2
								start_denta        <= 'b1;
								start_sigma        <= 'b1;
								done_inv           <= 'd0;
//              inv_nu             <= 256'd0;
								sel_denta          <= 3'b100;  // r - p
								sel_sigma          <= 2'b11;   // s + p
								inv                <= 'd0;
								debug <= 'd6;
							end
						end							
           end		  
           DONE: begin
              pi0              <= pi0;
              u_cal            <= u_cal;
              v_cal            <= v_cal;
              r_cal            <= r_cal;
              s_cal            <= s_cal;
              sel_u            <= sel_u;
              sel_v            <= sel_v;
              sel_r            <= sel_r;
              sel_s            <= sel_s;
              start_denta      <= 'b1;
              start_sigma      <= 'd0;
              done_inv         <= 1'b0;
//              inv_nu           <= r[255:0];
              sel_denta        <= (r > 0) ? 3'b110  : 3'b101;
              sel_sigma        <= sel_sigma;
				  inv              <= 'd0;
           end
           DONE2: begin
              pi0              <= 'd0;
              u_cal            <= 'd0;
              v_cal            <= 'd0;
              r_cal            <= 'd0;
              s_cal            <= 'd0;
              sel_u            <= 'd0;
              sel_v            <= 'd0;
              sel_r            <= 'd0;
              sel_s            <= 'd0;
				  start_denta      <= 'd0;
              start_sigma      <= 'd0;
              done_inv         <= 'd1;
//              inv_nu           <= r[255:0];
              sel_denta        <= 'd0;
              sel_sigma        <= 'd0;
				  inv              <= denta_result;
           end			  
           default: begin
              pi0              <= 'd0;
              u_cal            <= 'd0;
              v_cal            <= 'd0;
              r_cal            <= 'd0;
              s_cal            <= 'd0;
              sel_u            <= 'd0;
              sel_v            <= 'd0;
              sel_r            <= 'd0;
              sel_s            <= 'd0;
				  start_denta      <= 'd0;
              start_sigma      <= 'd0;
              done_inv         <= 'd0;
//              inv_nu           <= 256'd0;
              sel_denta        <= 'd0;
              sel_sigma        <= 'd0;
				  inv              <= 'd0;
           end
        endcase
     end
  end
endmodule
