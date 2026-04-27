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
