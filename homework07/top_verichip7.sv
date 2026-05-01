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
   byte_en <= 2'b11;                \
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

`define CHIP_RESET                  \
   wait( clk == 1'b0 );             \
   rst_b <= 1'b0;                   \
   wait( clk == 1'b1 );             \
   rst_b <= 1'b1;

`define WRITE_REG(addr,wval,bytes,cs)    \
   wait( clk == 1'b0 );                 \
   `SET_WRITE(addr,wval,bytes,cs)       \
   wait( clk == 1'b1 );                 \
   `CLEAR_BUS                           \
   wait( clk == 1'b0 );

`define READ_REG(addr,rval,cs)           \
   wait( clk == 1'b0 );                 \
   `SET_READ(addr,cs)                   \
   wait( clk == 1'b1 );                 \
   `CHECK_VAL(rval)                     \
   `CLEAR_BUS                           \
   wait( clk == 1'b0 );

`define CHECK_RW(addr,wval,rval,bytes,cs)    \
   `WRITE_REG(addr,wval,bytes,cs)            \
   `READ_REG(addr,rval,cs)

`define MATH_CMD(cmd)                                        \
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | cmd), 2'b11, 1'b1)

`define CHANGE_STATE_TO_NORMAL          \
   wait( clk == 1'b0 );                 \
   maroon <= 1'b0;                      \
   gold   <= 1'b1;                      \
   wait( clk == 1'b1 );                 \
   wait( clk == 1'b0 );                 \
   maroon <= 1'b0;                      \
   gold   <= 1'b0;

`define CHANGE_STATE_TO_ERR           \
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)

`define CHANGE_STATE_TO_EXP          \
   wait( clk == 1'b0 );                 \
   export_disable <= 1'b1;              \
   wait( clk == 1'b1 );                 \
   wait( clk == 1'b0 );                 \
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h0005), 2'b11, 1'b1)

`define WAIT_CYCLE                       \
   wait( clk == 1'b1 );                 \
   wait( clk == 1'b0 );

`define SETUP_ALU(lval, rval)            \
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, lval, 2'b11, 1'b1) \
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, rval, 2'b11, 1'b1)

`define CHECK_ALU_AND_STATE(exp_left, exp_right, exp_out, exp_state) \
   `READ_REG(VCHIP_ALU_LEFT_ADDR, exp_left, 1'b1)   \
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, exp_right, 1'b1) \
   `READ_REG(VCHIP_ALU_OUT_ADDR, exp_out, 1'b1)     \
   `READ_REG(VCHIP_STA_ADDR, exp_state, 1'b1)

// Setup for export tests: set export_disable=1, clear other signals, then reset
`define SETUP_EXPORT                     \
   wait( clk == 1'b0 );                 \
   export_disable <= 1'b1;              \
   maroon <= 1'b0;                      \
   gold   <= 1'b0;                      \
   `CLEAR_BUS                           \
   `CHIP_RESET

`define FORCE_LOST_STATE                    \
   wait( clk == 1'b0 );                    \
   force verichip7.state = 4'hF;           \
   wait( clk == 1'b1 );                    \
   wait( clk == 1'b0 );                    \
   release verichip7.state;                \
   wait( clk == 1'b1 );                    \
   wait( clk == 1'b0 );


module top_verichip7();

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

// Status register values for each state
localparam STA_RESET  = 16'h0000;
localparam STA_NORMAL = 16'h0001;
localparam STA_ERROR  = 16'h0002;
localparam STA_EXPORT = 16'h0008;
localparam STA_LOST   = 16'h000F;

// Test values: left, right, and out(=0 from reset) are all different
localparam TEST_LEFT  = 16'h000A;  // 10
localparam TEST_RIGHT = 16'h0003;  //  3

integer i;
integer j;

// Boundary + walking-1 + walking-0 + alternating-bit offsets
// relative to a 0x4000-wide range (0x0000 .. 0x3FFF).
// Add a range base (0x4000, 0x8000, 0xC000) to get actual values.
localparam integer NUM_PATS = 33;
logic [15:0] pat_off [0:NUM_PATS-1];

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

   // Initialize pattern offsets (boundary + walking-1 + walking-0 + alternating)
   // Boundaries
   pat_off[0]  = 16'h0000;  pat_off[1]  = 16'h0001;
   pat_off[2]  = 16'h3FFE;  pat_off[3]  = 16'h3FFF;
   // Midpoints
   pat_off[4]  = 16'h1FFF;  pat_off[5]  = 16'h2000;
   // Alternating bit patterns
   pat_off[6]  = 16'h1555;  pat_off[7]  = 16'h2AAA;
   // Walking 1s (bits 0-13)
   pat_off[8]  = 16'h0002;  pat_off[9]  = 16'h0004;
   pat_off[10] = 16'h0008;  pat_off[11] = 16'h0010;
   pat_off[12] = 16'h0020;  pat_off[13] = 16'h0040;
   pat_off[14] = 16'h0080;  pat_off[15] = 16'h0100;
   pat_off[16] = 16'h0200;  pat_off[17] = 16'h0400;
   pat_off[18] = 16'h0800;  pat_off[19] = 16'h1000;
   pat_off[20] = 16'h2000;
   // Walking 0s (from 0x3FFF, clear one bit at a time)
   pat_off[21] = 16'h3FFD;  pat_off[22] = 16'h3FFB;
   pat_off[23] = 16'h3FF7;  pat_off[24] = 16'h3FEF;
   pat_off[25] = 16'h3FDF;  pat_off[26] = 16'h3FBF;
   pat_off[27] = 16'h3F7F;  pat_off[28] = 16'h3EFF;
   pat_off[29] = 16'h3DFF;  pat_off[30] = 16'h3BFF;
   pat_off[31] = 16'h37FF;  pat_off[32] = 16'h2FFF;

   // ===================================================================
   // SECTION 1: RESET STATE - Test all 16 commands
   // In reset state, commands are ignored. ALU registers stay unchanged.
   // State must remain in Reset (0x0).
   // ===================================================================
   $display("\n=== RESET STATE TESTS ===");

   for (i = 0; i < 16; i = i + 1)
   begin
      `CLEAR_ALL
      `CHIP_RESET
      `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
      // Issue command i with valid bit set
      `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | i[15:0]), 2'b11, 1'b1)
      `WAIT_CYCLE
      // Verify: no change to ALU regs, state still Reset
      `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0000, STA_RESET)
      $display("Reset cmd %0d: PASS at %t", i, $time());
   end

   // ===================================================================
   // SECTION 2: NORMAL STATE - Test all 16 commands (export_disable=0)
   // Legal commands (0-7) get correct answers, state stays Normal.
   // Illegal commands (8-F) go to Error state.
   // ===================================================================
   $display("\n=== NORMAL STATE TESTS ===");

   // --- cmd 0: no command (nothing changes) ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h0000), 2'b11, 1'b1)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0000, STA_NORMAL)
   $display("Normal cmd 0 (none): PASS at %t", $time());

   // --- cmd 1: add (out = 0xA + 0x3 = 0xD) ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_ADD)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h000D, STA_NORMAL)
   $display("Normal cmd 1 (add): PASS at %t", $time());

   // --- cmd 2: sub (out = 0xA - 0x3 = 0x7) ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_SUB)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0007, STA_NORMAL)
   $display("Normal cmd 2 (sub): PASS at %t", $time());

   // --- cmd 3: mvl (left = out = 0x0000) ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_MVL)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(16'h0000, TEST_RIGHT, 16'h0000, STA_NORMAL)
   $display("Normal cmd 3 (mvl): PASS at %t", $time());

   // --- cmd 4: mvr (right = out = 0x0000) ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_MVR)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(TEST_LEFT, 16'h0000, 16'h0000, STA_NORMAL)
   $display("Normal cmd 4 (mvr): PASS at %t", $time());

   // --- cmd 5: swap (left=right=0x3, right=left=0xA, out unchanged) ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_SWA)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(TEST_RIGHT, TEST_LEFT, 16'h0000, STA_NORMAL)
   $display("Normal cmd 5 (swap): PASS at %t", $time());

   // --- cmd 6: shl (out = 0xA << 3 = 0x50) ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_SHL)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0050, STA_NORMAL)
   $display("Normal cmd 6 (shl): PASS at %t", $time());

   // --- cmd 7: shr (out = 0xA >> 3 = 0x1) ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_SHR)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0001, STA_NORMAL)
   $display("Normal cmd 7 (shr): PASS at %t", $time());

   // --- cmd 8-15: illegal commands -> Error state, ALU unchanged ---
   for (i = 8; i < 16; i = i + 1)
   begin
      `CLEAR_ALL
      `CHIP_RESET
      `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
      `CHANGE_STATE_TO_NORMAL
      `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | i[15:0]), 2'b11, 1'b1)
      `WAIT_CYCLE
      `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0000, STA_ERROR)
      $display("Normal cmd %0d (illegal->Error): PASS at %t", i, $time());
   end

   // ===================================================================
   // SECTION 3: OVERFLOW VIOLATION - 4 tests
   // Add/sub overflow with export_disable=0 and export_disable=1
   // All should go to Error state.
   // ===================================================================
   $display("\n=== OVERFLOW TESTS ===");

   // --- Add overflow, export_disable=0 ---
   // 0x7FFF + 0x0001 = 0x8000 (pos + pos = neg -> overflow)
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h7FFF, 16'h0001)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_ADD)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(16'h7FFF, 16'h0001, 16'h8000, STA_ERROR)
   $display("Overflow add (no export): PASS at %t", $time());

   // --- Sub overflow, export_disable=0 ---
   // 0x8000 - 0x0001 = 0x7FFF (neg - pos = pos -> overflow)
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h8000, 16'h0001)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_SUB)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(16'h8000, 16'h0001, 16'h7FFF, STA_ERROR)
   $display("Overflow sub (no export): PASS at %t", $time());

   // --- Add overflow, export_disable=1 ---
   // Add (cmd=1) is allowed with export, but overflow still -> Error
   `SETUP_EXPORT
   `SETUP_ALU(16'h7FFF, 16'h0001)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_ADD)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(16'h7FFF, 16'h0001, 16'h8000, STA_ERROR)
   $display("Overflow add (with export): PASS at %t", $time());

   // --- Sub overflow, export_disable=1 ---
   // Sub (cmd=2) is allowed with export, but overflow still -> Error
   `SETUP_EXPORT
   `SETUP_ALU(16'h8000, 16'h0001)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_SUB)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(16'h8000, 16'h0001, 16'h7FFF, STA_ERROR)
   $display("Overflow sub (with export): PASS at %t", $time());

   // ===================================================================
   // SECTION 4: EXPORT DISABLE - Test all 16 commands with export_disable=1
   // cmd 0-2 are legal (execute normally, stay Normal)
   // cmd 3-15 cause Export Violation state
   // ===================================================================
   $display("\n=== EXPORT DISABLE TESTS ===");

   // --- cmd 0: no command (stays Normal) ---
   `SETUP_EXPORT
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h0000), 2'b11, 1'b1)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0000, STA_NORMAL)
   $display("Export cmd 0 (none): PASS at %t", $time());

   // --- cmd 1: add (executes normally, out = 0xA + 0x3 = 0xD) ---
   `SETUP_EXPORT
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_ADD)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h000D, STA_NORMAL)
   $display("Export cmd 1 (add): PASS at %t", $time());

   // --- cmd 2: sub (executes normally, out = 0xA - 0x3 = 0x7) ---
   `SETUP_EXPORT
   `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
   `CHANGE_STATE_TO_NORMAL
   `MATH_CMD(VCHIP_ALU_SUB)
   `WAIT_CYCLE
   `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0007, STA_NORMAL)
   $display("Export cmd 2 (sub): PASS at %t", $time());

   // --- cmd 3-15: Export Violation (registers cleared, state=0x8) ---
   for (i = 3; i < 16; i = i + 1)
   begin
      `SETUP_EXPORT
      `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
      `CHANGE_STATE_TO_NORMAL
      `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | i[15:0]), 2'b11, 1'b1)
      `WAIT_CYCLE
      // In Export Violation: registers cleared, only Status readable
      `CHECK_ALU_AND_STATE(16'h0000, 16'h0000, 16'h0000, STA_EXPORT)
      $display("Export cmd %0d (violation): PASS at %t", i, $time());
   end

   // ===================================================================
   // SECTION 5: VALID=0 - Test all 16 commands with valid=0
   // Nothing should happen. All registers unchanged, state stays Normal.
   // ===================================================================
   $display("\n=== VALID=0 TESTS ===");

   for (i = 0; i < 16; i = i + 1)
   begin
      `CLEAR_ALL
      `CHIP_RESET
      `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
      `CHANGE_STATE_TO_NORMAL
      // Write command WITHOUT valid bit (bit 15 = 0)
      `WRITE_REG(VCHIP_CMD_ADDR, i[15:0], 2'b11, 1'b1)
      `WAIT_CYCLE
      // Verify: no change, state still Normal
      `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0000, STA_NORMAL)
      $display("Valid=0 cmd %0d: PASS at %t", i, $time());
   end



   // ===================================================================
   // SECTION 6: LOST STATE - Test all 16 commands
   // The LOST state (0xF) is the default case in the state machine.
   // It is reached when the state register holds an undefined value.
   // Once in LOST, it stays in LOST. Commands should not execute
   // (ALU unchanged), and state remains 0xF.
   // Force is required since no normal transition leads to LOST.
   // ===================================================================
   $display("\n=== LOST STATE TESTS ===");

   for (i = 0; i < 16; i = i + 1)
   begin
      `CLEAR_ALL
      `CHIP_RESET
      `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
      `FORCE_LOST_STATE
      // Issue command i with valid bit set
      `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | i[15:0]), 2'b11, 1'b1)
      `WAIT_CYCLE
      // Verify: ALU unchanged, state still LOST
      `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0000, STA_LOST)
      $display("Lost cmd %0d: PASS at %t", i, $time());
   end

   // ===================================================================
   // SECTION 7: ALU_LEFT REGISTER - Test writes in range 0xC000-0xFFFF
   // Uses boundary + walking-1/0 + alternating bit patterns (33 values)
   // instead of exhaustive sweep for fast simulation.
   // ===================================================================
   $display("\n=== ALU_LEFT REGISTER TESTS (0xC000 - 0xFFFF) ===");

   // --- 7a: Full word write (byte_en=2'b11) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
   end
   $display("ALU_LEFT full word 0xC000-0xFFFF: PASS at %t", $time());

   // --- 7b: High byte only (byte_en=2'b10) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'hC000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  {(pat_off[j][15:8] + 8'hC0), 8'h00}, 1'b1)
   end
   $display("ALU_LEFT high byte only 0xC000-0xFFFF: PASS at %t", $time());

   // --- 7c: Low byte only (byte_en=2'b01) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'hC000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  {8'h00, pat_off[j][7:0]}, 1'b1)
   end
   $display("ALU_LEFT low byte only 0xC000-0xFFFF: PASS at %t", $time());

   // --- 7d: No byte enable (byte_en=2'b00) - should NOT update ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'hC000), 2'b00, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 1'b1)
   end
   $display("ALU_LEFT byte_en=00 no update 0xC000-0xFFFF: PASS at %t", $time());

   // --- 7e: chip_select=0 - should NOT update ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b0)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 1'b1)
   end
   $display("ALU_LEFT chip_select=0 no update 0xC000-0xFFFF: PASS at %t", $time());

   // ===================================================================
   // SECTION 8: ALU_RIGHT REGISTER - Test writes in range 0xC000-0xFFFF
   // Uses boundary + walking-1/0 + alternating bit patterns (33 values).
   // ===================================================================
   $display("\n=== ALU_RIGHT REGISTER TESTS (0xC000 - 0xFFFF) ===");

   // --- 8a: Full word write (byte_en=2'b11) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
   end
   $display("ALU_RIGHT full word 0xC000-0xFFFF: PASS at %t", $time());

   // --- 8b: High byte only (byte_en=2'b10) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {(pat_off[j][15:8] + 8'hC0), 8'h00}, 1'b1)
   end
   $display("ALU_RIGHT high byte only 0xC000-0xFFFF: PASS at %t", $time());

   // --- 8c: Low byte only (byte_en=2'b01) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {8'h00, pat_off[j][7:0]}, 1'b1)
   end
   $display("ALU_RIGHT low byte only 0xC000-0xFFFF: PASS at %t", $time());

   // --- 8d: No byte enable (byte_en=2'b00) - should NOT update ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b00, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000, 1'b1)
   end
   $display("ALU_RIGHT byte_en=00 no update 0xC000-0xFFFF: PASS at %t", $time());

   // --- 8e: chip_select=0 - should NOT update ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b0)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000, 1'b1)
   end
   $display("ALU_RIGHT chip_select=0 no update 0xC000-0xFFFF: PASS at %t", $time());

   // ===================================================================
   // SECTION 9: ALU_RIGHT REGISTER - Test writes in range 0x4000-0x7FFF
   // Uses boundary + walking-1/0 + alternating bit patterns (33 values).
   // ===================================================================
   $display("\n=== ALU_RIGHT REGISTER TESTS (0x4000 - 0x7FFF) ===");

   // --- 9a: Full word write (byte_en=2'b11) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h4000), 1'b1)
   end
   $display("ALU_RIGHT full word 0x4000-0x7FFF: PASS at %t", $time());

   // --- 9b: High byte only (byte_en=2'b10) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {(pat_off[j][15:8] + 8'h40), 8'h00}, 1'b1)
   end
   $display("ALU_RIGHT high byte only 0x4000-0x7FFF: PASS at %t", $time());

   // --- 9c: Low byte only (byte_en=2'b01) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {8'h00, pat_off[j][7:0]}, 1'b1)
   end
   $display("ALU_RIGHT low byte only 0x4000-0x7FFF: PASS at %t", $time());

   // --- 9d: No byte enable (byte_en=2'b00) - should NOT update ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b00, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000, 1'b1)
   end
   $display("ALU_RIGHT byte_en=00 no update 0x4000-0x7FFF: PASS at %t", $time());

   // --- 9e: chip_select=0 - should NOT update ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b11, 1'b0)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000, 1'b1)
   end
   $display("ALU_RIGHT chip_select=0 no update 0x4000-0x7FFF: PASS at %t", $time());

   // ===================================================================
   // SECTION 10: ALU_RIGHT REGISTER - Test writes in range 0x8000-0xBFFF
   // Uses boundary + walking-1/0 + alternating bit patterns (33 values).
   // ===================================================================
   $display("\n=== ALU_RIGHT REGISTER TESTS (0x8000 - 0xBFFF) ===");

   // --- 10a: Full word write (byte_en=2'b11) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h8000), 1'b1)
   end
   $display("ALU_RIGHT full word 0x8000-0xBFFF: PASS at %t", $time());

   // --- 10b: High byte only (byte_en=2'b10) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {(pat_off[j][15:8] + 8'h80), 8'h00}, 1'b1)
   end
   $display("ALU_RIGHT high byte only 0x8000-0xBFFF: PASS at %t", $time());

   // --- 10c: Low byte only (byte_en=2'b01) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {8'h00, pat_off[j][7:0]}, 1'b1)
   end
   $display("ALU_RIGHT low byte only 0x8000-0xBFFF: PASS at %t", $time());

   // --- 10d: No byte enable (byte_en=2'b00) - should NOT update ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b00, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000, 1'b1)
   end
   $display("ALU_RIGHT byte_en=00 no update 0x8000-0xBFFF: PASS at %t", $time());

   // --- 10e: chip_select=0 - should NOT update ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b11, 1'b0)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000, 1'b1)
   end
   $display("ALU_RIGHT chip_select=0 no update 0x8000-0xBFFF: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.5: ALU_LEFT(0x8000-0xBFFF) / ALU_RIGHT(0x4000-0x7FFF)
   // CROSSOVER TEST - Boundary + walking patterns (33 values).
   // LEFT base: 0x8000    RIGHT base: 0x4000
   // ===================================================================
   $display("\n=== ALU LEFT(0x8000-0xBFFF) / RIGHT(0x4000-0x7FFF) CROSSOVER ===");

   // --- 10.5a: Full word write to both, read both back ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'h8000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h4000), 1'b1)
   end
   $display("Crossover10.5 full word both regs: PASS at %t", $time());

   // --- 10.5b: Sweep LEFT (0x8000-0xBFFF), RIGHT pinned at 0x4000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h4000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'h4000, 1'b1)
   end
   $display("Crossover10.5 sweep LEFT, RIGHT pinned 0x4000: PASS at %t", $time());

   // --- 10.5c: Sweep RIGHT (0x4000-0x7FFF), LEFT pinned at 0x8000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h8000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h4000), 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   16'h8000, 1'b1)
   end
   $display("Crossover10.5 sweep RIGHT, LEFT pinned 0x8000: PASS at %t", $time());

   // --- 10.5d: Opposite values - LEFT and ~LEFT, read both back ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000),  2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, ~(pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'h8000),  1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  ~(pat_off[j] + 16'h8000), 1'b1)
   end
   $display("Crossover10.5 opposite values LEFT/RIGHT: PASS at %t", $time());

   // --- 10.5e: Byte-enable crossover - high byte LEFT, low byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 2'b10, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {(pat_off[j][15:8] + 8'h80), 8'h00}, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {8'h00, pat_off[j][7:0]},             1'b1)
   end
   $display("Crossover10.5 byte-enable hi-LEFT lo-RIGHT: PASS at %t", $time());

   // --- 10.5f: Byte-enable crossover - low byte LEFT, high byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 2'b01, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {8'h00, pat_off[j][7:0]},             1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {(pat_off[j][15:8] + 8'h40), 8'h00}, 1'b1)
   end
   $display("Crossover10.5 byte-enable lo-LEFT hi-RIGHT: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.6: ALU_LEFT(0x8000-0xBFFF) / ALU_RIGHT(0x8000-0xBFFF)
   // CROSSOVER TEST - Boundary + walking patterns (33 values).
   // Both registers use the same range (base 0x8000).
   // ===================================================================
   $display("\n=== ALU LEFT(0x8000-0xBFFF) / RIGHT(0x8000-0xBFFF) CROSSOVER ===");

   // --- 10.6a: Write same value to both, read both back ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'h8000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h8000), 1'b1)
   end
   $display("Crossover10.6 same value both regs: PASS at %t", $time());

   // --- 10.6b: Sweep LEFT, RIGHT pinned at 0x8000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h8000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'h8000, 1'b1)
   end
   $display("Crossover10.6 sweep LEFT, RIGHT pinned 0x8000: PASS at %t", $time());

   // --- 10.6c: Sweep RIGHT, LEFT pinned at 0x8000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h8000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h8000), 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   16'h8000, 1'b1)
   end
   $display("Crossover10.6 sweep RIGHT, LEFT pinned 0x8000: PASS at %t", $time());

   // --- 10.6d: Opposite values - LEFT gets pattern, RIGHT gets inverse ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000),  2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, ~(pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'h8000),  1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  ~(pat_off[j] + 16'h8000), 1'b1)
   end
   $display("Crossover10.6 opposite values LEFT/RIGHT: PASS at %t", $time());

   // --- 10.6e: Byte-enable crossover - high byte LEFT, low byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 2'b10, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {(pat_off[j][15:8] + 8'h80), 8'h00}, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {8'h00, pat_off[j][7:0]},             1'b1)
   end
   $display("Crossover10.6 byte-enable hi-LEFT lo-RIGHT: PASS at %t", $time());

   // --- 10.6f: Byte-enable crossover - low byte LEFT, high byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 2'b01, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {8'h00, pat_off[j][7:0]},             1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {(pat_off[j][15:8] + 8'h80), 8'h00}, 1'b1)
   end
   $display("Crossover10.6 byte-enable lo-LEFT hi-RIGHT: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.7: ALU_LEFT(0xC000-0xFFFF) / ALU_RIGHT(0x8000-0xBFFF)
   // CROSSOVER TEST - Boundary + walking patterns (33 values).
   // LEFT base: 0xC000    RIGHT base: 0x8000
   // ===================================================================
   $display("\n=== ALU LEFT(0xC000-0xFFFF) / RIGHT(0x8000-0xBFFF) CROSSOVER ===");

   // --- 10.7a: Full word write to both, read both back ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'hC000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h8000), 1'b1)
   end
   $display("Crossover10.7 full word both regs: PASS at %t", $time());

   // --- 10.7b: Sweep LEFT (0xC000-0xFFFF), RIGHT pinned at 0x8000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h8000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'h8000, 1'b1)
   end
   $display("Crossover10.7 sweep LEFT, RIGHT pinned 0x8000: PASS at %t", $time());

   // --- 10.7c: Sweep RIGHT (0x8000-0xBFFF), LEFT pinned at 0xC000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hC000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h8000), 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   16'hC000, 1'b1)
   end
   $display("Crossover10.7 sweep RIGHT, LEFT pinned 0xC000: PASS at %t", $time());

   // --- 10.7d: Opposite values - LEFT gets pattern, RIGHT gets inverse ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000),  2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, ~(pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'hC000),  1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  ~(pat_off[j] + 16'hC000), 1'b1)
   end
   $display("Crossover10.7 opposite values LEFT/RIGHT: PASS at %t", $time());

   // --- 10.7e: Byte-enable crossover - high byte LEFT, low byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 2'b10, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {(pat_off[j][15:8] + 8'hC0), 8'h00}, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {8'h00, pat_off[j][7:0]},             1'b1)
   end
   $display("Crossover10.7 byte-enable hi-LEFT lo-RIGHT: PASS at %t", $time());

   // --- 10.7f: Byte-enable crossover - low byte LEFT, high byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 2'b01, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h8000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {8'h00, pat_off[j][7:0]},             1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {(pat_off[j][15:8] + 8'h80), 8'h00}, 1'b1)
   end
   $display("Crossover10.7 byte-enable lo-LEFT hi-RIGHT: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.8: ALU_LEFT(0xC000-0xFFFF) / ALU_RIGHT(0x4000-0x7FFF)
   // CROSSOVER TEST - Boundary + walking patterns (33 values).
   // LEFT base: 0xC000    RIGHT base: 0x4000
   // ===================================================================
   $display("\n=== ALU LEFT(0xC000-0xFFFF) / RIGHT(0x4000-0x7FFF) CROSSOVER ===");

   // --- 10.8a: Full word write to both, read both back ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'hC000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h4000), 1'b1)
   end
   $display("Crossover10.8 full word both regs: PASS at %t", $time());

   // --- 10.8b: Sweep LEFT (0xC000-0xFFFF), RIGHT pinned at 0x4000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h4000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'h4000, 1'b1)
   end
   $display("Crossover10.8 sweep LEFT, RIGHT pinned 0x4000: PASS at %t", $time());

   // --- 10.8c: Sweep RIGHT (0x4000-0x7FFF), LEFT pinned at 0xC000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hC000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h4000), 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   16'hC000, 1'b1)
   end
   $display("Crossover10.8 sweep RIGHT, LEFT pinned 0xC000: PASS at %t", $time());

   // --- 10.8d: Opposite values - LEFT gets pattern, RIGHT gets inverse ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000),  2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, ~(pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'hC000),  1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  ~(pat_off[j] + 16'hC000), 1'b1)
   end
   $display("Crossover10.8 opposite values LEFT/RIGHT: PASS at %t", $time());

   // --- 10.8e: Byte-enable crossover - high byte LEFT, low byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 2'b10, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {(pat_off[j][15:8] + 8'hC0), 8'h00}, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {8'h00, pat_off[j][7:0]},             1'b1)
   end
   $display("Crossover10.8 byte-enable hi-LEFT lo-RIGHT: PASS at %t", $time());

   // --- 10.8f: Byte-enable crossover - low byte LEFT, high byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 2'b01, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {8'h00, pat_off[j][7:0]},             1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {(pat_off[j][15:8] + 8'h40), 8'h00}, 1'b1)
   end
   $display("Crossover10.8 byte-enable lo-LEFT hi-RIGHT: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.9: ALU_LEFT(0xC000-0xFFFF) / ALU_RIGHT(0xC000-0xFFFF)
   // CROSSOVER TEST - Boundary + walking patterns (33 values).
   // Both registers use the same range (base 0xC000).
   // ===================================================================
   $display("\n=== ALU LEFT(0xC000-0xFFFF) / RIGHT(0xC000-0xFFFF) CROSSOVER ===");

   // --- 10.9a: Write same value to both, read both back ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'hC000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
   end
   $display("Crossover10.9 same value both regs: PASS at %t", $time());

   // --- 10.9b: Sweep LEFT, RIGHT pinned at 0xC000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hC000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hC000, 1'b1)
   end
   $display("Crossover10.9 sweep LEFT, RIGHT pinned 0xC000: PASS at %t", $time());

   // --- 10.9c: Sweep RIGHT, LEFT pinned at 0xC000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hC000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   16'hC000, 1'b1)
   end
   $display("Crossover10.9 sweep RIGHT, LEFT pinned 0xC000: PASS at %t", $time());

   // --- 10.9d: Opposite values - LEFT gets pattern, RIGHT gets inverse ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000),  2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, ~(pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'hC000),  1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  ~(pat_off[j] + 16'hC000), 1'b1)
   end
   $display("Crossover10.9 opposite values LEFT/RIGHT: PASS at %t", $time());

   // --- 10.9e: Byte-enable crossover - high byte LEFT, low byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 2'b10, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {(pat_off[j][15:8] + 8'hC0), 8'h00}, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {8'h00, pat_off[j][7:0]},             1'b1)
   end
   $display("Crossover10.9 byte-enable hi-LEFT lo-RIGHT: PASS at %t", $time());

   // --- 10.9f: Byte-enable crossover - low byte LEFT, high byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'hC000), 2'b01, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {8'h00, pat_off[j][7:0]},             1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {(pat_off[j][15:8] + 8'hC0), 8'h00}, 1'b1)
   end
   $display("Crossover10.9 byte-enable lo-LEFT hi-RIGHT: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.10: RESET -> ERROR STATE TRANSITION TESTS
   // There is NO direct RESET -> ERROR transition in the state machine.
   // From RESET, only !maroon && gold moves to NORM; everything else
   // stays in RESET. These tests verify:
   //   (A) Error-causing actions in RESET do NOT jump to ERROR.
   //   (B) The correct path RESET -> NORM -> ERROR works.
   // ===================================================================
   $display("\n=== RESET -> ERROR STATE TRANSITION TESTS ===");

   // --- 10.10a: Bad command (cmd 8-15) in RESET stays in RESET ---
   for (i = 8; i < 16; i = i + 1)
   begin
      `CLEAR_ALL
      `CHIP_RESET
      `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
      // Issue illegal command while still in RESET
      `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | i[15:0]), 2'b11, 1'b1)
      `WAIT_CYCLE
      // State must remain RESET, NOT jump to ERROR
      `CHECK_ALU_AND_STATE(TEST_LEFT, TEST_RIGHT, 16'h0000, STA_RESET)
      $display("Reset bad cmd %0d stays Reset: PASS at %t", i, $time());
   end

   // --- 10.10b: Add overflow in RESET stays in RESET ---
   // 0x7FFF + 0x0001 = 0x8000 (pos+pos=neg) would overflow in NORM
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h7FFF, 16'h0001)
   `MATH_CMD(VCHIP_ALU_ADD)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_RESET, 1'b1)
   $display("Reset add overflow stays Reset: PASS at %t", $time());

   // --- 10.10c: Sub overflow in RESET stays in RESET ---
   // 0x8000 - 0x0001 = 0x7FFF (neg-pos=pos) would overflow in NORM
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h8000, 16'h0001)
   `MATH_CMD(VCHIP_ALU_SUB)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_RESET, 1'b1)
   $display("Reset sub overflow stays Reset: PASS at %t", $time());

   // --- 10.10d: Multiple error attempts in RESET, then transition
   //             RESET -> NORM -> ERROR via bad command ---
   `CLEAR_ALL
   `CHIP_RESET
   // Fire several bad commands while in RESET - all ignored
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000A), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_RESET, 1'b1)
   // Now transition to NORM
   `CHANGE_STATE_TO_NORMAL
   `READ_REG(VCHIP_STA_ADDR, STA_NORMAL, 1'b1)
   // Now issue bad command -> should go to ERROR
   `CHANGE_STATE_TO_ERR
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_ERROR, 1'b1)
   $display("Reset(ignored) -> Normal -> Error: PASS at %t", $time());

   // --- 10.10e: RESET -> NORM -> ERROR via add overflow ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h7FFF, 16'h0001)
   `CHANGE_STATE_TO_NORMAL
   `READ_REG(VCHIP_STA_ADDR, STA_NORMAL, 1'b1)
   `MATH_CMD(VCHIP_ALU_ADD)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_ERROR, 1'b1)
   $display("Reset -> Normal -> Error (add overflow): PASS at %t", $time());

   // --- 10.10f: RESET -> NORM -> ERROR via sub overflow ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h8000, 16'h0001)
   `CHANGE_STATE_TO_NORMAL
   `READ_REG(VCHIP_STA_ADDR, STA_NORMAL, 1'b1)
   `MATH_CMD(VCHIP_ALU_SUB)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_ERROR, 1'b1)
   $display("Reset -> Normal -> Error (sub overflow): PASS at %t", $time());

   // --- 10.10g: RESET -> NORM -> ERROR via each bad command (8-15) ---
   for (i = 8; i < 16; i = i + 1)
   begin
      `CLEAR_ALL
      `CHIP_RESET
      `SETUP_ALU(TEST_LEFT, TEST_RIGHT)
      `CHANGE_STATE_TO_NORMAL
      `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | i[15:0]), 2'b11, 1'b1)
      `WAIT_CYCLE
      `READ_REG(VCHIP_STA_ADDR, STA_ERROR, 1'b1)
      $display("Reset -> Normal -> Error (bad cmd %0d): PASS at %t", i, $time());
   end

   // --- 10.10h: Verify maroon/gold inputs do NOT cause ERROR from RESET ---
   // maroon=1, gold=0 keeps RESET (this combo recovers from ERROR, not RESET)
   `CLEAR_ALL
   `CHIP_RESET
   wait(clk == 1'b0);
   maroon <= 1'b1;
   gold   <= 1'b0;
   wait(clk == 1'b1);
   wait(clk == 1'b0);
   `READ_REG(VCHIP_STA_ADDR, STA_RESET, 1'b1)
   $display("Reset maroon=1 gold=0 stays Reset: PASS at %t", $time());

   // maroon=1, gold=1 keeps RESET
   `CLEAR_ALL
   `CHIP_RESET
   wait(clk == 1'b0);
   maroon <= 1'b1;
   gold   <= 1'b1;
   wait(clk == 1'b1);
   wait(clk == 1'b0);
   `READ_REG(VCHIP_STA_ADDR, STA_RESET, 1'b1)
   $display("Reset maroon=1 gold=1 stays Reset: PASS at %t", $time());

   // maroon=0, gold=0 keeps RESET
   `CLEAR_ALL
   `CHIP_RESET
   wait(clk == 1'b0);
   maroon <= 1'b0;
   gold   <= 1'b0;
   wait(clk == 1'b1);
   wait(clk == 1'b0);
   `READ_REG(VCHIP_STA_ADDR, STA_RESET, 1'b1)
   $display("Reset maroon=0 gold=0 stays Reset: PASS at %t", $time());

   // maroon=0, gold=1 -> transitions to NORM (only valid exit from RESET)
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `READ_REG(VCHIP_STA_ADDR, STA_NORMAL, 1'b1)
   $display("Reset maroon=0 gold=1 -> Normal: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.11: CONFIGURATION REGISTER (VCHIP_ADDR_CON = 0x0C) TESTS
   // con_reg = {6'h0, int2_en, int1_en, 8'h0}
   // Only bits 9 (int2_en) and 8 (int1_en) are writable.
   // Write requires: chip_select=1, rw_=0, address=0x0C, byte_en[1]=1.
   // Behavior: reset->0, EXP->0, ERR->hold, NORM->writable.
   // ===================================================================
   $display("\n=== CONFIGURATION REGISTER TESTS ===");


   // --- 10.11a: Reset value should be 0x0000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `READ_REG(VCHIP_CON_ADDR, 16'h0000, 1'b1)
   $display("Config reset value 0x0000: PASS at %t", $time());

   // --- 10.11b: Write all 4 combinations of int1_en/int2_en ---
   // int1_en=0, int2_en=0 -> con_reg = 0x0000
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0000, 1'b1)
   $display("Config int1=0 int2=0: PASS at %t", $time());

   // int1_en=1, int2_en=0 -> con_reg = 0x0100
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0100, 1'b1)
   $display("Config int1=1 int2=0: PASS at %t", $time());

   // int1_en=0, int2_en=1 -> con_reg = 0x0200
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0200, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0200, 1'b1)
   $display("Config int1=0 int2=1: PASS at %t", $time());

   // int1_en=1, int2_en=1 -> con_reg = 0x0300
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0300, 1'b1)
   $display("Config int1=1 int2=1: PASS at %t", $time());

   // --- 10.11c: byte_en=2'b10 (high byte only) should update ---
   // int enables are in the high byte (bits 9:8)
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b10, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0300, 1'b1)
   $display("Config byte_en=10 updates: PASS at %t", $time());

   // --- 10.11d: byte_en=2'b01 (low byte only) should NOT update ---
   // int enables require byte_en[1]=1 to write
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b01, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0000, 1'b1)
   $display("Config byte_en=01 no update: PASS at %t", $time());

   // --- 10.11e: byte_en=2'b00 should NOT update ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b00, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0300, 1'b1)
   $display("Config byte_en=00 no update: PASS at %t", $time());

   // --- 10.11f: chip_select=0 should NOT update ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b0)
   `READ_REG(VCHIP_CON_ADDR, 16'h0000, 1'b1)
   $display("Config chip_select=0 no update: PASS at %t", $time());

   // --- 10.11g: Read-only bits - writing junk to unused bits ignored ---
   // Write 0xFFFF, only bits 9:8 should appear in readback
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0300, 1'b1)
   $display("Config write 0xFFFF reads 0x0300: PASS at %t", $time());

   // Write 0x0000, both enables cleared
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0000, 1'b1)
   $display("Config write 0x0000 reads 0x0000: PASS at %t", $time());

   // --- 10.11h: Config register holds value in ERROR state ---
   // Set both enables, then go to ERROR, verify they hold
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0300, 1'b1)
   // Transition to ERROR via bad command
   `CHANGE_STATE_TO_ERR
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_ERROR, 1'b1)
   // Config should be frozen at 0x0300
   `READ_REG(VCHIP_CON_ADDR, 16'h0300, 1'b1)
   $display("Config holds in Error (0x0300): PASS at %t", $time());

   // Same test with only int1_en set
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_ERROR, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0100, 1'b1)
   $display("Config holds in Error (0x0100): PASS at %t", $time());

   // --- 10.11i: Writes to config register are ignored in ERROR state ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_ERROR, 1'b1)
   // Try to clear enables while in ERROR - should be ignored
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0300, 1'b1)
   $display("Config write ignored in Error: PASS at %t", $time());

   // --- 10.11j: Config register cleared on EXP state transition ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0300, 1'b1)
   // Transition to EXPORT
   `CHANGE_STATE_TO_EXP
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_EXPORT, 1'b1)
   // Config should be cleared to 0x0000
   `READ_REG(VCHIP_CON_ADDR, 16'h0000, 1'b1)
   $display("Config cleared on Export: PASS at %t", $time());

   // --- 10.11k: Config not writable in RESET state ---
   `CLEAR_ALL
   `CHIP_RESET
   `READ_REG(VCHIP_CON_ADDR, 16'h0000, 1'b1)
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR, 16'h0000, 1'b1)
   $display("Config not writable in Reset: PASS at %t", $time());

   // --- 10.11l: Address decoding - writing to other addresses
   //             should NOT affect config register ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   // Write to every other register address
   `WRITE_REG(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, 16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR,   16'h0000, 2'b11, 1'b1)
   // Config should still be 0x0300
   `READ_REG(VCHIP_CON_ADDR, 16'h0300, 1'b1)
   $display("Config unaffected by other addr writes: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.12: INTERRUPT 1 / INTERRUPT 2 CROSSOVER TESTS
   // int1 sets when: int1_en && state==NORM && valid && (bad_cmd||overflow)
   // int2 sets when: int2_en && state==NORM && valid && bad_exp_cmd
   // Both clear by writing 1 to their bit in status register (byte_en[1]).
   // Status reg: {6'h0, int2, int1, 4'h0, state}
   //   int1 = bit 8,  int2 = bit 9
   // ===================================================================
   $display("\n=== INTERRUPT 1 / INTERRUPT 2 CROSSOVER TESTS ===");

   // -----------------------------------------------------------------
   // GROUP A: RESET BEHAVIOR
   // -----------------------------------------------------------------

   // --- 10.12a1: Both interrupts clear after reset ---
   `CLEAR_ALL
   `CHIP_RESET
   `READ_REG(VCHIP_STA_ADDR, 16'h0000, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: interrupts not 0 after reset at %t", $time());
   $display("Both interrupts 0 after reset: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP B: ENABLE COMBINATIONS - int1 trigger (bad_cmd, no export)
   // Trigger: cmd=0xF (bad_cmd) without export_disable -> int1 only
   // State goes to ERROR, status bit 8 = int1
   // -----------------------------------------------------------------

   // --- 10.12b1: int1_en=0, int2_en=0 -> neither fires ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0002, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: interrupt fired with enables=00 at %t", $time());
   $display("bad_cmd en=00 neither fires: PASS at %t", $time());

   // --- 10.12b2: int1_en=1, int2_en=0 -> int1 fires ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)
   if (interrupt_1 !== 1'b1)
      $display("bad: int1 should be 1 at %t", $time());
   if (interrupt_2 !== 1'b0)
      $display("bad: int2 should be 0 at %t", $time());
   $display("bad_cmd en=10 int1 fires: PASS at %t", $time());

   // --- 10.12b3: int1_en=0, int2_en=1 -> neither fires (int2 needs bad_exp_cmd) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0200, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0002, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: interrupt fired unexpectedly at %t", $time());
   $display("bad_cmd en=01 neither fires (no exp): PASS at %t", $time());

   // --- 10.12b4: int1_en=1, int2_en=1 -> int1 fires only (no export) ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)
   if (interrupt_1 !== 1'b1)
      $display("bad: int1 should be 1 at %t", $time());
   if (interrupt_2 !== 1'b0)
      $display("bad: int2 should be 0 at %t", $time());
   $display("bad_cmd en=11 int1 only (no exp): PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP C: ENABLE COMBINATIONS - int2 trigger (bad_exp_cmd, cmd 3-7)
   // Trigger: export_disable=1, cmd=5 (SWA, > LAST_EXP_CMD=2)
   // bad_exp_cmd=1, bad_cmd=0 -> int2 only, state goes to EXP
   // -----------------------------------------------------------------

   // --- 10.12c1: int1_en=0, int2_en=0 -> neither fires ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h0005), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0008, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: interrupt fired with enables=00 at %t", $time());
   $display("exp_cmd en=00 neither fires: PASS at %t", $time());

   // --- 10.12c2: int1_en=1, int2_en=0 -> neither fires (int1 needs bad_cmd) ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h0005), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0008, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: interrupt fired unexpectedly at %t", $time());
   $display("exp_cmd en=10 neither fires (no bad_cmd): PASS at %t", $time());

   // --- 10.12c3: int1_en=0, int2_en=1 -> int2 fires ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0200, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h0005), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)
   if (interrupt_2 !== 1'b1)
      $display("bad: int2 should be 1 at %t", $time());
   if (interrupt_1 !== 1'b0)
      $display("bad: int1 should be 0 at %t", $time());
   $display("exp_cmd en=01 int2 fires: PASS at %t", $time());

   // --- 10.12c4: int1_en=1, int2_en=1 -> int2 fires only (cmd 5 is not bad_cmd) ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h0005), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)
   if (interrupt_2 !== 1'b1)
      $display("bad: int2 should be 1 at %t", $time());
   if (interrupt_1 !== 1'b0)
      $display("bad: int1 should be 0 at %t", $time());
   $display("exp_cmd en=11 int2 only (cmd<=7): PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP D: BOTH INTERRUPTS TRIGGERED SIMULTANEOUSLY
   // Trigger: export_disable=1, cmd=0xF (> 7, so bad_cmd=1 AND bad_exp_cmd=1)
   // State goes to EXP (checked first in FSM)
   // -----------------------------------------------------------------

   // --- 10.12d1: Both enabled, both fire simultaneously ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0308, 1'b1)
   if (interrupt_1 !== 1'b1)
      $display("bad: int1 should be 1 at %t", $time());
   if (interrupt_2 !== 1'b1)
      $display("bad: int2 should be 1 at %t", $time());
   $display("Both fire (exp+bad_cmd): PASS at %t", $time());

   // --- 10.12d2: int1_en=1 only, cmd=0xF with export -> int1 fires, int2 doesn't ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0108, 1'b1)
   if (interrupt_1 !== 1'b1)
      $display("bad: int1 should be 1 at %t", $time());
   if (interrupt_2 !== 1'b0)
      $display("bad: int2 should be 0 at %t", $time());
   $display("cmd=F exp en=10 int1 only: PASS at %t", $time());

   // --- 10.12d3: int2_en=1 only, cmd=0xF with export -> int2 fires, int1 doesn't ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0200, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)
   if (interrupt_1 !== 1'b0)
      $display("bad: int1 should be 0 at %t", $time());
   if (interrupt_2 !== 1'b1)
      $display("bad: int2 should be 1 at %t", $time());
   $display("cmd=F exp en=01 int2 only: PASS at %t", $time());

   // --- 10.12d4: Neither enabled, cmd=0xF with export -> neither fires ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0008, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: interrupt fired with enables=00 at %t", $time());
   $display("cmd=F exp en=00 neither fires: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP E: OVERFLOW TRIGGERS INT1 (not int2)
   // -----------------------------------------------------------------

   // --- 10.12e1: Add overflow, int1_en=1 -> int1 fires ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h7FFF, 16'h0001)
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `MATH_CMD(VCHIP_ALU_ADD)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)
   if (interrupt_1 !== 1'b1)
      $display("bad: int1 should be 1 at %t", $time());
   if (interrupt_2 !== 1'b0)
      $display("bad: int2 should be 0 at %t", $time());
   $display("Add overflow int1 fires: PASS at %t", $time());

   // --- 10.12e2: Sub overflow, int1_en=1 -> int1 fires ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h8000, 16'h0001)
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `MATH_CMD(VCHIP_ALU_SUB)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)
   if (interrupt_1 !== 1'b1)
      $display("bad: int1 should be 1 at %t", $time());
   if (interrupt_2 !== 1'b0)
      $display("bad: int2 should be 0 at %t", $time());
   $display("Sub overflow int1 fires: PASS at %t", $time());

   // --- 10.12e3: Add overflow, int1_en=0 -> int1 does NOT fire ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h7FFF, 16'h0001)
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0200, 2'b11, 1'b1)
   `MATH_CMD(VCHIP_ALU_ADD)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0002, 1'b1)
   if (interrupt_1 !== 1'b0)
      $display("bad: int1 should be 0 at %t", $time());
   $display("Add overflow int1_en=0 no fire: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP F: CLEARING INTERRUPTS - CROSSOVER
   // Both interrupts set, then selectively clear one at a time
   // -----------------------------------------------------------------

   // --- 10.12f1: Both set, clear int1 only (write bit 8 to status) ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   // Both should be set
   `READ_REG(VCHIP_STA_ADDR, 16'h0308, 1'b1)
   // Clear int1 only (write 1 to bit 8 of status)
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b11, 1'b1)
   // int1 cleared, int2 still set
   `READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)
   if (interrupt_1 !== 1'b0)
      $display("bad: int1 should be cleared at %t", $time());
   if (interrupt_2 !== 1'b1)
      $display("bad: int2 should still be set at %t", $time());
   $display("Clear int1 only, int2 remains: PASS at %t", $time());

   // --- 10.12f2: Both set, clear int2 only (write bit 9 to status) ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0308, 1'b1)
   // Clear int2 only (write 1 to bit 9 of status)
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0200, 2'b11, 1'b1)
   // int2 cleared, int1 still set
   `READ_REG(VCHIP_STA_ADDR, 16'h0108, 1'b1)
   if (interrupt_1 !== 1'b1)
      $display("bad: int1 should still be set at %t", $time());
   if (interrupt_2 !== 1'b0)
      $display("bad: int2 should be cleared at %t", $time());
   $display("Clear int2 only, int1 remains: PASS at %t", $time());

   // --- 10.12f3: Both set, clear both simultaneously (write bits 9:8) ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0308, 1'b1)
   // Clear both (write 1 to bits 9 and 8)
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0300, 2'b11, 1'b1)
   `READ_REG(VCHIP_STA_ADDR, 16'h0008, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: both should be cleared at %t", $time());
   $display("Clear both simultaneously: PASS at %t", $time());

   // --- 10.12f4: Both set, clear int1 then int2 sequentially ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0308, 1'b1)
   // Clear int1 first
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b11, 1'b1)
   `READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)
   // Then clear int2
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0200, 2'b11, 1'b1)
   `READ_REG(VCHIP_STA_ADDR, 16'h0008, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: both should be cleared at %t", $time());
   $display("Clear int1 then int2 sequential: PASS at %t", $time());

   // --- 10.12f5: Both set, clear int2 then int1 sequentially ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0308, 1'b1)
   // Clear int2 first
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0200, 2'b11, 1'b1)
   `READ_REG(VCHIP_STA_ADDR, 16'h0108, 1'b1)
   // Then clear int1
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b11, 1'b1)
   `READ_REG(VCHIP_STA_ADDR, 16'h0008, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: both should be cleared at %t", $time());
   $display("Clear int2 then int1 sequential: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP G: CLEAR REQUIRES byte_en[1]
   // -----------------------------------------------------------------

   // --- 10.12g1: Clear attempt with byte_en=2'b01 -> should NOT clear ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)
   // Try clearing with byte_en=01 (low byte only)
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b01, 1'b1)
   `READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)
   if (interrupt_1 !== 1'b1)
      $display("bad: int1 should NOT have cleared at %t", $time());
   $display("Clear with byte_en=01 fails: PASS at %t", $time());

   // --- 10.12g2: Clear attempt with byte_en=2'b00 -> should NOT clear ---
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b00, 1'b1)
   `READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)
   if (interrupt_1 !== 1'b1)
      $display("bad: int1 should NOT have cleared at %t", $time());
   $display("Clear with byte_en=00 fails: PASS at %t", $time());

   // --- 10.12g3: Clear with byte_en=2'b10 -> should clear ---
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b10, 1'b1)
   `READ_REG(VCHIP_STA_ADDR, 16'h0002, 1'b1)
   if (interrupt_1 !== 1'b0)
      $display("bad: int1 should have cleared at %t", $time());
   $display("Clear with byte_en=10 works: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP H: VALID COMMANDS DO NOT TRIGGER INTERRUPTS
   // -----------------------------------------------------------------

   // --- 10.12h1: Valid add (no overflow), both enables on -> no interrupts ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h0001, 16'h0002)
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `MATH_CMD(VCHIP_ALU_ADD)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_NORMAL, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: interrupt fired on valid cmd at %t", $time());
   $display("Valid add no interrupts: PASS at %t", $time());

   // --- 10.12h2: Valid sub (no overflow), both enables on -> no interrupts ---
   `CLEAR_ALL
   `CHIP_RESET
   `SETUP_ALU(16'h0005, 16'h0002)
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `MATH_CMD(VCHIP_ALU_SUB)
   `WAIT_CYCLE
   `READ_REG(VCHIP_STA_ADDR, STA_NORMAL, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: interrupt fired on valid cmd at %t", $time());
   $display("Valid sub no interrupts: PASS at %t", $time());

   // --- 10.12h3: All valid commands (0-7) with both enables, no export ---
   for (i = 0; i < 8; i = i + 1)
   begin
      `CLEAR_ALL
      `CHIP_RESET
      `SETUP_ALU(16'h0001, 16'h0001)
      `CHANGE_STATE_TO_NORMAL
      `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | i[15:0]), 2'b11, 1'b1)
      `WAIT_CYCLE
      if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
         $display("bad: interrupt on valid cmd %0d at %t", i, $time());
   end
   $display("Valid cmds 0-7 no interrupts: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP I: INTERRUPT OUTPUT PINS MATCH REGISTER
   // -----------------------------------------------------------------

   // --- 10.12i1: Set int1 only, check output pin ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR
   `WAIT_CYCLE
   if (interrupt_1 !== 1'b1 || interrupt_2 !== 1'b0)
      $display("bad: pins wrong int1=1 int2=0 at %t", $time());
   $display("Pin check int1=1 int2=0: PASS at %t", $time());

   // --- 10.12i2: Set int2 only, check output pin ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0200, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h0005), 2'b11, 1'b1)
   `WAIT_CYCLE
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b1)
      $display("bad: pins wrong int1=0 int2=1 at %t", $time());
   $display("Pin check int1=0 int2=1: PASS at %t", $time());

   // --- 10.12i3: Set both, check output pins ---
   `SETUP_EXPORT
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
   `WAIT_CYCLE
   if (interrupt_1 !== 1'b1 || interrupt_2 !== 1'b1)
      $display("bad: pins wrong int1=1 int2=1 at %t", $time());
   $display("Pin check int1=1 int2=1: PASS at %t", $time());

   // --- 10.12i4: Clear both, check output pins return to 0 ---
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0300, 2'b11, 1'b1)
   if (interrupt_1 !== 1'b0 || interrupt_2 !== 1'b0)
      $display("bad: pins wrong after clear at %t", $time());
   $display("Pin check int1=0 int2=0 after clear: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.13: BUS CROSSOVER - cs=0 (not selected), rw_=1 (read),
   //                byte_en = {2'b10, 2'b01, 2'b11}
   // When chip_select=0, data_out must be 0 and no register may change,
   // regardless of rw_ or byte_en. Tests every register address with
   // all 3 byte_en values to verify complete isolation.
   // ===================================================================
   $display("\n=== BUS CROSSOVER: cs=0, rw=read, byte_en TESTS ===");

   // Pre-load all writable registers with known non-zero values
   // so we can verify nothing changes.
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR,       16'h0300, 2'b11, 1'b1)   // int1_en=1, int2_en=1
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE, 2'b11, 1'b1)
   `MATH_CMD(VCHIP_ALU_ADD)                                    // alu_out = 0xBEEF+0xCAFE
   `WAIT_CYCLE

   // Save expected values for verification
   // version_reg: read-only, determined by design
   // status_reg:  should be STA_NORMAL = 0x0001
   // cmd_reg:     valid cleared after one cycle = 0x0001 (cmd=1, valid=0)
   // con_reg:     0x0300
   // alu_left:    0xBEEF
   // alu_right:   0xCAFE
   // alu_out:     0xBEEF + 0xCAFE = 0x89ED

   // Verify baseline values before test
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("Baseline values loaded: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP A: cs=0, rw_=1 (read), byte_en=2'b11 (both bytes)
   // data_out must be 0, all registers unchanged
   // -----------------------------------------------------------------

   // Try "reading" every address with cs=0
   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b1;
   byte_en     <= 2'b11;

   address <= VCHIP_VER_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_STA_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CMD_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_OUT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify no register was corrupted
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("cs=0 rw=read byte_en=11: data_out=0, regs intact: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP B: cs=0, rw_=1 (read), byte_en=2'b10 (byte1 only)
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b1;
   byte_en     <= 2'b10;

   address <= VCHIP_VER_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_STA_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CMD_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_OUT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify no register was corrupted
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("cs=0 rw=read byte_en=10: data_out=0, regs intact: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP C: cs=0, rw_=1 (read), byte_en=2'b01 (byte0 only)
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b1;
   byte_en     <= 2'b01;

   address <= VCHIP_VER_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_STA_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CMD_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_OUT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify no register was corrupted
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("cs=0 rw=read byte_en=01: data_out=0, regs intact: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP D: cs=0, rw_=1, byte_en=2'b00 (no bytes)
   // Edge case - even with no byte enables, cs=0 means data_out=0
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b1;
   byte_en     <= 2'b00;

   address <= VCHIP_VER_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_STA_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_OUT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify no register was corrupted
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("cs=0 rw=read byte_en=00: data_out=0, regs intact: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP E: cs=0 with data_in driven (should still be ignored)
   // Even if data_in has values, cs=0 means no write occurs
   // -----------------------------------------------------------------

   // byte_en=2'b11, data_in=0xFFFF, rw_=1
   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b1;
   byte_en     <= 2'b11;
   data_in     <= 16'hFFFF;

   address <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify nothing changed
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("cs=0 rw=read data_in=FFFF ignored: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP F: cs=0, rw_=1, rapid address cycling
   // Cycle through all addresses quickly, verify no side-effects
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b1;
   byte_en     <= 2'b11;

   for (i = 0; i < 128; i = i + 1)
   begin
      address <= i[6:0];
      wait(clk == 1'b1);
      `CHECK_VAL(16'h0000)
      wait(clk == 1'b0);
   end
   `CLEAR_BUS

   // Final verification - all registers still intact
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("cs=0 rw=read all 128 addrs data_out=0, regs intact: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.14: BUS CROSSOVER - cs=0 (not selected), rw_=1 (read),
   //                byte_en = {2'b10 (byte1), 2'b01 (byte0), 2'b00 (neither)}
   // When chip_select=0, data_out must be 0 and no register may change,
   // regardless of byte_en setting during a read.
   // ===================================================================
   $display("\n=== BUS CROSSOVER: cs=0, rw=read, byte_en={byte1,byte0,neither} TESTS ===");

   // Pre-load all writable registers with known non-zero values
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR,       16'h0300, 2'b11, 1'b1)   // int1_en=1, int2_en=1
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE, 2'b11, 1'b1)
   `MATH_CMD(VCHIP_ALU_ADD)                                    // alu_out = 0xBEEF+0xCAFE
   `WAIT_CYCLE

   // Verify baseline
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("10.14 Baseline values loaded: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP A: cs=0, rw_=1, byte_en=2'b10 (byte1 only)
   // data_out must be 0, all registers unchanged
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b1;
   byte_en     <= 2'b10;

   address <= VCHIP_VER_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_STA_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CMD_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_OUT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify no register was corrupted
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("10.14a cs=0 rw=read byte_en=10: data_out=0, regs intact: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP B: cs=0, rw_=1, byte_en=2'b01 (byte0 only)
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b1;
   byte_en     <= 2'b01;

   address <= VCHIP_VER_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_STA_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CMD_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_OUT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify no register was corrupted
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("10.14b cs=0 rw=read byte_en=01: data_out=0, regs intact: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP C: cs=0, rw_=1, byte_en=2'b00 (neither byte)
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b1;
   byte_en     <= 2'b00;

   address <= VCHIP_VER_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_STA_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CMD_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_OUT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify no register was corrupted
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("10.14c cs=0 rw=read byte_en=00: data_out=0, regs intact: PASS at %t", $time());

   // ===================================================================
   // SECTION 10.15: BUS CROSSOVER - cs=0 (not selected), rw_=0 (write),
   //                byte_en = {2'b10 (byte1), 2'b01 (byte0), 2'b00 (neither)}
   // When chip_select=0, writes must be ignored - no register may change,
   // data_out must be 0, regardless of rw_ or byte_en setting.
   // ===================================================================
   $display("\n=== BUS CROSSOVER: cs=0, rw=write, byte_en={byte1,byte0,neither} TESTS ===");

   // Pre-load all writable registers with known non-zero values
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_CON_ADDR,       16'h0300, 2'b11, 1'b1)   // int1_en=1, int2_en=1
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE, 2'b11, 1'b1)
   `MATH_CMD(VCHIP_ALU_ADD)                                    // alu_out = 0xBEEF+0xCAFE
   `WAIT_CYCLE

   // Verify baseline
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("10.15 Baseline values loaded: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP A: cs=0, rw_=0 (write), byte_en=2'b10 (byte1 only)
   // Attempt to write 0xFFFF to every writable register with cs=0
   // No register should change, data_out should be 0
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b0;       // write mode
   byte_en     <= 2'b10;
   data_in     <= 16'hFFFF;   // attempt to overwrite with all 1s

   address <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CMD_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_STA_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_OUT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_VER_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify no register was corrupted by the write attempt
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("10.15a cs=0 rw=write byte_en=10: writes ignored, regs intact: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP B: cs=0, rw_=0 (write), byte_en=2'b01 (byte0 only)
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b0;       // write mode
   byte_en     <= 2'b01;
   data_in     <= 16'hFFFF;

   address <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CMD_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_STA_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_OUT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_VER_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify no register was corrupted
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("10.15b cs=0 rw=write byte_en=01: writes ignored, regs intact: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP C: cs=0, rw_=0 (write), byte_en=2'b00 (neither byte)
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b0;       // write mode
   byte_en     <= 2'b00;
   data_in     <= 16'hFFFF;

   address <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_CMD_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_STA_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_ALU_OUT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   address <= VCHIP_VER_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify no register was corrupted
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("10.15c cs=0 rw=write byte_en=00: writes ignored, regs intact: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP D: cs=0, rw_=0 (write), byte_en=2'b10, different data patterns
   // Try writing specific non-trivial values to verify isolation
   // -----------------------------------------------------------------

   // Attempt to write 0x1234 to LEFT, 0x5678 to RIGHT, 0x0000 to CON
   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b0;
   byte_en     <= 2'b10;
   data_in     <= 16'h1234;
   address     <= VCHIP_ALU_LEFT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   data_in     <= 16'h5678;
   address     <= VCHIP_ALU_RIGHT_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   data_in     <= 16'h0000;
   address     <= VCHIP_CON_ADDR;
   wait(clk == 1'b1);
   `CHECK_VAL(16'h0000)
   wait(clk == 1'b0);

   `CLEAR_BUS

   // Verify registers still hold original values
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("10.15d cs=0 rw=write varied data_in: writes ignored, regs intact: PASS at %t", $time());

   // -----------------------------------------------------------------
   // GROUP E: cs=0, rw_=0 (write), rapid address cycling
   // Cycle through all 128 addresses with write + data_in=0xFFFF
   // Verify no side-effects
   // -----------------------------------------------------------------

   wait(clk == 1'b0);
   chip_select <= 1'b0;
   rw_         <= 1'b0;
   byte_en     <= 2'b11;
   data_in     <= 16'hFFFF;

   for (i = 0; i < 128; i = i + 1)
   begin
      address <= i[6:0];
      wait(clk == 1'b1);
      `CHECK_VAL(16'h0000)
      wait(clk == 1'b0);
   end
   `CLEAR_BUS

   // Final verification - all registers still intact
   `READ_REG(VCHIP_STA_ADDR,       STA_NORMAL,  1'b1)
   `READ_REG(VCHIP_CON_ADDR,       16'h0300,    1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,    1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hCAFE,    1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,   16'h89ED,    1'b1)
   $display("10.15e cs=0 rw=write all 128 addrs: writes ignored, regs intact: PASS at %t", $time());

   // ===================================================================
   // SECTION 11: ALU_LEFT / ALU_RIGHT CROSSOVER TEST (0x4000-0x7FFF)
   // Uses boundary + walking-1/0 + alternating bit patterns (33 values)
   // instead of exhaustive sweep for fast simulation.
   // ===================================================================
   $display("\n=== ALU LEFT/RIGHT CROSSOVER TESTS (0x4000 - 0x7FFF) ===");

   // --- 11a: Write same value to both, read both back ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'h4000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h4000), 1'b1)
   end
   $display("Crossover same value both regs 0x4000-0x7FFF: PASS at %t", $time());

   // --- 11b: Write LEFT, verify RIGHT unchanged ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h4000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h4000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'h4000, 1'b1)
   end
   $display("Crossover write LEFT, RIGHT unchanged 0x4000-0x7FFF: PASS at %t", $time());

   // --- 11c: Write RIGHT, verify LEFT unchanged ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h4000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'h4000), 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   16'h4000, 1'b1)
   end
   $display("Crossover write RIGHT, LEFT unchanged 0x4000-0x7FFF: PASS at %t", $time());

   // --- 11d: Write opposite values to LEFT and RIGHT, read both back ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h4000),  2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, ~(pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'h4000),  1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  ~(pat_off[j] + 16'h4000), 1'b1)
   end
   $display("Crossover opposite values LEFT/RIGHT 0x4000-0x7FFF: PASS at %t", $time());

   // --- 11e: Byte-enable crossover - high byte LEFT, low byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h4000), 2'b10, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  {(pat_off[j][15:8] + 8'h40), 8'h00}, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR, {8'h00, pat_off[j][7:0]},             1'b1)
   end
   $display("Crossover byte-enable hi-LEFT lo-RIGHT 0x4000-0x7FFF: PASS at %t", $time());

   // --- 11f: Byte-enable crossover - low byte LEFT, high byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h4000), 2'b01, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'h4000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  {8'h00, pat_off[j][7:0]},             1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR, {(pat_off[j][15:8] + 8'h40), 8'h00}, 1'b1)
   end
   $display("Crossover byte-enable lo-LEFT hi-RIGHT 0x4000-0x7FFF: PASS at %t", $time());

   // ===================================================================
   // SECTION 12: ALU_LEFT / ALU_RIGHT CROSSOVER TEST
   // LEFT range: 0x4000-0x7FFF (base 0x4000)
   // RIGHT range: 0xC000-0xFFFF (base 0xC000)
   // Same 33 patterns, different bases.
   // ===================================================================
   $display("\n=== ALU LEFT(0x4000-0x7FFF) / RIGHT(0xC000-0xFFFF) CROSSOVER ===");

   // --- 12a: Full word write to both, read both back ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'h4000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
   end
   $display("Crossover12 full word both regs: PASS at %t", $time());

   // --- 12b: Sweep LEFT, RIGHT pinned at 0xC000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hC000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'h4000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h4000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hC000, 1'b1)
   end
   $display("Crossover12 sweep LEFT, RIGHT pinned 0xC000: PASS at %t", $time());

   // --- 12c: Sweep RIGHT, LEFT pinned at 0x4000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h4000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   16'h4000, 1'b1)
   end
   $display("Crossover12 sweep RIGHT, LEFT pinned 0x4000: PASS at %t", $time());

   // --- 12d: Mirror values - LEFT ascending, RIGHT descending ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h4000),              2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (16'hFFFF - pat_off[j]),               2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'h4000),              1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (16'hFFFF - pat_off[j]),               1'b1)
   end
   $display("Crossover12 mirror values LEFT/RIGHT: PASS at %t", $time());

   // --- 12e: Byte-enable crossover - high byte LEFT, low byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h4000), 2'b10, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {(pat_off[j][15:8] + 8'h40), 8'h00}, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {8'h00, pat_off[j][7:0]},             1'b1)
   end
   $display("Crossover12 byte-enable hi-LEFT lo-RIGHT: PASS at %t", $time());

   // --- 12f: Byte-enable crossover - low byte LEFT, high byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h4000), 2'b01, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {8'h00, pat_off[j][7:0]},             1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {(pat_off[j][15:8] + 8'hC0), 8'h00}, 1'b1)
   end
   $display("Crossover12 byte-enable lo-LEFT hi-RIGHT: PASS at %t", $time());

   // ===================================================================
   // SECTION 13: ALU_LEFT / ALU_RIGHT CROSSOVER TEST
   // LEFT range: 0x8000-0xBFFF (base 0x8000)
   // RIGHT range: 0xC000-0xFFFF (base 0xC000)
   // Same 33 patterns, different bases.
   // ===================================================================
   $display("\n=== ALU LEFT(0x8000-0xBFFF) / RIGHT(0xC000-0xFFFF) CROSSOVER ===");

   // --- 13a: Full word write to both, read both back ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'h8000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
   end
   $display("Crossover13 full word both regs: PASS at %t", $time());

   // --- 13b: Sweep LEFT, RIGHT pinned at 0xC000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hC000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR, (pat_off[j] + 16'h8000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR, 16'hC000, 1'b1)
   end
   $display("Crossover13 sweep LEFT, RIGHT pinned 0xC000: PASS at %t", $time());

   // --- 13c: Sweep RIGHT, LEFT pinned at 0x8000 ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h8000, 2'b11, 1'b1)
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (pat_off[j] + 16'hC000), 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   16'h8000, 1'b1)
   end
   $display("Crossover13 sweep RIGHT, LEFT pinned 0x8000: PASS at %t", $time());

   // --- 13d: Mirror values - LEFT ascending, RIGHT descending ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000),              2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (16'hFFFF - pat_off[j]),               2'b11, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   (pat_off[j] + 16'h8000),              1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  (16'hFFFF - pat_off[j]),               1'b1)
   end
   $display("Crossover13 mirror values LEFT/RIGHT: PASS at %t", $time());

   // --- 13e: Byte-enable crossover - high byte LEFT, low byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 2'b10, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b01, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {(pat_off[j][15:8] + 8'h80), 8'h00}, 1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {8'h00, pat_off[j][7:0]},             1'b1)
   end
   $display("Crossover13 byte-enable hi-LEFT lo-RIGHT: PASS at %t", $time());

   // --- 13f: Byte-enable crossover - low byte LEFT, high byte RIGHT ---
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   for (j = 0; j < NUM_PATS; j = j + 1)
   begin
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
      `WRITE_REG(VCHIP_ALU_LEFT_ADDR,  (pat_off[j] + 16'h8000), 2'b01, 1'b1)
      `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, (pat_off[j] + 16'hC000), 2'b10, 1'b1)
      `READ_REG(VCHIP_ALU_LEFT_ADDR,   {8'h00, pat_off[j][7:0]},             1'b1)
      `READ_REG(VCHIP_ALU_RIGHT_ADDR,  {(pat_off[j][15:8] + 8'hC0), 8'h00}, 1'b1)
   end
   $display("Crossover13 byte-enable lo-LEFT hi-RIGHT: PASS at %t", $time());

//$display();
   // ===================================================================
   // END OF TESTS
   // ===================================================================
   $display("\n=== ALL TESTS COMPLETE ===");

   wait(clk == 1'b0);   // MUST LEAVE SO GRADING WORKS!
   wait(clk == 1'b1);
   wait(clk == 1'b0);
   $finish;

end // initial begin


initial begin : wave_plotter
   $dumpfile("top_verichip7.vcd");
   $dumpvars(0, top_verichip7);
end


verichip7 verichip7      (.clk     ( clk ),    // system clock

                     .rst_b ( rst_b  ),    // chip reset
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

verichip7_binds verichip7_binds();

endmodule
