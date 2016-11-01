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
					state_wait_S_at_sj,
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
reg [7:0] i, S_at_i;
reg [7:0] j, S_at_j;
wire [23:0] Key [2:0];
assign Key[0] = SW[7:0];
assign Key[1] = {6'b0000000, SW[9:8]};
assign Key[2] = 8'b00000000;

// include S memory structurally
s_memory u0(address, CLOCK_50, data, wren, q);

//Implicite datapath
always_ff @(posedge CLOCK_50) begin
	case(state)
	
		state_init : begin 
			
			//Date initialization
			i = 8'b0;	
			
			//Memory control
			wren  <= 1'b1;
			
			//Next state logic
			state <= state_fill; //Set the next state to be the fill state
		
		end //End state_init
		
		state_fill : begin 
				
			//Data update
			i = i + 1'b1;
			
			
			//Memory Control
			wren    <= 1'b1;
			data    <= i[7:0];
			address <= i[7:0];
			
			//Next state logic
			state <= (i == 256) ? state_ : state_fill; //if i has reached 256, S is full
			
			//Next State Setup
			if(i == 256) begin		
				i = 8'b00000000;
				j = 8'b00000000;			
			end//End if
			
		end //End state_fill
		
		
		
		state_done : begin 
				
			state <= state_done;
		
		end //End State_done
		
		default : begin 
		
			state <= state_init;
			
		end //End Default
		
	endcase//End main state case statement
end //End Always_ff

endmodule



