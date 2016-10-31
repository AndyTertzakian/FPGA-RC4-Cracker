module ksa( CLOCK_50, KEY, SW, LEDR);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;


// state names here as you complete your design	

typedef enum {state_init, state_fill, state_done} state_type;
state_type state;

// these are signals that connect to the memory

reg [7:0] address, data, q;
reg wren;

// include S memory structurally

oneport u0(address, clk, data, wren, q);

// Write your code here.  As described in the lectures, this code will drive
// the address, data, and wren signals to fill the memory with the values 0..255.

// You will likely be writing a state machine.  Ensure that after the memory is
// filled, you enter a DONE state which does nothing but loop back to itself.



endmodule



