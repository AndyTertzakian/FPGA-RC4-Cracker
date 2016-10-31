module ksa( CLOCK_50, KEY, SW, LEDR);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;


// state names here as you complete your design	

typedef enum {state_init, state_fill, state_done} state_type;
state_type state;

// these are signals that connect to the memory

//For s_memory
reg [7:0] address, data;
reg [7:0] q;
reg wren;

//datapath regs
reg [7:0] i;
reg sel_i, done;

// include S memory structurally
s_memory u0(address, clk, data, wren, q);

//Implicite datapath
always_ff @(posedge CLOCK_50) begin
	case(state)
	
		state_init : begin 
			
			//Datapath control
			sel_i <= 1'b1;	
			done  <= 1'b0;
			
			//Memory control
			wren  <= 1'b0;
			
			state <= state_fill; //Set the next state to be the fill state
		
		end //End state_init
		
		state_fill : begin 
				
				done <= ()
			
		end //End state_fill
		
		state_done : begin 
				
			state <= state_done;
		
		end //End State_done
		
		default : begin 
		
			state <= state_done;
			
		end //End Default
		
	endcase
end

endmodule



