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

`define CLK_WAIT \
  wait(clk == 1'b1); \
  wait(clk == 1'b0);

`define READ_WAIT \
  wait(clk == 1'b0); \
  wait(clk == 1'b1);

`define ISSUE_ADD \
  `CLK_WAIT \
  `SET_WRITE(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | VCHIP_ALU_ADD), 2'b11, 1'b1);  



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

initial begin
  `CLEAR_ALL
  `CHIP_RESET

  // put state machine inputs in known state
  // initial state
`CLK_WAIT
maroon <= 1'b0;
gold   <= 1'b1;

// ----------------------------------
// 1) Write 19_08, read back
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h19_08, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h19_08);
`CLEAR_BUS


// ----------------------------------
// 1) Write 55_55, read back
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h55_55, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h55_55);
`CLEAR_BUS



// ----------------------------------
// 1) Write AA_AA, read back
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAA_AA, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hAA_AA);
`CLEAR_BUS






// ----------------------------------
// 2) Write FFFF, read back
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);
`CLEAR_BUS

// ----------------------------------
// 3) Low byte write
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h45_32, 2'b01, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_32);
`CLEAR_BUS

// ----------------------------------
// 4) High byte write
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5F_40, 2'b10, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h5F_32);
`CLEAR_BUS

// ----------------------------------
// 5) Full clear
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5F_40, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h00_00, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_00);
`CLEAR_BUS

// ----------------------------------
// 6) Write 5A5A
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5A_5A, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h5A_5A);
`CLEAR_BUS

// ----------------------------------
// 7) byte_en = 00 (no write)
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hDEAD, 2'b00, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h5A_5A);
`CLEAR_BUS

// ----------------------------------
// 8) cs = 0 (no write)
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFADA, 2'b11, 1'b0);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h5A_5A);
`CLEAR_BUS

// ----------------------------------
// 9) Valid write FADA
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFADA, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFADA);
`CLEAR_BUS



// ----------------------------------
// 8) cs = 0 (no read)
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFADA, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0);
`READ_WAIT
`CHECK_VAL(16'h00_00);
`CLEAR_BUS




// ===============================
// ALU REGISTER TESTS (COPY/PASTE)
// Uses required structure:
//   `CLK_WAIT  `SET_* (...)  `READ_WAIT (for reads)
// ===============================

// Issue ADD command (adjust encoding if spec differs)


// -------------------------------
// ALU_LEFT tests
// -------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h19_08, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h19_08);
`CLEAR_BUS

`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);
`CLEAR_BUS

// low byte only (expect high byte preserved = FF)
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h45_32, 2'b01, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_32);
`CLEAR_BUS

// high byte only (expect low byte preserved = 32)
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5F_40, 2'b10, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h5F_32);
`CLEAR_BUS

// full clear
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h00_00, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_00);
`CLEAR_BUS

// byte_en = 00 => no write (should stay 0000)
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hDEAD, 2'b00, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_00);
`CLEAR_BUS

// cs = 0 => no write (should stay 0000)
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hBEEF, 2'b11, 1'b0);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_00);
`CLEAR_BUS


// -------------------------------
// ALU_RIGHT tests
// -------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h12_34, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h12_34);
`CLEAR_BUS

`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hAB_CD, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hAB_CD);
`CLEAR_BUS

// low byte only (expect high byte preserved = AB)
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h77_55, 2'b01, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hAB_55);
`CLEAR_BUS

// high byte only (expect low byte preserved = 55)
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h66_00, 2'b10, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h66_55);
`CLEAR_BUS

// full clear
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h00_00, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_00);
`CLEAR_BUS

// byte_en = 00 => no write (should stay 0000)
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hDEAD, 2'b00, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_00);
`CLEAR_BUS

// cs = 0 => no write (should stay 0000)
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hBEEF, 2'b11, 1'b0);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_00);
`CLEAR_BUS


// -------------------------------
// ALIASING: LEFT vs RIGHT
// -------------------------------
// Write distinct values; confirm both hold independently
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR,  16'h0A0B, 2'b11, 1'b1);
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0C0D, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0A0B);

`CLK_WAIT
`SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0C0D);
`CLEAR_BUS


// -------------------------------
// ALU_OUT tests (READ-ONLY) using ADD
// -------------------------------
// Set operands
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR,  16'h0011, 2'b11, 1'b1);
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0022, 2'b11, 1'b1);

// Compute OUT = LEFT + RIGHT
`CLK_WAIT

`ISSUE_ADD
`CLK_WAIT
`CLK_WAIT

// Read OUT
`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0033);
`CLEAR_BUS

// Change LEFT only, recompute, OUT should change, RIGHT unchanged
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR,  16'h0100, 2'b11, 1'b1);
`CLK_WAIT
`ISSUE_ADD
`CLK_WAIT
`CLK_WAIT


`CLK_WAIT
`SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0022);

`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0122);
`CLEAR_BUS

// Change RIGHT only, recompute, OUT should change, LEFT unchanged
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0005, 2'b11, 1'b1);
`CLK_WAIT
`ISSUE_ADD
`CLK_WAIT
`CLK_WAIT

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0100);

`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0105);
`CLEAR_BUS

// Read-only enforcement: attempt write to OUT should not change OUT
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_OUT_ADDR, 16'hBEEF, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0105);
`CLEAR_BUS



//=======================================================================




// write to base address
`CLK_WAIT
`SET_WRITE(7'h10, 16'h5555, 2'b11, 1'b1);

// write to alias (bit6 flipped)
`CLK_WAIT
`SET_WRITE(7'h50, 16'h0000, 2'b11, 1'b1);

// read original
`CLK_WAIT
`SET_READ(7'h10, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0000);   // should change if aliasing is correct






  #5 $finish;
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
