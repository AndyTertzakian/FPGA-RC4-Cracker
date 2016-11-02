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
					state_done} state_type;
state_type state;

// these are signals that connect to the memory

//For s_memory
reg [7:0] address, data; 
reg [7:0] q;
reg wren;

//datapath regs
reg [8:0] i, j;
reg [7:0] S_at_i, S_at_j; 
reg [7:0] temp_swap; //for swapping 

//The values for the secret key
parameter Key_Length = 3;
// wire [7:0] Key [2:0];
// assign Key[2] = SW[7:0];
// assign Key[1] = {6'b0000000, SW[9:8]};
// assign Key[0] = 8'b00000000;
wire [23:0] Key;
assign Key[23:10] = 1'b0;
assign Key[9:0] = SW;

//To indicate when the process has completed
assign LEDR[7] = (state == state_done);

// include S memory structurally
s_memory u0(address, CLOCK_50, data, wren, q);

//Implicite datapath
always_ff @(posedge CLOCK_50) begin
	case(state)
	
		state_init : begin 
			
			//Data initialization
			i = 9'b000000000;	
			
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
			state <= (i < 256) ? state_get_S_at_i : state_done;
		
		end //End state_update_S_at_j
		
		state_done : begin 
			
			//Memory control
			wren <= 1'b0; //No more writing to memory is required after finishing
				
			//Next state logic	
			state <= state_done; //stay here forever after completion
		
		end //End State_done
		
		default : begin 
		
			i = 9'b000000000;
			state <= state_init;
			
		end //End Default
		
	endcase//End main state case statement
end //End Always_ff

endmodule



