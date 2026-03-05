`timescale 1ns/1ps

`define SET_WRITE(addr,val,bytes,cs)   \
   rw_ <= 1'b0;                     \
   chip_select <= cs;               \
   byte_en <= bytes;                \
   address <= addr;                 \
   data_in <= val; 

`define SET_READ(addr,cs)           \
   rw_ <= 1'b1;                     \
   chip_select <= cs;               \
   byte_en <= 2'b00;                \
   address <= addr;                 \
   data_in <= 16'h0;

`define CLEAR_BUS                   \
   chip_select    <= 1'b0;          \
   address        <= 7'h0;          \
   byte_en        <= 2'h0;          \
   rw_            <= 1'b1;          \
   data_in        <= 16'h0; 

`define CLEAR_ALL                   \
   export_disable <= 1'b0;          \
   maroon         <= 1'b0;          \
   gold           <= 1'b0;          \
   `CLEAR_BUS

`define CHECK_VAL(val)              \
   if ( data_out != val )           \
       $display("bad read, got %h but expected %h at %t",data_out,val,$time());

`define CHECK_RW(addr,wval,rval,bytes,cs)    \
   `WRITE_REG(addr,wval,bytes,cs)            \
   `READ_REG(addr,rval,cs)

`define CHIP_RESET                  \
   wait( clk == 1'b0 );             \
   rst_b <= 1'b0;                   \
   wait( clk == 1'b1 );             \
   rst_b <= 1'b1;

module top_verichip ();

logic clk;                       // system clock
logic rst_b;                     // chip reset
logic export_disable;            // disable features
logic interrupt_1;               // first interrupt
logic interrupt_2;               // second interrupt

logic maroon;                    // maroon state machine input
logic gold;                      // gold state machine input

logic chip_select;               // target of r/w
logic [6:0] address;             // address bus
logic [1:0] byte_en;             // write byte enables
logic       rw_;                 // read/write
logic [15:0] data_in;            // input data bus

logic [15:0] data_out;           // output data bus

localparam VCHIP_VER_ADDR       = 7'h00;
localparam VCHIP_STA_ADDR       = 7'h04;
localparam VCHIP_CMD_ADDR       = 7'h08;
localparam VCHIP_CON_ADDR       = 7'h0C;
localparam VCHIP_ALU_LEFT_ADDR  = 7'h10;
localparam VCHIP_ALU_RIGHT_ADDR = 7'h14;
localparam VCHIP_ALU_OUT_ADDR   = 7'h18;

localparam VCHIP_ALU_VALID = 16'h8000;
localparam VCHIP_ALU_ADD   = 16'h0001;
localparam VCHIP_ALU_SUB   = 16'h0002;
localparam VCHIP_ALU_MVL   = 16'h0003;
localparam VCHIP_ALU_MVR   = 16'h0004;
localparam VCHIP_ALU_SWA   = 16'h0005;
localparam VCHIP_ALU_SHL   = 16'h0006;
localparam VCHIP_ALU_SHR   = 16'h0007;


//loop params start

int i;// loop counter will be used in while
int seed; //will be used to generate random numbers


//loop params ends

initial
begin
   clk <= 1'b0;
   while ( 1 )
   begin
      #5 clk <= 1'b1;
      #5 clk <= 1'b0;
   end
end

initial
begin
   `CLEAR_ALL
   `CHIP_RESET

  //reset is done
  //bring the chip to Normal mode -> M'G
  maroon <= 1'b0;
  gold <= 1'b1;
 //chip now in normal mode
 wait(clk == 1'b1);
 wait(clk == 1'b0);
 //wait for the clock to take the reg
 `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hF0_F0, 2'b11, 1'b1)
 wait(clk == 1'b1);
 wait(clk == 1'b0);
 // Read back and verify
 `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
 wait(clk == 1'b1);
 wait(clk == 1'b0);
 `CHECK_VAL(16'hF0_F0)

 wait(clk == 1'b1);
 wait(clk == 1'b0);
 `CLEAR_BUS

 //=====================--ZERO CHECK--==================================================

  wait(clk == 1'b1);
 wait(clk == 1'b0);
 //wait for the clock to take the reg
 `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1)
 wait(clk == 1'b1);
 wait(clk == 1'b0);
 // Read back and verify
 `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
 wait(clk == 1'b1);
 wait(clk == 1'b0);
 `CHECK_VAL(16'hFF_FF)

 wait(clk == 1'b1);
 wait(clk == 1'b0);
 //`CLEAR_BUS
 `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h00_00, 2'b11, 1'b1)
 wait(clk == 1'b1);
 wait(clk == 1'b0);
 // Read back and verify
 `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
 wait(clk == 1'b1);
 wait(clk == 1'b0);
 `CHECK_VAL(16'h00_00)

 wait(clk == 1'b1);
 wait(clk == 1'b0);
 `CLEAR_BUS

 //=====================================================================




   #5 $finish;
end // initial begin

//get the wave gen

initial begin : wave_gen
   $dumpfile("wave.vcd");
   $dumpvars(0,top_verichip);
end

verichip verichip (.clk           ( clk            ),    // system clock
                   .rst_b         ( rst_b          ),    // chip reset
                   .export_disable( export_disable ),    // disable features
                   .interrupt_1   ( interrupt_1    ),    // first interrupt
                   .interrupt_2   ( interrupt_2    ),    // second interrupt
 
                   .maroon        ( maroon         ),    // maroon state machine input
                   .gold          ( gold           ),    // gold state machine input

                   .chip_select   ( chip_select    ),    // target of r/w
                   .address       ( address        ),    // address bus
                   .byte_en       ( byte_en        ),    // write byte enables
                   .rw_           ( rw_            ),    // read/write
                   .data_in       ( data_in        ),    // data bus

                   .data_out      ( data_out       ) );  // output data bus


endmodule
