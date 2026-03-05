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

//replaced all the @negedge clk with wait(clk == 1'b0);

//=================================================================================
   //writing 0xff_ff to alu left

   // Transition FSM from RESET -> NORM (requires !maroon & gold)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   maroon <= 1'b0;
   gold   <= 1'b1;
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // let the state transition register

   // Write 0xFFFF to ALU LEFT (chip_select=1, byte_en=2'b11 for both bytes)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for write to latch

   // Read ALU LEFT back
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for read data to appear
   `CHECK_VAL(16'hFF_FF)

   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `CLEAR_BUS
//========================================================================================

//=================================================================================
   //writing 0x5a_5a to alu left

   // Transition FSM from RESET -> NORM (requires !maroon & gold)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   maroon <= 1'b0;
   gold   <= 1'b1;
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // let the state transition register

   // Write 0x5A5A to ALU LEFT (chip_select=1, byte_en=2'b11 for both bytes)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5A_5A, 2'b11, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for write to latch

   // Read ALU LEFT back
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for read data to appear
   `CHECK_VAL(16'h5A_5A)

   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `CLEAR_BUS
//========================================================================================

//=================================================================================
   //writing 0xaa_aa to alu left

   // Transition FSM from RESET -> NORM (requires !maroon & gold)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   maroon <= 1'b0;
   gold   <= 1'b1;
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // let the state transition register

   // Write 0xAAAA to ALU LEFT (chip_select=1, byte_en=2'b11 for both bytes)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAA_AA, 2'b11, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for write to latch

   // Read ALU LEFT back
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for read data to appear
   `CHECK_VAL(16'hAA_AA)

   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `CLEAR_BUS
//========================================================================================

//=================================================================================
   //writing 0x55_55 to alu left

   // Transition FSM from RESET -> NORM (requires !maroon & gold)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   maroon <= 1'b0;
   gold   <= 1'b1;
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // let the state transition register

   // Write 0x5555 to ALU LEFT (chip_select=1, byte_en=2'b11 for both bytes)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h55_55, 2'b11, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for write to latch

   // Read ALU LEFT back
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for read data to appear
   `CHECK_VAL(16'h55_55)

   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `CLEAR_BUS
//========================================================================================


//=================================================================================
   //writing 0x55_20 to alu left

   // Transition FSM from RESET -> NORM (requires !maroon & gold)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   maroon <= 1'b0;
   gold   <= 1'b1;
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // let the state transition register

   // Write 0x5520 to ALU LEFT (chip_select=1, byte_en=2'b11 for both bytes)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h55_20, 2'b11, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for write to latch

   // Read ALU LEFT back
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for read data to appear
   `CHECK_VAL(16'h55_20)

   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `CLEAR_BUS
//========================================================================================


//=================================================================================
   //writing 0x20_20 to alu left

   // Transition FSM from RESET -> NORM (requires !maroon & gold)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   maroon <= 1'b0;
   gold   <= 1'b1;
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // let the state transition register

   // Write 0x2020 to ALU LEFT (chip_select=1, byte_en=2'b11 for both bytes)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h20_20, 2'b11, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for write to latch

   // Read ALU LEFT back
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for read data to appear
   `CHECK_VAL(16'h20_20)

   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `CLEAR_BUS
//========================================================================================

//=================================================================================
   //writing 0x00_00 to alu left
   // First load a non-zero value, then overwrite with 0x00_00 and read back
   // This proves the 0x00_00 write actually took effect (not just a cleared bus)

   // Transition FSM (requires !maroon & gold)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   maroon <= 1'b0;
   gold   <= 1'b1;
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // let the state transition register

   // First write a known non-zero value (0xBEEF) to ALU LEFT
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hBE_EF, 2'b11, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for write to latch

   // Verify the non-zero value was written
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for read data to appear
   `CHECK_VAL(16'hBE_EF)

   // Now overwrite with 0x00_00
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h00_00, 2'b11, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for write to latch

   // Read ALU LEFT back — should be 0x00_00 (not the old 0xBEEF)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1)
   wait( clk == 1'b1 );
   wait( clk == 1'b0 );  // wait for read data to appear
   `CHECK_VAL(16'h00_00)

   wait( clk == 1'b1 );
   wait( clk == 1'b0 );
   `CLEAR_BUS
//========================================================================================


//=================================================================================
   // Random value testing using $urandom
   // Generate a seed, then use it to produce random 0xyy_yy values for ALU LEFT
   begin : random_test_block
      integer seed;
      integer i;
      logic [7:0]  rand_byte;
      logic [15:0] rand_val;

      // Generate a random seed
      seed = $urandom;
      rand_byte = $urandom(seed) & 8'hFF;
      $display("Random seed = %0d", seed);

      // Run 10 random write/read tests
      for (i = 0; i < 10; i = i + 1) begin
         // Generate a random 8-bit value from the seed
         rand_byte = $urandom();
         // Form 0xyy_yy pattern (same byte in both halves)
         rand_val = {rand_byte, rand_byte};
         $display("Random test %0d: writing 0x%h to ALU LEFT", i, rand_val);

         // Transition FSM (requires !maroon & gold)
         wait( clk == 1'b1 );
         wait( clk == 1'b0 );
         maroon <= 1'b0;
         gold   <= 1'b1;
         wait( clk == 1'b1 );
         wait( clk == 1'b0 );  // let the state transition register

         // Write random value to ALU LEFT
         wait( clk == 1'b1 );
         wait( clk == 1'b0 );
         `SET_WRITE(VCHIP_ALU_LEFT_ADDR, rand_val, 2'b11, 1)
         wait( clk == 1'b1 );
         wait( clk == 1'b0 );  // wait for write to latch

         // Read ALU LEFT back and verify
         wait( clk == 1'b1 );
         wait( clk == 1'b0 );
         `SET_READ(VCHIP_ALU_LEFT_ADDR, 1)
         wait( clk == 1'b1 );
         wait( clk == 1'b0 );  // wait for read data to appear
         `CHECK_VAL(rand_val)

         wait( clk == 1'b1 );
         wait( clk == 1'b0 );
         `CLEAR_BUS
      end
   end
//========================================================================================


   #5 $finish;
end // initial begin


initial begin :wave_gen
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
