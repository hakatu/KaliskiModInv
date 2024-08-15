`define INPUT_SIZE_SIZE 256		//set the input size n
`define GROUP_SIZE_SIZE 4		  //set the group size = 1, 2, 4, 8 or 16

module BKAA(
	input wire                      			clk, rst_ni,
	input	wire  [`INPUT_SIZE_SIZE - 1:0]  	A,
	input	wire  [`INPUT_SIZE_SIZE - 1: 0]	B,
	input                           			C_in,
	output wire  [`INPUT_SIZE_SIZE - 1:0]  	Sum,
	output wire                     			Cout
	);
	
	
wire  [`INPUT_SIZE_SIZE - 1: 0]								S;
wire	[`INPUT_SIZE_SIZE - 1:0]		   					S_tmp;
wire	[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE * 2 - 1:0]	r;
wire  [`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE * 2 - 1:0] r_out;	
wire	[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE * 2 - 1:0]	r_temp;
wire	[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE * 2 - 1:0]	r_temp_out;
wire	[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE:0]			cin;
wire	[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE:0]			cin_out;
wire	[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE * 2 - 1:0]	q;
wire	[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE * 2 - 1:0]	q_out;





	assign cin[0] = C_in;
	
	generate
	genvar i;
	
	
	for(i = 0;i < `INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE;i = i + 1) begin: parallel_FA_FA_FA //test
		group_q_q_q #(.Group_size_SIZE(`GROUP_SIZE_SIZE))
f(.a(A[`GROUP_SIZE_SIZE * (i + 1) - 1:`GROUP_SIZE_SIZE * i]),
		  .b(B[`GROUP_SIZE_SIZE * (i + 1) - 1:`GROUP_SIZE_SIZE * i]),
		  .cin(cin[i]),
		  .s(S[`GROUP_SIZE_SIZE * (i + 1) - 1:`GROUP_SIZE_SIZE * i]),
		  .qg(q[i * 2 + 1: i * 2]));
end

/*
for (i = 0; i < `INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE; i = i + 1) begin: registerP
reg_reg_reg_1
r4(.clk(clk),
		   .rst_ni(rst_ni),
		   .data_in(q[i * 2 + 1: i * 2]),
		   .data_out(q_out[i * 2 + 1: i * 2])
);
end*/
	
	first_half_half_half #(.Treesize(`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE))
t1(.q(q[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE * 2 - 1: 0]),
	   .r(r[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE * 2 - 1: 0])
);


	
	second_half_half_half #(.Treesize(`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE)) //original
t2(.q(r[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE * 2 - 1: 0]),
	   .r(r_out[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE * 2 - 1: 0])
);

/*
for (i = 0; i < `INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE; i = i + 1) begin: registerC
reg_reg_reg_1
r6(.clk(clk),
		   .rst_ni(rst_ni),
		   .data_in(r_out[2 * i + 1: 2 * i]),
		   .data_out(r_temp_out[2 * i + 1: 2 * i])
);
end*/

for (i = 0; i < `INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE; i = i + 1) begin: cin_generation
		cin_gen_cin_gen f(	.r(r_out[2 * i + 1: 2 * i]),
										.c0(C_in),
										.cin(cin[i + 1]));
end

		
	assign Sum = S[`INPUT_SIZE_SIZE - 1:0]; //original
	
	assign Cout = cin[`INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE]; //original	
	endgenerate
	
/*
always @(posedge clk or negedge rst_ni) begin
	if(!rst_ni) begin
		Sum_tmp <= 0;
		Cout_tmp <= 0;
	end else begin
		Sum_tmp <= Sum;
		Cout_tmp <= Cout;
	end
end
*/	
endmodule


//Cin_gen_cin_gen
module cin_gen_cin_gen(r,c0,cin);

	input	[1:0]	r;
	input		c0;
	output		cin;
	
	assign cin = (r[0] & c0) | r[1];
	
endmodule


module group_q_q_q #(parameter Group_size_SIZE = `GROUP_SIZE_SIZE) (a, b, cin, s, qg);

input[Group_size_SIZE - 1: 0]a;
input[Group_size_SIZE - 1: 0]b;
	input				         cin;
output[Group_size_SIZE - 1: 0]s;
output[1: 0]qg;

wire[2 * Group_size_SIZE - 1: 0]q;
wire[Group_size_SIZE - 1: 0]c;
	
	assign c[0] = cin;

generate
	genvar i;
for (i = 0; i < Group_size_SIZE; i = i + 1) begin: parallel_FA_FA_FA
		FA_FA_FA f(.a(a[i]),
						.b(b[i]),
						.cin(c[i]),
						.s(s[i]),
						.q(q[i * 2 + 1: i * 2]));
if (i != Group_size_SIZE - 1) begin: special_case
			assign c[i + 1] = q[i * 2 + 1] | q[i * 2] & c[i];
end
end

//group q generation based on the Group_size_SIZE
if (Group_size_SIZE == 1) begin: case_gs1
		assign qg[1] = q[1];
		assign qg[0] = q[0];
end
	else if (Group_size_SIZE == 2) begin: case_gs2
		assign qg[1] = q[3] | (q[1] & q[2]);
		assign qg[0] = q[2] & q[0];
end
	else if (Group_size_SIZE == 4) begin: case_gs4
		assign qg[1] = q[7] | (q[5] & q[6]) | (q[3] & q[6] & q[4]) | (q[1] & q[6] & q[4] & q[2]);
		assign qg[0] = q[6] & q[4] & q[2] & q[0];
end
	else if (Group_size_SIZE == 8) begin: case_gs8b
		assign qg[1] = q[15] | (q[13] & q[14]) | (q[11] & q[14] & q[12]) | (q[9] & q[14] & q[12] & q[10]) | (q[7] & q[14] & q[12] & q[10] & q[8]) | (q[5] & q[14] & q[12] & q[10] & q[8] & q[6]) | (q[3] & q[14] & q[12] & q[10] & q[8] & q[6] & q[4]) | (q[1] & q[14] & q[12] & q[10] & q[8] & q[6] & q[4] & q[2]);
		assign qg[0] = q[14] & q[12] & q[10] & q[8] & q[6] & q[4] & q[2] & q[0];
end 
	else if (Group_size_SIZE == 16) begin: case_gs16
		assign qg[1] = q[31] | (q[29] & q[30]) | (q[27] & q[30] & q[28]) | (q[25] & q[30] & q[28] & q[26]) | (q[7] & q[30] & q[28] & q[26] & q[24]) | (q[21] & q[30] & q[28] & q[26] & q[24] & q[22]) | (q[19] & q[30] & q[28] & q[26] & q[24] & q[22] & q[20]) | (q[17] & q[30] & q[28] & q[26] & q[24] & q[22] & q[20] & q[18]) | (q[15] & q[30] & q[28] & q[26] & q[24] & q[22] & q[20] & q[18] & q[16]) | (q[13] & q[30] & q[28] & q[26] & q[24] & q[22] & q[20] & q[18] & q[16] & q[14]) | (q[11] & q[30] & q[28] & q[26] & q[24] & q[22] & q[20] & q[18] & q[16] & q[14] & q[12]) | (q[9] & q[30] & q[28] & q[26] & q[24] & q[22] & q[20] & q[18] & q[16] & q[14] & q[12] & q[10]) | (q[7] & q[30] & q[28] & q[26] & q[24] & q[22] & q[20] & q[18] & q[16] & q[14] & q[12] & q[10] & q[8]) | (q[5] & q[30] & q[28] & q[26] & q[24] & q[22] & q[20] & q[18] & q[16] & q[14] & q[12] & q[10] & q[8] & q[6]) | (q[3] & q[30] & q[28] & q[26] & q[24] & q[22] & q[20] & q[18] & q[16] & q[14] & q[12] & q[10] & q[8] & q[6] & q[4]) | (q[1] & q[30] & q[28] & q[26] & q[24] & q[22] & q[20] & q[18] & q[16] & q[14] & q[12] & q[10] & q[8] & q[6] & q[4] & q[2]);
		assign qg[0] = q[30] & q[28] & q[26] & q[24] & q[22] & q[20] & q[18] & q[16] & q[14] & q[12] & q[10] & q[8] & q[6] & q[4] & q[2];
end
endgenerate

endmodule

//FA_cell_CLA
module FA_FA_FA(a, b, cin, s, q);

	input 		a;
	input 		b;
	input 		cin;
	output 		s;
output[1: 0]q;
	
	assign q[0] = a ^ b;
	assign s = q[0] ^ cin;
	assign q[1] = a & b;

endmodule

module reg_reg_reg_1 (
	input wire clk,      // Clock input
		input wire rst_ni,    // Rst_ni input
			input wire[1: 0]data_in,  // Data input (1 bits)
				output wire[1: 0]data_out  // Data output (1 bits)
);

reg[1: 0]reg_data;  // 4-bit register data
    
    always @(posedge clk or negedge rst_ni) begin
if (!rst_ni) begin
reg_data <= 2'b00;  // Rst_ni the register to 0
        end else begin
reg_data <= data_in;  // Load data on each clock edge
end
end

    assign data_out = reg_data;  // Output is the register data

endmodule

module reg_reg_reg_2 (
	input wire clk,      // Clock input
		input wire rst_ni,    // Rst_ni input
			input wire  data_in,  // Data input (1 bits)
				output wire data_out  // Data output (1 bits)
);

    reg  reg_data;  // 1-bit register data
    
    always @(posedge clk or negedge rst_ni) begin
if (!rst_ni) begin
reg_data <= 1'b0;  // Rst_ni the register to 0
        end else begin
reg_data <= data_in;  // Load data on each clock edge
end
end

    assign data_out = reg_data;  // Output is the register data

endmodule

module reg_reg_reg_3 (
	input wire clk,      // Clock input
		input wire rst_ni,    // Rst_ni input
			input wire[`GROUP_SIZE_SIZE-1:0] data_in,  // Data input (4 bits)
    output wire [`GROUP_SIZE_SIZE - 1: 0]data_out  // Data output (4 bits)
);

reg[`GROUP_SIZE_SIZE-1:0] reg_data;  // 8-bit register data
    
    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            reg_data <= 0;  // Rst_ni the register to 0
        end else begin
            reg_data <= data_in;  // Load data on each clock edge
        end
    end

    assign data_out = reg_data;  // Output is the register data

endmodule


module second_half_half_half #(parameter Treesize = `INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE)(q,r);

	input	[Treesize * 2 - 1:0]	q;
	output	[Treesize * 2 - 1:0]	r;
	
	wire	[Treesize * 2 * ($clog2(Treesize) - 1) - 1:0]	r_temp;
	
	assign r_temp[Treesize * 2 - 1:0] = q[Treesize * 2 - 1:0];
	
	generate
	genvar i, j;
	for(i = 0;i < $clog2(Treesize) - 2;i = i + 1) begin: second_half_level
		assign r_temp[Treesize * 2 * (i + 1) + ((Treesize / (2 ** i)) - 1 - 2 ** ($clog2(Treesize / 4) - i)) * 2 - 1:Treesize * 2 * (i + 1)] = r_temp[Treesize * 2 * i + ((Treesize / (2 ** i)) - 1 - 2 ** ($clog2(Treesize / 4) - i)) * 2 - 1:Treesize * 2 * i];
		for(j = (Treesize / (2 ** i)) - 1 - 2 ** ($clog2(Treesize / 4) - i);j < Treesize;j = j + 2 ** ($clog2(Treesize / 2) - i)) begin: second_half_level_logic
			prefix_prefix_prefix f(.ql(r_temp[Treesize * 2 * i + (j - 2 ** ($clog2(Treesize / 4) - i)) * 2 + 1:Treesize * 2 * i + (j - 2 ** ($clog2(Treesize / 4) - i)) * 2]),
						   .qh(r_temp[Treesize * 2 * i + j * 2 + 1:Treesize * 2 * i + j * 2]),
						   .r(r_temp[Treesize * 2 * (i + 1) + j * 2 + 1:Treesize * 2 * (i + 1) + j * 2]));
			if(j != Treesize - 1 - 2 ** ($clog2(Treesize / 4) - i)) begin: second_half_level_direct_connect
				assign r_temp[Treesize * 2 * (i + 1) + (j + 2 ** ($clog2(Treesize / 2) - i)) * 2 - 1:Treesize * 2 * (i + 1) + j * 2 + 2] = r_temp[Treesize * 2 * i + (j + 2 ** ($clog2(Treesize / 2) - i)) * 2 - 1:Treesize * 2 * i + j * 2 + 2];
			end
		end
		assign r_temp[Treesize * 2 * (i + 2) - 1:Treesize * 2 * (i + 2) - (2 ** ($clog2(Treesize / 4) - i)) * 2] = r_temp[Treesize * 2 * (i + 1) - 1:Treesize * 2 * (i + 1) - (2 ** ($clog2(Treesize / 4) - i)) * 2];
	end
	assign r[1:0] = r_temp[Treesize * 2 * ($clog2(Treesize) - 2) + 1:Treesize * 2 * ($clog2(Treesize) - 2)];
	for(i = 1;i < Treesize;i = i + 2) begin: final_r_odd
		assign r[i * 2 + 1:i * 2] = r_temp[Treesize * 2 * ($clog2(Treesize) - 2) + i * 2 + 1:Treesize * 2 * ($clog2(Treesize) - 2) + i * 2];
	end
	for(i = 2;i < Treesize;i = i + 2) begin: final_r_even
		prefix_prefix_prefix f(.ql(r_temp[Treesize * 2 * ($clog2(Treesize) - 2) + i * 2 - 1:Treesize * 2 * ($clog2(Treesize) - 2) + i * 2 - 2]),
					   .qh(r_temp[Treesize * 2 * ($clog2(Treesize) - 2) + i * 2 + 1:Treesize * 2 * ($clog2(Treesize) - 2) + i * 2]),
					   .r(r[i * 2 + 1:i * 2]));
	end
	endgenerate
	
endmodule

module first_half_half_half #(parameter Treesize = `INPUT_SIZE_SIZE / `GROUP_SIZE_SIZE)(q,r);

	//input clk, rst_ni; //test pipeline
	input	[Treesize * 2 - 1:0]	q;
	output	[Treesize * 2 - 1:0]	r;
	
	//wire  [Treesize * 2 - 1:0]	r_temp_temp;
	
	generate
	genvar i;
	if(Treesize == 2) begin: trival_case
		assign r[1:0] = q[1:0];
		
		prefix_prefix_prefix f(.ql(q[1:0]),
							.qh(q[3:2]),
							.r(r[3:2])
							);
	end
	else begin: recursive_case
		wire	[Treesize * 2 - 1:0]	r_temp;
		//reg   [Treesize * 2 - 1:0]	r_temp_temp;
		
		first_half_half_half #(.Treesize(Treesize / 2))
		recursion_lsbh(.q(q[Treesize - 1:0]),
							.r(r_temp[Treesize - 1:0])
							);
							
		first_half_half_half #(.Treesize(Treesize / 2))
		recursion_msbh(.q(q[Treesize * 2 - 1:Treesize]),
							.r(r_temp[Treesize * 2 - 1:Treesize])
							);
		
		for(i = 0;i < Treesize * 2;i = i + 2) begin: parallel_stitch_up
			if(i != Treesize * 2 - 2) begin: parallel_stitch_up_pass
				assign r[i + 1:i] = r_temp[i + 1:i];
			end
			else begin: parallel_stitch_up_produce
				prefix_prefix_prefix f(.ql(r_temp[Treesize - 1:Treesize - 2]),
									.qh(r_temp[Treesize * 2 - 1:Treesize * 2 - 2]),
									.r(r[Treesize * 2 - 1:Treesize * 2 - 2])
									);
			end
		end
	end
	endgenerate
	
endmodule

//basic_logic
module prefix_prefix_prefix(ql,qh,r);
	
	input	[1:0]	ql;
	input	[1:0]	qh;
	output	[1:0]	r;
	
	assign r[0] = qh[0] & ql[0];
	assign r[1] = (qh[0] & ql[1]) | qh[1];
	
endmodule
