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


// loop variable for walking-ones / walking-zeros tests
int i;

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

   // ================================================================
   // TC-LED-001  Reset Value Verification
   // Precondition: rst_b just deasserted (chip in Reset state)
   // Expected: Led = 16'h0000
   // ================================================================
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0000)
   $display("TC-LED-001: Reset Value Verification");
@(negedge clk)
   `CLEAR_BUS

   // ── Transition chip to Normal state ──
@(negedge clk)
   maroon <= 1'b0;
@(negedge clk)
   gold <= 1'b1;
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-002  Write All Zeros
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0000)
   $display("TC-LED-002: Write All Zeros");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-003  Write All Ones
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hFFFF)
   $display("TC-LED-003: Write All Ones");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-004  Write Walking Ones
   // ================================================================
   for (i = 0; i < 16; i = i + 1) begin
   @(negedge clk)
      `SET_WRITE(VCHIP_ALU_LEFT_ADDR, (16'h0001 << i), 2'b11, 1'b1)
   @(negedge clk)
      `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
      `CHECK_VAL((16'h0001 << i))
   end
   $display("TC-LED-004: Write Walking Ones");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-005  Write Walking Zeros
   // ================================================================
   for (i = 0; i < 16; i = i + 1) begin
   @(negedge clk)
      `SET_WRITE(VCHIP_ALU_LEFT_ADDR, ~(16'h0001 << i), 2'b11, 1'b1)
   @(negedge clk)
      `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
      `CHECK_VAL(~(16'h0001 << i))
   end
   $display("TC-LED-005: Write Walking Zeros");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-006  Write/Read Alternating Pattern A (0xAAAA)
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hAAAA)
   $display("TC-LED-006: Alternating Pattern A");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-007  Write/Read Alternating Pattern B (0x5555)
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h5555)
   $display("TC-LED-007: Alternating Pattern B");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-008  Write Mid-range Value (0x1234)
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h1234, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h1234)
   $display("TC-LED-008: Write Mid-range Value");
   // NOTE: Led = 16'h1234 after this test (needed for TC-LED-009)

   // ================================================================
   // TC-LED-009  No Access When chip_select=0
   // Precondition: Led = 16'h1234 from TC-LED-008
   // Write 16'hBEEF with cs=0 → Led unchanged
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hBEEF, 2'b11, 1'b0)   // cs=0
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)                      // cs=1 to read
   `CHECK_VAL(16'h1234)
   $display("TC-LED-009: No Access When chip_select=0");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-010  Read Returns 0 When chip_select=0
   // ================================================================
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0)                      // cs=0
   `CHECK_VAL(16'h0000)
   $display("TC-LED-010: Read Returns 0 When chip_select=0");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-011  Correct Address Decode 7'h10
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hDEAD, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hDEAD)
   $display("TC-LED-011: Correct Address Decode 7'h10");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-012  Address Alias Check (bit6 ignored) — write to 7'h50
   // 7'h50 = 7'b1010000  (bit6=1, lower 6 bits = 6'h10)
   // ================================================================
@(negedge clk)
   `SET_WRITE(7'h50, 16'hBEEF, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hBEEF)
   $display("TC-LED-012: Address Alias Check (bit6 ignored)");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-013  No Write to Adjacent Address (Right register)
   // Precondition: Led=16'hAAAA, Right=16'h0000
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h1234, 2'b11, 1'b1)  // write Right
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)                      // read Led
   `CHECK_VAL(16'hAAAA)
   $display("TC-LED-013: No Write to Adjacent Address (Right)");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-014  No Write to Command Register Affects Led
   // Precondition: Led=16'hCCCC
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hCCCC, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)     // write to CMD
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)                   // read Led
   `CHECK_VAL(16'hCCCC)
   $display("TC-LED-014: No Write to Command Register Affects Led");
@(negedge clk)
   `CLEAR_BUS

   // ── Need to recover from possible error state after bad cmd ──
@(negedge clk)
   maroon <= 1'b1;
   gold   <= 1'b0;
@(negedge clk)
   maroon <= 1'b0;
   gold   <= 1'b1;
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-015  Byte Enable Low Byte Only (byte_en=2'b01)
   // Precondition: Led = 16'h0000
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)   // clear Led
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFF12, 2'b01, 1'b1)   // low byte only
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0012)  // Led[7:0]=12, Led[15:8]=00
   $display("TC-LED-015: Byte Enable Low Byte Only");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-016  Byte Enable High Byte Only (byte_en=2'b10)
   // Precondition: Led = 16'h0000
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)   // clear Led
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAB00, 2'b10, 1'b1)   // high byte only
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hAB00)  // Led[15:8]=AB, Led[7:0]=00
   $display("TC-LED-016: Byte Enable High Byte Only");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-017  Byte Enable Both Bytes (byte_en=2'b11)
   // Precondition: Led = 16'h0000
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)   // clear Led
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hBEEF, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hBEEF)
   $display("TC-LED-017: Byte Enable Both Bytes");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-018  Byte Enable Neither (byte_en=2'b00)
   // Precondition: Led = 16'h1234
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h1234, 2'b11, 1'b1)   // set Led
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hDEAD, 2'b00, 1'b1)   // neither byte
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h1234)  // Led unchanged
   $display("TC-LED-018: Byte Enable Neither");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-019  Read in Reset State
   // Chip goes back to Reset state, Led should read 0000
   // ================================================================
   // Re-enter Reset state by toggling rst_b
   wait( clk == 1'b0 );
   rst_b <= 1'b0;
   wait( clk == 1'b1 );
   rst_b <= 1'b1;
   // Chip is now in RESET state (maroon/gold not yet toggled)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0000)
   $display("TC-LED-019: Read in Reset State");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-020  Write in Reset State
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5A5A, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h5A5A)
   $display("TC-LED-020: Write in Reset State");
@(negedge clk)
   `CLEAR_BUS

   // ── Transition back to Normal state ──
@(negedge clk)
   maroon <= 1'b0;
@(negedge clk)
   gold <= 1'b1;
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-021  Read in Normal State
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hABCD, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hABCD)
   $display("TC-LED-021: Read in Normal State");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-022  Write in Normal State
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hCAFE, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hCAFE)
   $display("TC-LED-022: Write in Normal State");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-023  Read in Error State
   // Trigger Error state via bad command (cmd > 7)
   // Precondition: Led has some value
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h1234, 2'b11, 1'b1)
@(negedge clk)
   // Write bad command: Valid=1, CMD=8 (> LAST_CMD=7) → bad_cmd → Error state
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h1234)  // read enabled in Error state, value preserved
   $display("TC-LED-023: Read in Error State");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-024  Write Disabled in Error State
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)   // attempt write
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h1234)  // Led unchanged, write disabled in Error
   $display("TC-LED-024: Write Disabled in Error State");
@(negedge clk)
   `CLEAR_BUS

   // ── Recover from Error state: maroon=1, gold=0 → Normal ──
@(negedge clk)
   maroon <= 1'b1;
   gold   <= 1'b0;
@(negedge clk)
   maroon <= 1'b0;
   gold   <= 1'b1;
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-025  Access Disabled in Export Violation State
   // Precondition: export_disable=1, trigger restricted cmd (cmd>2)
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h1234, 2'b11, 1'b1)
@(negedge clk)
   export_disable <= 1'b1;
@(negedge clk)
   // Valid=1, CMD=shift_left(6) > LAST_EXP_CMD(2) → Export Violation
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8006, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0000)  // Led zeroed out, access disabled (data_out=0 for non-STA)
   $display("TC-LED-025: Access Disabled in Export Violation State");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-026  Write Disabled in Export Violation State
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hDEAD, 2'b11, 1'b1)   // attempt write
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0000)  // write disabled, Led stays 0 (was reset entering EXP state)
   $display("TC-LED-026: Write Disabled in Export Violation State");
@(negedge clk)
   `CLEAR_BUS

   // ── Full reset to recover from Export Violation (stuck state) ──
@(negedge clk)
   export_disable <= 1'b0;
   wait( clk == 1'b0 );
   rst_b <= 1'b0;
   wait( clk == 1'b1 );
   rst_b <= 1'b1;
@(negedge clk)
   maroon <= 1'b0;
@(negedge clk)
   gold <= 1'b1;
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-027  Led Used as Left Operand in ADD
   // Led=0x0003, Right=0x0002 → Result=0x0005, Led unchanged
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0003, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0002, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)        // Valid=1, CMD=add
@(negedge clk)
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   `CHECK_VAL(16'h0005)
   $display("TC-LED-027a: ADD Result=0005");
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0003)  // Led unchanged
   $display("TC-LED-027b: Led unchanged after ADD");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-028  Led Used as Left Operand in SUB
   // Led=0x0010, Right=0x0003 → Result=0x000D, Led unchanged
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0010, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0003, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8002, 2'b11, 1'b1)        // Valid=1, CMD=sub
@(negedge clk)
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   `CHECK_VAL(16'h000D)
   $display("TC-LED-028a: SUB Result=000D");
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0010)  // Led unchanged
   $display("TC-LED-028b: Led unchanged after SUB");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-029  Move Out to Led (CMD=3)
   // Precondition: Result = some value (use ADD to set Result=0x00FF)
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h00F0, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h000F, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)        // ADD → Result=0x00FF
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8003, 2'b11, 1'b1)        // MVL → Led=Result=0x00FF
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h00FF)
   $display("TC-LED-029: Move Out to Led");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-030  Swap Led and Right
   // Led=0x1111, Right=0xAAAA → Led=0xAAAA, Right=0x1111
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h1111, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8005, 2'b11, 1'b1)        // Valid=1, CMD=swap
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hAAAA)
   $display("TC-LED-030a: Swap — Led=AAAA");
@(negedge clk)
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   `CHECK_VAL(16'h1111)
   $display("TC-LED-030b: Swap — Right=1111");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-031  Shift Left (CMD=6) Uses Led as Value
   // Led=0x0001, Right=0x0003 → Result=0x0008, Led unchanged
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0001, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0003, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8006, 2'b11, 1'b1)        // Valid=1, CMD=shl
@(negedge clk)
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   `CHECK_VAL(16'h0008)
   $display("TC-LED-031a: Shift Left Result=0008");
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0001)  // Led unchanged
   $display("TC-LED-031b: Led unchanged after SHL");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-032  Shift Right (CMD=7) Uses Led as Value
   // Led=0x0080, Right=0x0003 → Result=0x0010, Led unchanged
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0080, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0003, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8007, 2'b11, 1'b1)        // Valid=1, CMD=shr
@(negedge clk)
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   `CHECK_VAL(16'h0010)
   $display("TC-LED-032a: Shift Right Result=0010");
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0080)  // Led unchanged
   $display("TC-LED-032b: Led unchanged after SHR");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-033  ADD Overflow Triggers Error State and INT1
   // Led=0xFFFF, Right=0x0001 → overflow → Error state
   // Enable INT1 first via Config register
   // ================================================================
   // Enable INT1: write to Config register, bit8=1
@(negedge clk)
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)        // INT1_EN=1
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0001, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)        // ADD → overflow
@(negedge clk)
   // Check state is Error by reading Status register
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   // Status: state=4'h2 (Error), int1=1 → {6'h0, 0, 1, 4'h0, 4'h2} = 16'h0102
   `CHECK_VAL(16'h0102)
   $display("TC-LED-033: ADD Overflow → Error State, INT1 set");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-034  Led Value Preserved After Error Transition
   // ================================================================
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'hFFFF)  // Led preserved in Error state
   $display("TC-LED-034: Led Preserved After Error Transition");
@(negedge clk)
   `CLEAR_BUS

   // ── Recover from Error state ──
@(negedge clk)
   maroon <= 1'b1;
   gold   <= 1'b0;
@(negedge clk)
   maroon <= 1'b0;
   gold   <= 1'b1;
   // Clear INT1 by writing to Status register
@(negedge clk)
   `SET_WRITE(VCHIP_STA_ADDR, 16'h0100, 2'b11, 1'b1)       // clear INT1
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-035  Export Violation Resets Led Register
   // Led=0x1234, export_disable=1, issue restricted cmd
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h1234, 2'b11, 1'b1)
@(negedge clk)
   export_disable <= 1'b1;
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8006, 2'b11, 1'b1)        // CMD=6 (shl) > LAST_EXP_CMD
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h0000)  // Led reset to 0 in Export Violation
   $display("TC-LED-035: Export Violation Resets Led Register");
@(negedge clk)
   `CLEAR_BUS

   // ── Full reset to recover from Export Violation (stuck state) ──
@(negedge clk)
   export_disable <= 1'b0;
   wait( clk == 1'b0 );
   rst_b <= 1'b0;
   wait( clk == 1'b1 );
   rst_b <= 1'b1;
@(negedge clk)
   maroon <= 1'b0;
@(negedge clk)
   gold <= 1'b1;
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-036  Consecutive Writes — Last Write Wins
   // Write 0xAAAA then 0x5555 → read returns 0x5555
   // ================================================================
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h5555)
   $display("TC-LED-036: Consecutive Writes — Last Write Wins");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   // TC-LED-037  Write After Move-to-Led Overrides ALU Result
   // Execute MVL to load Led from Result, then overwrite directly
   // ================================================================
   // Set up: Led=0x00F0, Right=0x000F, ADD → Result=0x00FF
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h00F0, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h000F, 2'b11, 1'b1)
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)        // ADD → Result=0x00FF
@(negedge clk)
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8003, 2'b11, 1'b1)        // MVL → Led=0x00FF
   // Now directly overwrite Led
@(negedge clk)
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h1234, 2'b11, 1'b1)
@(negedge clk)
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   `CHECK_VAL(16'h1234)  // direct write overrides ALU move
   $display("TC-LED-037: Write After Move-to-Led Overrides ALU Result");
@(negedge clk)
   `CLEAR_BUS

   // ================================================================
   $display("ALL TC-LED TESTS COMPLETE");
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
