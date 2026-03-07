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











// ==================================================RESET===================



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
// ALU_OUT tests (READ-ONLY) - Reset State (commands ignored)
// -------------------------------
// Set operands
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR,  16'h0011, 2'b11, 1'b1);
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0022, 2'b11, 1'b1);

// No ADD issued - commands ignored in Reset state
`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0000);  // ADD ignored, Out stays 16'h0000
`CLEAR_BUS

// Change LEFT only, OUT should stay 16'h0000, RIGHT unchanged
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR,  16'h0100, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0022);

`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0000);  // ADD ignored, Out stays 16'h0000
`CLEAR_BUS

// Change RIGHT only, OUT should stay 16'h0000, LEFT unchanged
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0005, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0100);

`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0000);  // ADD ignored, Out stays 16'h0000
`CLEAR_BUS

// Read-only enforcement: attempt write to OUT should not change OUT
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_OUT_ADDR, 16'hBEEF, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0000);  // Still 16'h0000, write to Out ignored
`CLEAR_BUS



//=======================================================================




//aliasing type 2 6 bit address
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);

`CLK_WAIT
`SET_WRITE(7'h09, 16'h0000, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h5555);
`CLEAR_BUS
//=======================================================================










































// ==================================================END OF RESET=====================






























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




//aliasing type 2 6 bit address
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);

`CLK_WAIT
`SET_WRITE(7'h09, 16'h0000, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h5555);
`CLEAR_BUS
//=======================================================================












//=====================START OF ERROR STATE=========================


// ===============================================================
// ERROR STATE TESTS
// Precondition: Push to Error state via overflow
// ===============================================================
// Push to Error state
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR,  16'hFFFF, 2'b11, 1'b1);
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0001, 2'b11, 1'b1);
`CLK_WAIT
`ISSUE_ADD   // Overflow → Error state
`CLK_WAIT
`CLK_WAIT

// ----------------------------------
// Write 19_08 - DISABLED in Error state
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h19_08, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored, Led still holds 16'hFFFF
`CLEAR_BUS


// ----------------------------------
// 1) Write 55_55 - DISABLED in Error state
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h55_55, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS


// ----------------------------------
// 1) Write AA_AA - DISABLED in Error state
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAA_AA, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS


// ----------------------------------
// 2) Write FFFF - DISABLED in Error state
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Coincidentally same value but write still ignored
`CLEAR_BUS

// ----------------------------------
// 3) Low byte write - DISABLED in Error state
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h45_32, 2'b01, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

// ----------------------------------
// 4) High byte write - DISABLED in Error state
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5F_40, 2'b10, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

// ----------------------------------
// 5) Full clear - DISABLED in Error state
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
`CHECK_VAL(16'hFF_FF);  // Both writes ignored
`CLEAR_BUS

// ----------------------------------
// 6) Write 5A5A - DISABLED in Error state
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5A_5A, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

// ----------------------------------
// 7) byte_en = 00 (no write) - already disabled in Error state
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hDEAD, 2'b00, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

// ----------------------------------
// 8) cs = 0 (no write)
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFADA, 2'b11, 1'b0);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

// ----------------------------------
// 9) Valid write FADA - DISABLED in Error state
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFADA, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

// ----------------------------------
// 8) cs = 0 (no read)
// ----------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFADA, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0);
`READ_WAIT
`CHECK_VAL(16'h00_00);  // cs=0, no read driven
`CLEAR_BUS


// ===============================
// ALU REGISTER TESTS - ERROR STATE
// ===============================

// -------------------------------
// ALU_LEFT tests - writes disabled, reads enabled
// -------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h19_08, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF_FF, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored, same value by coincidence
`CLEAR_BUS

// low byte only - write disabled
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h45_32, 2'b01, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

// high byte only - write disabled
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5F_40, 2'b10, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

// full clear - write disabled
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h00_00, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

// byte_en = 00 => no write
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hDEAD, 2'b00, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS

// cs = 0 => no write
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hBEEF, 2'b11, 1'b0);
`CLK_WAIT
`SET_READ (VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Write ignored
`CLEAR_BUS


// -------------------------------
// ALU_RIGHT tests - writes disabled, reads enabled
// Right was 16'h0001 before overflow
// -------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h12_34, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_01);  // Write ignored, Right stays 16'h0001
`CLEAR_BUS

`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hAB_CD, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_01);  // Write ignored
`CLEAR_BUS

// low byte only - write disabled
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h77_55, 2'b01, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_01);  // Write ignored
`CLEAR_BUS

// high byte only - write disabled
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h66_00, 2'b10, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_01);  // Write ignored
`CLEAR_BUS

// full clear - write disabled
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h00_00, 2'b11, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_01);  // Write ignored
`CLEAR_BUS

// byte_en = 00 => no write
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hDEAD, 2'b00, 1'b1);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_01);  // Write ignored
`CLEAR_BUS

// cs = 0 => no write
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hBEEF, 2'b11, 1'b0);
`CLK_WAIT
`SET_READ (VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_01);  // Write ignored
`CLEAR_BUS


// -------------------------------
// ALIASING: LEFT vs RIGHT - reads still work
// -------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR,  16'h0A0B, 2'b11, 1'b1);  // Write ignored
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0C0D, 2'b11, 1'b1);  // Write ignored

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Still holds pre-error value

`CLK_WAIT
`SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_01);  // Still holds pre-error value
`CLEAR_BUS


// -------------------------------
// ALU_OUT tests - commands disabled in Error state
// -------------------------------
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR,  16'h0011, 2'b11, 1'b1);  // Write ignored
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0022, 2'b11, 1'b1);  // Write ignored

// No ADD - commands ignored in Error state
`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0000);  // Out holds last ALU result (overflow result is 0)
`CLEAR_BUS

`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR,  16'h0100, 2'b11, 1'b1);  // Write ignored

`CLK_WAIT
`SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h00_01);  // Unchanged

`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0000);  // Unchanged
`CLEAR_BUS

`CLK_WAIT
`SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0005, 2'b11, 1'b1);  // Write ignored

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Unchanged

`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0000);  // Unchanged
`CLEAR_BUS

// Read-only enforcement: write to OUT ignored
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_OUT_ADDR, 16'hBEEF, 2'b11, 1'b1);

`CLK_WAIT
`SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'h0000);  // Still 16'h0000
`CLEAR_BUS


//=======================================================================
// Aliasing type 2 - 6 bit address - writes disabled in Error state
`CLK_WAIT
`SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1);  // Write ignored

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);

`CLK_WAIT
`SET_WRITE(7'h09, 16'h0000, 2'b11, 1'b1);  // Write ignored

`CLK_WAIT
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1);
`READ_WAIT
`CHECK_VAL(16'hFF_FF);  // Still holds pre-error value
`CLEAR_BUS
//=======================================================================




















//=========================END OF ERROR STATE====================================














//===================start of export control========================




















//================end of export control================================














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