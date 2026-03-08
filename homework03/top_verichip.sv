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

   // Test ALU Left Register in Reset State (Write and Read) keeping byte enable and chip select on
   // Attempt to write 0000 to ALU Left
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
 //Attempt to read 0000 from ALU left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
// Make sure 0000 is read back from ALU left
   `CHECK_VAL(16'h0000)
    //Similarly, apply this method for other test inputs in the same state.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'hFFFF)

   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'hAAAA)

   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h5555)
   #10;
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
    
 #10;
   `CHECK_VAL(16'h0000)

   // Test ALU Left Register in Normal State (Write and Read) keeping byte enable and chip select on
   `CLEAR_ALL
   `CHIP_RESET
    maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   #10; //Attempt to write 0000 to ALU Left
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10; //Attempt to read 0000 from ALU left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;  // Make sure 0000 is read back from ALU left
   `CHECK_VAL(16'h0000)
    // Similarly, apply this method for other test inputs within the same state.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'hFFFF)

   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'hAAAA)

   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h5555)

   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0000)

   // Test ALU Left Register in Error State (Write and Read) keeping byte enable and chip select on
   `CLEAR_ALL
   `CHIP_RESET
    maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
    //Attempt to write 0100 to Configuration register
   `SET_WRITE(VCHIP_CON_ADDR,16'h0100,2'b11,1'b1)
   #10; //Attempt to write 8008 to command register - To transition from Normal state to Error state
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008,2'b11,1'b1)
   #10; //Attempt to write 0000 to ALU_Left
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10; // Make sure 0000 is read back from ALU_Left
   `CHECK_VAL(16'h0000)
    // Similarly, apply this method for other test inputs within the same state.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0000)

   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;


`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0000)

   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0000)

   // Test ALU Left Register in Export Violation State (Write and Read) keeping byte enable and chip select on
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   export_disable <= 1'b1; //This signal disables certain export-required commands. Invalid commands will transition the state machine to the Export Violation state.
   //Attempt to write 0200 to Configuration register
   `SET_WRITE(VCHIP_CON_ADDR,16'h0200,2'b11,1'b1)
   #10;//Attempt to write 800A to command register - To transition from Normal state to Export violation state
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800A,2'b11,1'b1)
   #10;//Attempt to write 0000 to ALU_Left
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10; // Make sure 0000 is read back from ALU_Left
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same state.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0000)

   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0000)

   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0000)


   // Test Byte Enable Combinations with chip select on state
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   //Attempt to write 0000 to ALU Left when byte enable is 00
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b00, 1'b1)
   #10;//Attempt to read 0000 from ALU left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU left
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b00 ,1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0000)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b00,1'b1)
    
 #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0000)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b00, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0000)


   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   //Attempt to write 0000 to ALU Left when byte enable is 01
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b01, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU_Left
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b01, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h00AA)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b01, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h0055)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b01, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h00FF)


   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1;// Maroon = 0 and Gold = 1, for transitioning to Normal State.
   //Attempt to write 0000 to ALU Left when byte enable is 10
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b10, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU_Left
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b10, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'hAA00)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b10, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h5500)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b10, 1'b1)
   #10;

`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'hFF00)


   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   //Attempt to write 0000 to ALU Left when byte enable is 11
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU_Left
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'hAAAA)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h5555)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'hFFFF)



   // Test Aliasing on different operations
  //Check for Aliasing with Chip Select
   `CHIP_RESET
   `CLEAR_ALL
   //Attempt to write 0000 to ALU_Left
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0)
   #10;// Make sure 0000 is read back from ALU left
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0)
   #10;
   `CHECK_VAL(16'h0000)

   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0)
   #10;
   `CHECK_VAL(16'h0000)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0)
   #10;
   `CHECK_VAL(16'h0000)

   //Check for Aliasing without Chip Select
   // Clear all for a spotless interface
   `CLEAR_ALL
   //Attempt to write AAAA to ALU_Left when chip select is off
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b0)
   #10; //Attempt to read AAAA from ALU_Left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure FFFF is read back from ALU_Left
   `CHECK_VAL(16'hFFFF)
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b0)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'hFFFF)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b0)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'hFFFF)
   //Attempt to write 5555 to ALU Left when chip select is on
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;//Attempt to read 5555 from ALU left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 5555 is read back from ALU left
   `CHECK_VAL(16'h5555)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b0)
   #10;
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   `CHECK_VAL(16'h5555)

   //Write to Correct ALU LEFT Register
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   //Attempt to write AAAA to 7'h50 address
   `SET_WRITE(7'h50, 16'hAAAA, 2'b11, 1'b1)
   #10;//Attempt to write FFFF from ALU left
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;//Attempt to read AAAA from 7'h50
   `SET_READ(7'h50, 1'b1)
   #10;// Make sure 0000 is read back from 7'h50 (unused address returns 0)
   `CHECK_VAL(16'h0000)   // corrected from 16'hAAAA

//Write to Aliased Address (7'h50)
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
  //Attempt to write AAAA to ALU_Left
  `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10; //Attempt to write 5555 to 7'h50 address
   `SET_WRITE(7'h50, 16'h5555, 2'b11, 1'b1)
   #10; //Attempt to read AAAA from ALU_Left
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU left (write to unused address may clear register)
   `CHECK_VAL(16'h0000)   // corrected from 16'hAAAA

   #5 $finish;
end // initial begin

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