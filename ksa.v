module ksa( CLOCK_50, KEY, SW, LEDR);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;


// state names here as you complete your design	

typedef enum {state_init, 
					state_fill,
					state_get_S_at_i,
					state_wait_S_at_i,
					state_get_j_and_S_at_j,
					state_wait_S_at_j,
					state_update_S_at_i,
					state_update_S_at_j,
					state_init_loop,
					state_get_S_at_i_2,
					state_wait_S_at_i_2,
					state_get_j_and_S_at_j_2,
					state_wait_S_at_j_2,
					state_update_S_at_i_2,
					state_update_S_at_j_2,
					state_get_f,
					state_wait_f,
					state_get_input_at_k,
					state_wait_input_at_k,
					state_update_output_at_k,
					state_update_k,
					state_update_Key,
					state_done} state_type;
state_type state;

// these are signals that connect to the memory

//parameters for the circuit
parameter Key_Length = 3;
parameter Message_Length = 32; 

//For s_memory
reg [7:0] address, data; 
reg [7:0] q;
reg wren;

//For message_rom
reg [4:0] address_m;
reg [7:0] q_m;

//For output_ram
reg [4:0] address_d;
reg [7:0] data_d, q_d;
reg wren_d;

//datapath regs and variables
reg [8:0] i, j;
reg [7:0] f, input_message;
reg [5:0] k;
reg [7:0] S_at_i, S_at_j; 
reg [7:0] temp_swap; //for swapping 



//The values for the secret key
reg [23:0] Key;
//these were for task 2
//assign Key[9:0] = SW;
//assign Key[23:10] = 1'b0;

//To indicate when the process has completed
assign LEDR = Key[21:12];

// include S memory structurally
s_memory S( .address(address), 
				.clock(CLOCK_50), 
				.data(data), 
				.wren(wren),
				.q(q));

//include the message rom
message_rom Message( .address(address_m),
							.clock(CLOCK_50),
							.q(q_m));
							
//include the decrypted output result ram
output_ram Result(.address(address_d),
						.clock(CLOCK_50),
						.data(data_d),
						.wren(wren_d),
						.q(q_d));
				
//Implicite datapath
always_ff @(posedge CLOCK_50) begin	
	case(state)
	
		state_init : begin 
			
			//Data initialization
			i   = 9'b000000000;	
			
			//Memory control
			wren  <= 1'b1;
			
			//Next state logic
			state <= state_fill; //Set the next state to be the fill state
		
		end //End state_init
		
		state_fill : begin 
					
			//Memory Control
			wren    <= 1'b1;
			data    <= i[7:0];
			address <= i[7:0];
			
			//Data update
			i = i + 1'b1;
			
			//Next state logic
			state <= (i == 256) ? state_get_S_at_i : state_fill; //if i has reached 256, S is full
			
			//Next State Setup
			if(i == 256) begin		
				i = 9'b000000000;
				j = 9'b000000000;			
			end//End if
			
		end //End state_fill
		
		state_get_S_at_i: begin
		
			//Here we request the value in memory at location i
		
			//Memory Control
			wren    <= 1'b0;
			address <= i[7:0];
			
			//Next state logic
			state <= state_wait_S_at_i;
			
		end //End get_S_at_i
		
		state_wait_S_at_i : begin
			
			//Here we just wait a cycle for the data from the S memory
			//to be loaded into S_at_i
			
			//Next state logic
			state <= state_get_j_and_S_at_j;
			
		end //End state_wait_S_at_i
		
		state_get_j_and_S_at_j : begin
		
			//Data update
			S_at_i = q; //Set S_at_i to be the result of requesting the memory at location i
			//j 		 = (j + S_at_i + Key[i % Key_Length]) % 9'b10000000; //Update the value of j according to the algorithm
			
			case(i%Key_Length) 
				0: j = (j + S_at_i + Key[23:16])%9'b100000000;
				1: j = (j + S_at_i + Key[15:8]) %9'b100000000;
				2: j = (j + S_at_i + Key[7:0])  %9'b100000000;
			endcase
			
			//Memory Control
			temp_swap = S_at_i;
			address  <= j[7:0];
			
			//Next state logic
			state <= state_wait_S_at_j;
		
		end //End state_get_j_and_S_at_j
		
		state_wait_S_at_j : begin
		
			//Next state logic
			state <= state_update_S_at_i;
		
		end //End state_wait_S_at_j
		
		state_update_S_at_i :  begin
		
			//Data update
			S_at_j = q; //Set S_at_i to be the result of requesting the memory at location i
			
			//Memory Control
			wren    <= 1'b1;   //prepare the memory to be written to for swapping
			address <= i[7:0];      //set the location to be written to to i
			data    <= S_at_j; //set the value to write to S_at_j (i.e. overwrite S_at_i with S_at_j)
			
			//Next state logic
			state <= state_update_S_at_j;
		
		end //End state_update_S_at_i;
		
		state_update_S_at_j : begin
			
			//Memory control
			wren    <= 1'b1;
			address <= j[7:0];  
			data    <= temp_swap; //replace S_at_j with the old value of S_at_i
			
			//Data update
			i = i + 1'b1;
			
			//Next state logic
			state <= (i < 256) ? state_get_S_at_i : state_init_loop;
		
		end //End state_update_S_at_j
		
		state_init_loop : begin 
		
			//Data Update
			//reset all looping iteration variables to 0
			i = 9'b000000000;
			j = 9'b000000000;
			k = 6'b000000;
			
			//Next state logic
			state <= state_get_S_at_i_2;
		end //End state_init_loop	
		
		state_get_S_at_i_2 : begin
		
			//Data Update
			i = (i + 1'b1) % 9'b100000000;
			
			//Memory Control
			wren    <= 1'b0;
			address <= i[7:0];
			
			//Next state logic
			state <= state_wait_S_at_i_2;
		
		end //End _state_get_S_at_i_2
		
		state_wait_S_at_i_2 : begin
		
			//Next state logic
			state <= state_get_j_and_S_at_j_2;
			
		end //End state_wait_S_at_2
		
		state_get_j_and_S_at_j_2 : begin
		
			//Data update
			S_at_i 		= q;
			j      		= (S_at_i + j) % 9'b100000000;
			temp_swap   = S_at_i; //to be used for swapping
			
			//Memory Control
			address <= j[7:0];
		   
			//Next state logic
			state <= state_wait_S_at_j_2;
			
		end //End state state_get_j_and_S_at_j_2
		
		state_wait_S_at_j_2 : begin
		
			//Next state logic 
			state <= state_update_S_at_i_2;
		
		end //End state_wait_S_at_i_2
		
		state_update_S_at_i_2 : begin
		
			//Date update
			S_at_j = q; 
			
			//Memory Control
			wren    <= 1'b1; //enable writing for swapping
			address <= i[7:0];
			data    <= S_at_j[7:0]; //begin swapping
			
			//Next state logic
			state <= state_update_S_at_j_2;
		
		end //End state_update_S_at_i_2
		
		state_update_S_at_j_2 : begin
			
			//Memory Control
			wren    <= 1'b1; //ensure that writing is still enabled for swapping
			address <= j[7:0];
			data    <= temp_swap[7:0]; //complete the swapping
			
			//Next state logic
			state <= state_get_f;
			
		end //End state_update_S_at_j_2
		
		state_get_f : begin
			
			//Memory Control
			wren    <= 1'b0; //no writing needed to S anymore
			address <= (S_at_j + temp_swap) % 9'b100000000;
			
			//Next state logic
			state <= state_wait_f;
			
		end
		
		state_wait_f : begin
			
			//Next state logic
			state <= state_get_input_at_k;
			
		end //End state_wait_f
		
		state_get_input_at_k : begin
		
			//Update data
			f = q; //get the value of S_at(S_at_i + S_at_j % 256)
			
			//Memory Control
			address_m <= k[4:0]; //get the input at k
			
			//Next state logic
			state <= state_wait_input_at_k;
		
		end //End state_get_input_at_k
		
		state_wait_input_at_k : begin
		 
			//Next state logic
			state <= state_update_output_at_k;
		 
		end //End state_wait_input_at_k
		
		state_update_output_at_k : begin
			
			//Data update
			input_message = q_m;
		
			//Memory Control
			wren_d    <= 1'b1;
			address_d <= k[4:0];
			data_d    <= input_message ^ f;
			
			//Next state logic	
			state <= (((8'b01100001 > (f ^ input_message)) || ((f ^ input_message) > 8'b01111010)) && ((f^input_message) != 32)) ? 
							state_update_Key : state_update_k;
			
		end //End state_update_output_at_k
		
		state_update_k: begin
			
			//Update data
			k = k + 1'b1;
			
			if(k >= Message_Length)
				Key = 24'b001000000000000000000000;

			//Memory Control
			wren_d <= 1'b0;
			
			//Next state logic
			state <= (k < Message_Length) ? state_get_S_at_i_2 : state_done;

		end //End state_update_k
		
		state_update_Key: begin
			
			//Data Update
			Key = Key + 1'b1;
			
			if(Key >= 24'b010000000000000000000000)
				Key = 24'b000100000000000000000000;
			
			//Memory Control
			wren_d <= 1'b0;
			
			//Next state logic
			state <= (Key < 24'b010000000000000000000000) ? state_init : state_done;

		end //End state_update_Key
		
		state_done : begin 
			
			//Next state logic	
			state <= state_done; //stay here forever after completion
		
		end //End State_done
		
		default : begin 
			
			//Data update
			i 			  = 9'b000000000;
			Key = 24'b000000000000000000000000;
			
			//Next state logic
			state <= state_init;
			
		end //End Default
		
	endcase//End main state case statement
end //End Always_ff

endmodule



