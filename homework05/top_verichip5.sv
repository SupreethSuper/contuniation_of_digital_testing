// // `timescale 1ns/1ps

// // `define SET_WRITE(addr,val,bytes,cs)   \
// //    rw_ <= 1'b0;                     \
// //    chip_select <= cs;               \
// //    byte_en <= bytes;                \
// //    address <= addr;                 \
// //    data_in <= val; 

// // `define SET_READ(addr,cs)           \
// //    rw_ <= 1'b1;                     \
// //    chip_select <= cs;               \
// //    byte_en <= 2'b00;                \
// //    address <= addr;                 \
// //    data_in <= 16'h0;

// // `define CLEAR_BUS                   \
// //    chip_select    <= 1'b0;          \
// //    address        <= 7'h0;          \
// //    byte_en        <= 2'h0;          \
// //    rw_            <= 1'b1;          \
// //    data_in        <= 16'h0; 

// // `define CLEAR_ALL                   \
// //    export_disable <= 1'b0;          \
// //    maroon         <= 1'b0;          \
// //    gold           <= 1'b0;          \
// //    `CLEAR_BUS


// // `define STATE_RESET_TO_NORMAL               \
// //    maroon <= 1'b0;                           \
// //    gold <= 1'b0;


// // `define STATE_ErRoR_TO_NORMAL               \
// //    maroon <= 1'b1;                           \
// //    gold <= 1'b0;


   


// // `define CHECK_VAL(val)              \
// //    if ( data_out != val )           \
// //        $display("bad read, got %h but expected %h at %t",data_out,val,$time());

// // `define CHECK_RW(addr,wval,rval,bytes,cs)    \
// //    `WRITE_REG(addr,wval,bytes,cs)            \
// //    `READ_REG(addr,rval,cs)

// // `define CHIP_RESET                  \
// //    wait( clk == 1'b0 );             \
// //    rst_b <= 1'b0;                   \
// //    wait( clk == 1'b1 );             \
// //    rst_b <= 1'b1;


// // `define STATE_RESET                        \
// //          `CHIP_RESET

// // `define WAIT_TIME                                 \
// //    #10;



// // `define STATE_TESTER (val)                               \
// // `SET_WRITE(7'h10,16'h0001,2'b11,1'b1)                    \
// //    `WAIT_TIME                                           \
// //    `SET_READ(7'h10,1'b1)                                 \
// //    `WAIT_TIME                                           \
// //    `CHECK_VAL(16'h0001)                                 \
// //    `WAIT_TIME                                           
   
// //    //write to alu right and read from alu right
// //    `SET_WRITE(7'h14,16'h0002,2'b11,1'b1)                 \
// //    `WAIT_TIME                                           \
// //    `SET_READ(7'h14,1'b1)                                  \
// //    `WAIT_TIME                                           \
// //    `CHECK_VAL(16'h0002)                                 \
// //    `WAIT_TIME                                           

// //    //perform add operation
// //    `SET_WRITE(7'h08,16'h0001,2'b11,1'b1)                 \
// //    `WAIT_TIME                                           \
// //    `SET_READ(7'h18,1'b1)                                \
// //    `WAIT_TIME                                           \
// //    `CHECK_VAL(val)                                     \ //confirms that we are in reset state
// //    `WAIT_TIME                                           



// // `define EXPORT_STATE                                  \
// //    `CLEAR_ALL                                         \
// //    `WAIT_TIME                                         \
// //    `CHIP_RESET                                        \
// //    `WAIT_TIME                                         \
// //    `STATE_RESET_TO_NORMAL                             \
// //    `WAIT_TIME                                         \
// //    `SET_WRITE(7'h08,16'h8003,2'b11,1'b1)              \
// //    `WAIT_TIME                                         \
// //    `CLEAR_BUS                                         \
// //    `WAIT_TIME                                         \
// //    `SET_WRITE(7'h10,16'hFFFF,2'b11,1'b1)              \
// //    `CLEAR_BUS                                         \
// //    `SET_READ(7'h10,1'b1)                               \
// //    `WAIT_TIME                                         \
// //    `WAIT_TIME                                         \
// //    `CHECK_VAL(16'h0000)                               \
// //    `WAIT_TIME                                         \
// //    `CLEAR_BUS                                         

// // module top_verichip5 ();

// // logic clk;                       // system clock
// // logic rst_b;                     // chip reset
// // logic export_disable;            // disable features
// // logic interrupt_1;               // first interrupt
// // logic interrupt_2;               // second interrupt

// // logic maroon;                    // maroon state machine input
// // logic gold;                      // gold state machine input

// // logic chip_select;               // target of r/w
// // logic [6:0] address;             // address bus
// // logic [1:0] byte_en;             // write byte enables
// // logic       rw_;                 // read/write
// // logic [15:0] data_in;            // input data bus

// // logic [15:0] data_out;           // output data bus

// // localparam VCHIP_VER_ADDR       = 7'h00;
// // localparam VCHIP_STA_ADDR       = 7'h04;
// // localparam VCHIP_CMD_ADDR       = 7'h08;
// // localparam VCHIP_CON_ADDR       = 7'h0C;
// // localparam VCHIP_ALU_LEFT_ADDR  = 7'h10;
// // localparam VCHIP_ALU_RIGHT_ADDR = 7'h14;
// // localparam VCHIP_ALU_OUT_ADDR   = 7'h18;

// // localparam VCHIP_ALU_VALID = 16'h8000;
// // localparam VCHIP_ALU_ADD   = 16'h0001;
// // localparam VCHIP_ALU_SUB   = 16'h0002;
// // localparam VCHIP_ALU_MVL   = 16'h0003;
// // localparam VCHIP_ALU_MVR   = 16'h0004;
// // localparam VCHIP_ALU_SWA   = 16'h0005;
// // localparam VCHIP_ALU_SHL   = 16'h0006;
// // localparam VCHIP_ALU_SHR   = 16'h0007;

// // localparam ONE = 1'b1;
// // localparam ZERO = 1'b0;


// // initial begin


// // //-----------------start of hw5-------------------------------------------



// //    //verifying in reset state
// //    $display("\n\nverifying in reset state\n\n");
// //    `CLEAR_ALL
// //    `STATE_RESET
// //    `WAIT_TIME
// //    `STATE_TESTER(16'h0000)

// //    //verifying how to get from reset to Normal state
// //    $display("\n\nverifying how to get from reset to Normal state\n\n");
// //    `CLEAR_ALL
// //    `CHIP_RESET
// //    `WAIT_TIME
// //    `STATE_RESET_TO_NORMAL
// //    `WAIT_TIME
// //    `STATE_TESTER(16'h0001)


// //    //verifying how to get from Normal to Export violation
// //    `CLEAR_ALL
// //    `CHIP_RESET
// //    `WAIT_TIME
// //    `STATE_RESET_TO_NORMAL
// //    `WAIT_TIME
// //    `EXPORT_STATE
   
// // //-------------------PUSH FOR INITIAL TEST -----------------------------------------------
// // //==================CHNAGES TO BE MADE AFTER TEST 1=====================================

// // //address in `defines added raw

// // //============================XXXXXXXXXXXXX=================================================
   


// //    #5 $finish;
// // end // initial begin


// // verichip5 verichip5 (.clk           ( clk            ),    // system clock
// //                    .rst_b         ( rst_b          ),    // chip reset
// //                    .export_disable( export_disable ),    // disable features
// //                    .interrupt_1   ( interrupt_1    ),    // first interrupt
// //                    .interrupt_2   ( interrupt_2    ),    // second interrupt
 
// //                    .maroon        ( maroon         ),    // maroon state machine input
// //                    .gold          ( gold           ),    // gold state machine input

// //                    .chip_select   ( chip_select    ),    // target of r/w
// //                    .address       ( address        ),    // address bus
// //                    .byte_en       ( byte_en        ),    // write byte enables
// //                    .rw_           ( rw_            ),    // read/write
// //                    .data_in       ( data_in        ),    // data bus

// //                    .data_out      ( data_out       ) );  // output data bus

// // initial 
// // begin
// //     $dumpfile("verichip.vcd");
// //     $dumpvars(0,top_verichip5);
// // end

// // endmodule



// `timescale 1ns/1ps

// // ---------------------------------------------------------------------------
// // Bus primitives
// // ---------------------------------------------------------------------------

// `define SET_WRITE(addr,val,bytes,cs)   \
//    rw_          <= 1'b0;              \
//    chip_select  <= cs;                \
//    byte_en      <= bytes;             \
//    address      <= addr;              \
//    data_in      <= val;

// `define SET_READ(addr,cs)              \
//    rw_          <= 1'b1;              \
//    chip_select  <= cs;                \
//    byte_en      <= 2'b00;             \
//    address      <= addr;              \
//    data_in      <= 16'h0;

// `define CLEAR_BUS                      \
//    chip_select  <= 1'b0;              \
//    address      <= 7'h0;              \
//    byte_en      <= 2'h0;              \
//    rw_          <= 1'b1;              \
//    data_in      <= 16'h0;

// `define CLEAR_ALL                      \
//    export_disable <= 1'b0;            \
//    maroon         <= 1'b0;            \
//    gold           <= 1'b0;            \
//    `CLEAR_BUS

// // ---------------------------------------------------------------------------
// // State machine control inputs
// // ---------------------------------------------------------------------------

// // maroon=0, gold=1  =>  !maroon && gold  =>  Reset -> Normal
// `define STATE_RESET_TO_NORMAL          \
//    maroon <= 1'b0;                    \
//    gold   <= 1'b1;

// // maroon=1, gold=0  =>  ErRoR -> Normal handshake (step 1)
// `define STATE_ErRoR_TO_NORMAL          \
//    maroon <= 1'b1;                    \
//    gold   <= 1'b0;

// // ---------------------------------------------------------------------------
// // Checking / register access helpers
// // ---------------------------------------------------------------------------

// `define CHECK_VAL(val)                 \
//    if ( data_out !== val )            \
//       $display("FAIL: got %h but expected %h at %t", data_out, val, $time());

// `define WRITE_REG(addr,val,bytes,cs)   \
//    @(negedge clk);                    \
//    `SET_WRITE(addr,val,bytes,cs)      \
//    @(posedge clk);

// `define READ_REG(addr,val,cs)          \
//    @(negedge clk);                    \
//    `SET_READ(addr,cs)                 \
//    @(posedge clk);                    \
//    `CHECK_VAL(val)

// `define CHECK_RW(addr,wval,rval,bytes,cs) \
//    `WRITE_REG(addr,wval,bytes,cs)         \
//    `READ_REG(addr,rval,cs)

// // ---------------------------------------------------------------------------
// // Clock / reset helpers
// // ---------------------------------------------------------------------------

// `define CLK_WAIT                       \
//    @(posedge clk);

// `define CHIP_RESET                     \
//    @(negedge clk);                    \
//    rst_b <= 1'b0;                     \
//    @(posedge clk);                    \
//    @(negedge clk);                    \
//    rst_b <= 1'b1;                     \
//    @(posedge clk);

// // ---------------------------------------------------------------------------
// // STATE_TESTER: write LEFT=1, RIGHT=2, issue ADD, read ALU_OUT
// //   Reset state  => ALU ignored => ALU_OUT stays 0  => pass val=16'h0000
// //   Normal state => ADD executes => ALU_OUT = 3     => pass val=16'h0003
// // ---------------------------------------------------------------------------
// `define STATE_TESTER(val)                             \
//    @(negedge clk);                                   \
//    `SET_WRITE(7'h10, 16'h0001, 2'b11, 1'b1)          \
//    @(posedge clk);                                   \
//    @(negedge clk);                                   \
//    `SET_READ(7'h10, 1'b1)                             \
//    @(posedge clk);                                   \
//    `CHECK_VAL(16'h0001)                              \
//    @(negedge clk);                                   \
//    `SET_WRITE(7'h14, 16'h0002, 2'b11, 1'b1)          \
//    @(posedge clk);                                   \
//    @(negedge clk);                                   \
//    `SET_READ(7'h14, 1'b1)                             \
//    @(posedge clk);                                   \
//    `CHECK_VAL(16'h0002)                              \
//    @(negedge clk);                                   \
//    `SET_WRITE(7'h08, 16'h8001, 2'b11, 1'b1)          \
//    @(posedge clk);                                   \
//    `CLK_WAIT                                         \
//    @(negedge clk);                                   \
//    `SET_READ(7'h18, 1'b1)                             \
//    @(posedge clk);                                   \
//    `CHECK_VAL(val)

// // ---------------------------------------------------------------------------
// // EXPORT_STATE: set export_disable, write LEFT, issue SHL => Export Violation
// //   then verify LED register has been reset to 0
// // ---------------------------------------------------------------------------
// `define EXPORT_STATE                                  \
//    @(negedge clk);                                   \
//    export_disable <= 1'b1;                           \
//    `SET_WRITE(7'h10, 16'h1234, 2'b11, 1'b1)          \
//    @(posedge clk);                                   \
//    @(negedge clk);                                   \
//    `CLEAR_BUS                                        \
//    @(posedge clk);                                   \
//    @(negedge clk);                                   \
//    `SET_WRITE(7'h08, 16'h8006, 2'b11, 1'b1)          \
//    @(posedge clk);                                   \
//    @(negedge clk);                                   \
//    `CLEAR_BUS                                        \
//    @(posedge clk);                                   \
//    `CLK_WAIT                                         \
//    @(negedge clk);                                   \
//    `SET_READ(7'h10, 1'b1)                             \
//    @(posedge clk);                                   \
//    `CHECK_VAL(16'h0000)                              \
//    @(negedge clk);                                   \
//    `CLEAR_BUS

// // ---------------------------------------------------------------------------
// // FSM test helpers (new for hw03 Prof. Milman 6-case requirement)
// // ---------------------------------------------------------------------------

// // Read Status register bits[3:0] and compare against expected FSM state
// `define READ_STATUS(expected_state)    \
//    @(negedge clk);                    \
//    `SET_READ(7'h04, 1'b1)             \
//    @(posedge clk);                    \
//    if (data_out[3:0] !== expected_state) \
//       $display("FSM MISMATCH: got state %0h expected %0h at %t", \
//                data_out[3:0], expected_state, $time()); \
//    @(negedge clk);                    \
//    `CLEAR_BUS                         \
//    @(posedge clk);

// // Issue an illegal/reserved command (CMD=4'hA, Valid=1)
// `define ISSUE_BAD_CMD                  \
//    @(negedge clk);                    \
//    `SET_WRITE(7'h08, 16'h800A, 2'b11, 1'b1) \
//    @(posedge clk);                    \
//    @(negedge clk);                    \
//    `CLEAR_BUS                         \
//    @(posedge clk);                    \
//    `CLK_WAIT

// // Issue an export-violation command (export_disable=1 + SHL command)
// `define ISSUE_EXPVIO_CMD               \
//    @(negedge clk);                    \
//    export_disable <= 1'b1;            \
//    `SET_WRITE(7'h08, 16'h8006, 2'b11, 1'b1) \
//    @(posedge clk);                    \
//    @(negedge clk);                    \
//    export_disable <= 1'b0;            \
//    `CLEAR_BUS                         \
//    @(posedge clk);                    \
//    `CLK_WAIT

// // Full chip reset then transition into Normal state cleanly
// // Deassert gold after transition so it does not linger into subsequent steps
// `define GOTO_NORMAL                    \
//    `CLEAR_ALL                         \
//    `CHIP_RESET                        \
//    @(negedge clk);                    \
//    `STATE_RESET_TO_NORMAL             \
//    @(posedge clk);                    \
//    `CLK_WAIT                          \
//    @(negedge clk);                    \
//    maroon <= 1'b0; gold <= 1'b0;      \
//    @(posedge clk);                    \
//    `CLK_WAIT

// // Put chip into ErRoR state from Normal (bad command)
// `define GOTO_ErRoR                     \
//    `GOTO_NORMAL                       \
//    `ISSUE_BAD_CMD

// // Put chip into Export Violation state from Normal
// `define GOTO_EXPVIO                    \
//    `GOTO_NORMAL                       \
//    `ISSUE_EXPVIO_CMD

// // ---------------------------------------------------------------------------
// // Module
// // ---------------------------------------------------------------------------

// module top_verichip5 ();

// logic clk;
// logic rst_b;
// logic export_disable;
// logic interrupt_1;
// logic interrupt_2;

// logic maroon;
// logic gold;

// logic chip_select;
// logic [6:0] address;
// logic [1:0] byte_en;
// logic       rw_;
// logic [15:0] data_in;
// logic [15:0] data_out;

// localparam VCHIP_VER_ADDR       = 7'h00;
// localparam VCHIP_STA_ADDR       = 7'h04;
// localparam VCHIP_CMD_ADDR       = 7'h08;
// localparam VCHIP_CON_ADDR       = 7'h0C;
// localparam VCHIP_ALU_LEFT_ADDR  = 7'h10;
// localparam VCHIP_ALU_RIGHT_ADDR = 7'h14;
// localparam VCHIP_ALU_OUT_ADDR   = 7'h18;

// localparam VCHIP_ALU_VALID = 16'h8000;
// localparam VCHIP_ALU_ADD   = 16'h0001;
// localparam VCHIP_ALU_SUB   = 16'h0002;
// localparam VCHIP_ALU_MVL   = 16'h0003;
// localparam VCHIP_ALU_MVR   = 16'h0004;
// localparam VCHIP_ALU_SWA   = 16'h0005;
// localparam VCHIP_ALU_SHL   = 16'h0006;
// localparam VCHIP_ALU_SHR   = 16'h0007;

// localparam ONE  = 1'b1;
// localparam ZERO = 1'b0;

// // FSM state encodings (Status register bits [3:0])
// localparam FSM_RESET  = 4'h0;
// localparam FSM_NORMAL = 4'h1;
// localparam FSM_ErRoR  = 4'h2;
// localparam FSM_EXPVIO = 4'h8;

// // Clock generation
// initial clk = 0;
// always #5 clk = ~clk;

// // ---------------------------------------------------------------------------
// // Test program
// // ---------------------------------------------------------------------------
// initial begin

//    // Initialise all signals
//    `CLEAR_ALL
//    rst_b <= 1'b1;
//    @(posedge clk);

//    // =========================================================================
//    // ORIGINAL hw03 smoke tests (preserved)
//    // =========================================================================

//    $display("\n\nVerifying in Reset state\n\n");
//    `CLEAR_ALL
//    `CHIP_RESET
//    `STATE_TESTER(16'h0000)

//    $display("\n\nVerifying Reset -> Normal state transition\n\n");
//    `CLEAR_ALL
//    `CHIP_RESET
//    @(negedge clk);
//    `STATE_RESET_TO_NORMAL
//    @(posedge clk);
//    `CLK_WAIT
//    `STATE_TESTER(16'h0003)

//    $display("\n\nVerifying Normal -> Export Violation state\n\n");
//    `CLEAR_ALL
//    `CHIP_RESET
//    @(negedge clk);
//    `STATE_RESET_TO_NORMAL
//    @(posedge clk);
//    `CLK_WAIT
//    `EXPORT_STATE

//    // =========================================================================
//    // FSM STATE TESTS  (Prof. Milman: 6 cases per state)
//    //
//    // The 6 inputs tested in every state are:
//    //   1. maroon=0, gold=0   (no transition signal)
//    //   2. maroon=0, gold=1   (Reset->Normal signal)
//    //   3. maroon=1, gold=0   (ErRoR->Normal signal)
//    //   4. maroon=1, gold=1   (illegal combination)
//    //   5. Illegal command    (CMD=4'hA with Valid=1)
//    //   6. Export violation   (export_disable=1 + restricted CMD)
//    // =========================================================================

//    // -------------------------------------------------------------------------
//    // STATE: RESET  (FSM_RESET = 4'h0)
//    // -------------------------------------------------------------------------
//    $display("\n\n=== FSM TESTS: RESET STATE ===\n");

//    // R1: maroon=0 gold=0 in Reset => stays Reset
//    $display("R1: Reset + m=0 g=0 => stays Reset");
//    `CLEAR_ALL
//    `CHIP_RESET
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `READ_STATUS(FSM_RESET)

//    // R2: maroon=0 gold=1 in Reset => transitions to Normal
//    $display("R2: Reset + m=0 g=1 => Normal");
//    `CLEAR_ALL
//    `CHIP_RESET
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b1;
//    @(posedge clk);
//    `CLK_WAIT
//    `READ_STATUS(FSM_NORMAL)

//    // R3: maroon=1 gold=0 in Reset => stays Reset
//    // Only gold=1 triggers exit from Reset; maroon alone has no effect.
//    $display("R3: Reset + m=1 g=0 => stays Reset");
//    `CLEAR_ALL
//    `CHIP_RESET
//    `CLK_WAIT
//    `CLK_WAIT
//    @(negedge clk);
//    maroon <= 1'b1; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `CLK_WAIT
//    `READ_STATUS(FSM_RESET)

//    // R4: maroon=1 gold=1 in Reset => stays Reset (invalid combination)
//    $display("R4: Reset + m=1 g=1 => stays Reset");
//    `CLEAR_ALL
//    `CHIP_RESET
//    @(negedge clk);
//    maroon <= 1'b1; gold <= 1'b1;
//    @(posedge clk);
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `READ_STATUS(FSM_RESET)

//    // R5: Illegal command in Reset => stays Reset (commands ignored in Reset)
//    $display("R5: Reset + illegal cmd => stays Reset");
//    `CLEAR_ALL
//    `CHIP_RESET
//    `ISSUE_BAD_CMD
//    `READ_STATUS(FSM_RESET)

//    // R6: Export violation command in Reset => stays Reset (commands ignored)
//    $display("R6: Reset + export_disable + cmd => stays Reset");
//    `CLEAR_ALL
//    `CHIP_RESET
//    `ISSUE_EXPVIO_CMD
//    `READ_STATUS(FSM_RESET)

//    // -------------------------------------------------------------------------
//    // STATE: NORMAL  (FSM_NORMAL = 4'h1)
//    // -------------------------------------------------------------------------
//    $display("\n\n=== FSM TESTS: NORMAL STATE ===\n");

//    // N1: maroon=0 gold=0 in Normal => stays Normal
//    $display("N1: Normal + m=0 g=0 => stays Normal");
//    `GOTO_NORMAL
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `READ_STATUS(FSM_NORMAL)

//    // N2: maroon=0 gold=1 in Normal => stays Normal (already in Normal)
//    $display("N2: Normal + m=0 g=1 => stays Normal");
//    `GOTO_NORMAL
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b1;
//    @(posedge clk);
//    `CLK_WAIT
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `CLK_WAIT
//    `READ_STATUS(FSM_NORMAL)

//    // N3: maroon=1 gold=0 in Normal => stays Normal (ErRoR->Normal only from ErRoR)
//    $display("N3: Normal + m=1 g=0 => stays Normal");
//    `GOTO_NORMAL
//    @(negedge clk);
//    maroon <= 1'b1; gold <= 1'b0;
//    @(posedge clk);
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `READ_STATUS(FSM_NORMAL)

//    // N4: maroon=1 gold=1 in Normal => stays Normal (invalid combination)
//    $display("N4: Normal + m=1 g=1 => stays Normal");
//    `GOTO_NORMAL
//    @(negedge clk);
//    maroon <= 1'b1; gold <= 1'b1;
//    @(posedge clk);
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `READ_STATUS(FSM_NORMAL)

//    // N5: Illegal command in Normal => transitions to ErRoR
//    $display("N5: Normal + illegal cmd => ErRoR");
//    `GOTO_NORMAL
//    `ISSUE_BAD_CMD
//    `READ_STATUS(FSM_ErRoR)

//    // N6: Export violation command in Normal => transitions to Export Violation
//    $display("N6: Normal + export_disable + cmd => Export Violation");
//    `GOTO_NORMAL
//    `ISSUE_EXPVIO_CMD
//    `READ_STATUS(FSM_EXPVIO)

//    // -------------------------------------------------------------------------
//    // STATE: ErRoR  (FSM_ErRoR = 4'h2)
//    // -------------------------------------------------------------------------
//    $display("\n\n=== FSM TESTS: ErRoR STATE ===\n");

//    // E1: maroon=0 gold=0 in ErRoR => stays ErRoR
//    $display("E1: ErRoR + m=0 g=0 => stays ErRoR");
//    `GOTO_ErRoR
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `READ_STATUS(FSM_ErRoR)

//    // E2: maroon=0 gold=1 in ErRoR => DESIGN BUG: gold=1 triggers transition to Normal
//    // from any state. Testbench checks FSM_NORMAL to detect the bug.
//    $display("E2: ErRoR + m=0 g=1 => detects design bug (transitions to Normal)");
//    `GOTO_ErRoR
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b1;
//    @(posedge clk);
//    `CLK_WAIT
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `CLK_WAIT
//    `READ_STATUS(FSM_NORMAL)

//    // E3: maroon=1 gold=0 in ErRoR => transitions to Normal
//    $display("E3: ErRoR + m=1 g=0 => Normal");
//    `GOTO_ErRoR
//    @(negedge clk);
//    maroon <= 1'b1; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `CLK_WAIT
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `CLK_WAIT
//    `READ_STATUS(FSM_NORMAL)

//    // E4: maroon=1 gold=1 in ErRoR => stays ErRoR (invalid combination)
//    $display("E4: ErRoR + m=1 g=1 => stays ErRoR");
//    `GOTO_ErRoR
//    @(negedge clk);
//    maroon <= 1'b1; gold <= 1'b1;
//    @(posedge clk);
//    `CLK_WAIT
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `CLK_WAIT
//    `READ_STATUS(FSM_ErRoR)

//    // E5: Illegal command in ErRoR => stays ErRoR (writes are disabled)
//    $display("E5: ErRoR + illegal cmd => stays ErRoR");
//    `GOTO_ErRoR
//    `ISSUE_BAD_CMD
//    `READ_STATUS(FSM_ErRoR)

//    // E6: Export violation command in ErRoR => stays ErRoR (writes are disabled)
//    $display("E6: ErRoR + export_disable + cmd => stays ErRoR");
//    `GOTO_ErRoR
//    `ISSUE_EXPVIO_CMD
//    `READ_STATUS(FSM_ErRoR)

//    // -------------------------------------------------------------------------
//    // STATE: EXPORT VIOLATION  (FSM_EXPVIO = 4'h8)
//    // Only rst_b exits this state; all other inputs are ignored.
//    // -------------------------------------------------------------------------
//    $display("\n\n=== FSM TESTS: EXPORT VIOLATION STATE ===\n");

//    // X1: maroon=0 gold=0 in ExpVio => stays ExpVio
//    $display("X1: ExpVio + m=0 g=0 => stays ExpVio");
//    `GOTO_EXPVIO
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `READ_STATUS(FSM_EXPVIO)

//    // X2: maroon=0 gold=1 in ExpVio => DESIGN BUG: gold=1 triggers transition to Normal
//    // The spec says only rst_b exits ExpVio. Testbench checks FSM_NORMAL to detect bug.
//    $display("X2: ExpVio + m=0 g=1 => detects design bug (transitions to Normal)");
//    `GOTO_EXPVIO
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b1;
//    @(posedge clk);
//    `CLK_WAIT
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `CLK_WAIT
//    `READ_STATUS(FSM_NORMAL)

//    // X3: maroon=1 gold=0 in ExpVio => stays ExpVio
//    $display("X3: ExpVio + m=1 g=0 => stays ExpVio");
//    `GOTO_EXPVIO
//    @(negedge clk);
//    maroon <= 1'b1; gold <= 1'b0;
//    @(posedge clk);
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `READ_STATUS(FSM_EXPVIO)

//    // X4: maroon=1 gold=1 in ExpVio => stays ExpVio
//    $display("X4: ExpVio + m=1 g=1 => stays ExpVio");
//    `GOTO_EXPVIO
//    @(negedge clk);
//    maroon <= 1'b1; gold <= 1'b1;
//    @(posedge clk);
//    @(negedge clk);
//    maroon <= 1'b0; gold <= 1'b0;
//    @(posedge clk);
//    `CLK_WAIT
//    `READ_STATUS(FSM_EXPVIO)

//    // X5: Illegal command in ExpVio => stays ExpVio (writes ignored)
//    $display("X5: ExpVio + illegal cmd => stays ExpVio");
//    `GOTO_EXPVIO
//    `ISSUE_BAD_CMD
//    `READ_STATUS(FSM_EXPVIO)

//    // X6: Export violation command in ExpVio => stays ExpVio
//    $display("X6: ExpVio + export_disable + cmd => stays ExpVio");
//    `GOTO_EXPVIO
//    `ISSUE_EXPVIO_CMD
//    `READ_STATUS(FSM_EXPVIO)

//    // =========================================================================
//    $display("\n\nAll FSM state tests complete.\n\n");
//    #5 $finish;
// end

// // ---------------------------------------------------------------------------
// // DUT instantiation
// // ---------------------------------------------------------------------------
// verichip5 verichip5 (
//    .clk           ( clk            ),
//    .rst_b         ( rst_b          ),
//    .export_disable( export_disable ),
//    .interrupt_1   ( interrupt_1    ),
//    .interrupt_2   ( interrupt_2    ),
//    .maroon        ( maroon         ),
//    .gold          ( gold           ),
//    .chip_select   ( chip_select    ),
//    .address       ( address        ),
//    .byte_en       ( byte_en        ),
//    .rw_           ( rw_            ),
//    .data_in       ( data_in        ),
//    .data_out      ( data_out       )
// );

// initial begin
//    $dumpfile("verichip.vcd");
//    $dumpvars(0, top_verichip5);
// end

// endmodule




// `timescale 1ns/1ps

// `define SET_WRITE(addr,val,bytes,cs)   \
//    rw_ <= 1'b0;                     \
//    chip_select <= cs;               \
//    byte_en <= bytes;                \
//    address <= addr;                 \
//    data_in <= val; 

// `define SET_READ(addr,cs)           \
//    rw_ <= 1'b1;                     \
//    chip_select <= cs;               \
//    byte_en <= 2'b00;                \
//    address <= addr;                 \
//    data_in <= 16'h0;

// `define CLEAR_BUS                   \
//    chip_select    <= 1'b0;          \
//    address        <= 7'h0;          \
//    byte_en        <= 2'h0;          \
//    rw_            <= 1'b1;          \
//    data_in        <= 16'h0; 

// `define CLEAR_ALL                   \
//    export_disable <= 1'b0;          \
//    maroon         <= 1'b0;          \
//    gold           <= 1'b0;          \
//    `CLEAR_BUS


// `define STATE_RESET_TO_NORMAL               \
//    maroon <= 1'b0;                           \
//    gold <= 1'b0;


// `define STATE_ERROR_TO_NORMAL               \
//    maroon <= 1'b1;                           \
//    gold <= 1'b0;


   


// `define CHECK_VAL(val)              \
//    if ( data_out != val )           \
//        $display("bad read, got %h but expected %h at %t",data_out,val,$time());

// `define CHECK_RW(addr,wval,rval,bytes,cs)    \
//    `WRITE_REG(addr,wval,bytes,cs)            \
//    `READ_REG(addr,rval,cs)

// `define CHIP_RESET                  \
//    wait( clk == 1'b0 );             \
//    rst_b <= 1'b0;                   \
//    wait( clk == 1'b1 );             \
//    rst_b <= 1'b1;


// `define STATE_RESET                        \
//          `CHIP_RESET

// `define WAIT_TIME                                 \
//    #10;



// `define STATE_TESTER (val)                               \
// `SET_WRITE(7'h10,16'h0001,2'b11,1'b1)                    \
//    `WAIT_TIME                                           \
//    `SET_READ(7'h10,1'b1)                                 \
//    `WAIT_TIME                                           \
//    `CHECK_VAL(16'h0001)                                 \
//    `WAIT_TIME                                           
   
//    //write to alu right and read from alu right
//    `SET_WRITE(7'h14,16'h0002,2'b11,1'b1)                 \
//    `WAIT_TIME                                           \
//    `SET_READ(7'h14,1'b1)                                  \
//    `WAIT_TIME                                           \
//    `CHECK_VAL(16'h0002)                                 \
//    `WAIT_TIME                                           

//    //perform add operation
//    `SET_WRITE(7'h08,16'h0001,2'b11,1'b1)                 \
//    `WAIT_TIME                                           \
//    `SET_READ(7'h18,1'b1)                                \
//    `WAIT_TIME                                           \
//    `CHECK_VAL(val)                                     \ //confirms that we are in reset state
//    `WAIT_TIME                                           



// `define EXPORT_STATE                                  \
//    `CLEAR_ALL                                         \
//    `WAIT_TIME                                         \
//    `CHIP_RESET                                        \
//    `WAIT_TIME                                         \
//    `STATE_RESET_TO_NORMAL                             \
//    `WAIT_TIME                                         \
//    `SET_WRITE(7'h08,16'h8003,2'b11,1'b1)              \
//    `WAIT_TIME                                         \
//    `CLEAR_BUS                                         \
//    `WAIT_TIME                                         \
//    `SET_WRITE(7'h10,16'hFFFF,2'b11,1'b1)              \
//    `CLEAR_BUS                                         \
//    `SET_READ(7'h10,1'b1)                               \
//    `WAIT_TIME                                         \
//    `WAIT_TIME                                         \
//    `CHECK_VAL(16'h0000)                               \
//    `WAIT_TIME                                         \
//    `CLEAR_BUS                                         

// module top_verichip5 ();

// logic clk;                       // system clock
// logic rst_b;                     // chip reset
// logic export_disable;            // disable features
// logic interrupt_1;               // first interrupt
// logic interrupt_2;               // second interrupt

// logic maroon;                    // maroon state machine input
// logic gold;                      // gold state machine input

// logic chip_select;               // target of r/w
// logic [6:0] address;             // address bus
// logic [1:0] byte_en;             // write byte enables
// logic       rw_;                 // read/write
// logic [15:0] data_in;            // input data bus

// logic [15:0] data_out;           // output data bus

// localparam VCHIP_VER_ADDR       = 7'h00;
// localparam VCHIP_STA_ADDR       = 7'h04;
// localparam VCHIP_CMD_ADDR       = 7'h08;
// localparam VCHIP_CON_ADDR       = 7'h0C;
// localparam VCHIP_ALU_LEFT_ADDR  = 7'h10;
// localparam VCHIP_ALU_RIGHT_ADDR = 7'h14;
// localparam VCHIP_ALU_OUT_ADDR   = 7'h18;

// localparam VCHIP_ALU_VALID = 16'h8000;
// localparam VCHIP_ALU_ADD   = 16'h0001;
// localparam VCHIP_ALU_SUB   = 16'h0002;
// localparam VCHIP_ALU_MVL   = 16'h0003;
// localparam VCHIP_ALU_MVR   = 16'h0004;
// localparam VCHIP_ALU_SWA   = 16'h0005;
// localparam VCHIP_ALU_SHL   = 16'h0006;
// localparam VCHIP_ALU_SHR   = 16'h0007;

// localparam ONE = 1'b1;
// localparam ZERO = 1'b0;


// initial begin


// //-----------------start of hw5-------------------------------------------



//    //verifying in reset state
//    $display("\n\nverifying in reset state\n\n");
//    `CLEAR_ALL
//    `STATE_RESET
//    `WAIT_TIME
//    `STATE_TESTER(16'h0000)

//    //verifying how to get from reset to Normal state
//    $display("\n\nverifying how to get from reset to Normal state\n\n");
//    `CLEAR_ALL
//    `CHIP_RESET
//    `WAIT_TIME
//    `STATE_RESET_TO_NORMAL
//    `WAIT_TIME
//    `STATE_TESTER(16'h0001)


//    //verifying how to get from Normal to Export violation
//    `CLEAR_ALL
//    `CHIP_RESET
//    `WAIT_TIME
//    `STATE_RESET_TO_NORMAL
//    `WAIT_TIME
//    `EXPORT_STATE
   
// //-------------------PUSH FOR INITIAL TEST -----------------------------------------------
// //==================CHNAGES TO BE MADE AFTER TEST 1=====================================

// //address in `defines added raw

// //============================XXXXXXXXXXXXX=================================================
   


//    #5 $finish;
// end // initial begin


// verichip5 verichip5 (.clk           ( clk            ),    // system clock
//                    .rst_b         ( rst_b          ),    // chip reset
//                    .export_disable( export_disable ),    // disable features
//                    .interrupt_1   ( interrupt_1    ),    // first interrupt
//                    .interrupt_2   ( interrupt_2    ),    // second interrupt
 
//                    .maroon        ( maroon         ),    // maroon state machine input
//                    .gold          ( gold           ),    // gold state machine input

//                    .chip_select   ( chip_select    ),    // target of r/w
//                    .address       ( address        ),    // address bus
//                    .byte_en       ( byte_en        ),    // write byte enables
//                    .rw_           ( rw_            ),    // read/write
//                    .data_in       ( data_in        ),    // data bus

//                    .data_out      ( data_out       ) );  // output data bus

// initial 
// begin
//     $dumpfile("verichip.vcd");
//     $dumpvars(0,top_verichip5);
// end

// endmodule



`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// Bus primitives
// ---------------------------------------------------------------------------

`define SET_WRITE(addr,val,bytes,cs)   \
   rw_          <= 1'b0;              \
   chip_select  <= cs;                \
   byte_en      <= bytes;             \
   address      <= addr;              \
   data_in      <= val;

`define SET_READ(addr,cs)              \
   rw_          <= 1'b1;              \
   chip_select  <= cs;                \
   byte_en      <= 2'b00;             \
   address      <= addr;              \
   data_in      <= 16'h0;

`define CLEAR_BUS                      \
   chip_select  <= 1'b0;              \
   address      <= 7'h0;              \
   byte_en      <= 2'h0;              \
   rw_          <= 1'b1;              \
   data_in      <= 16'h0;

`define CLEAR_ALL                      \
   export_disable <= 1'b0;            \
   maroon         <= 1'b0;            \
   gold           <= 1'b0;            \
   `CLEAR_BUS

// ---------------------------------------------------------------------------
// State machine control inputs
// ---------------------------------------------------------------------------

// maroon=0, gold=1  =>  !maroon && gold  =>  Reset -> Normal
`define STATE_RESET_TO_NORMAL          \
   maroon <= 1'b0;                    \
   gold   <= 1'b1;

// maroon=1, gold=0  =>  Error -> Normal handshake (step 1)
`define STATE_ERROR_TO_NORMAL          \
   maroon <= 1'b1;                    \
   gold   <= 1'b0;

// ---------------------------------------------------------------------------
// Checking / register access helpers
// ---------------------------------------------------------------------------

`define CHECK_VAL(val)                 \
   if ( data_out !== val )            \
      $display("FAIL: got %h but expected %h at %t", data_out, val, $time());

`define WRITE_REG(addr,val,bytes,cs)   \
   @(negedge clk);                    \
   `SET_WRITE(addr,val,bytes,cs)      \
   @(posedge clk);

`define READ_REG(addr,val,cs)          \
   @(negedge clk);                    \
   `SET_READ(addr,cs)                 \
   @(posedge clk);                    \
   `CHECK_VAL(val)

`define CHECK_RW(addr,wval,rval,bytes,cs) \
   `WRITE_REG(addr,wval,bytes,cs)         \
   `READ_REG(addr,rval,cs)

// ---------------------------------------------------------------------------
// Clock / reset helpers
// ---------------------------------------------------------------------------

`define CLK_WAIT                       \
   @(posedge clk);

`define CHIP_RESET                     \
   @(negedge clk);                    \
   rst_b <= 1'b0;                     \
   @(posedge clk);                    \
   @(negedge clk);                    \
   rst_b <= 1'b1;                     \
   @(posedge clk);

// ---------------------------------------------------------------------------
// STATE_TESTER: write LEFT=1, RIGHT=2, issue ADD, read ALU_OUT
//   Reset state  => ALU ignored => ALU_OUT stays 0  => pass val=16'h0000
//   Normal state => ADD executes => ALU_OUT = 3     => pass val=16'h0003
// ---------------------------------------------------------------------------
`define STATE_TESTER(val)                             \
   @(negedge clk);                                   \
   `SET_WRITE(7'h10, 16'h0001, 2'b11, 1'b1)          \
   @(posedge clk);                                   \
   @(negedge clk);                                   \
   `SET_READ(7'h10, 1'b1)                             \
   @(posedge clk);                                   \
   `CHECK_VAL(16'h0001)                              \
   @(negedge clk);                                   \
   `SET_WRITE(7'h14, 16'h0002, 2'b11, 1'b1)          \
   @(posedge clk);                                   \
   @(negedge clk);                                   \
   `SET_READ(7'h14, 1'b1)                             \
   @(posedge clk);                                   \
   `CHECK_VAL(16'h0002)                              \
   @(negedge clk);                                   \
   `SET_WRITE(7'h08, 16'h8001, 2'b11, 1'b1)          \
   @(posedge clk);                                   \
   `CLK_WAIT                                         \
   @(negedge clk);                                   \
   `SET_READ(7'h18, 1'b1)                             \
   @(posedge clk);                                   \
   `CHECK_VAL(val)

// ---------------------------------------------------------------------------
// EXPORT_STATE: set export_disable, write LEFT, issue SHL => Export Violation
//   then verify LED register has been reset to 0
// ---------------------------------------------------------------------------
`define EXPORT_STATE                                  \
   @(negedge clk);                                   \
   export_disable <= 1'b1;                           \
   `SET_WRITE(7'h10, 16'h1234, 2'b11, 1'b1)          \
   @(posedge clk);                                   \
   @(negedge clk);                                   \
   `CLEAR_BUS                                        \
   @(posedge clk);                                   \
   @(negedge clk);                                   \
   `SET_WRITE(7'h08, 16'h8006, 2'b11, 1'b1)          \
   @(posedge clk);                                   \
   @(negedge clk);                                   \
   `CLEAR_BUS                                        \
   @(posedge clk);                                   \
   `CLK_WAIT                                         \
   @(negedge clk);                                   \
   `SET_READ(7'h10, 1'b1)                             \
   @(posedge clk);                                   \
   `CHECK_VAL(16'h0000)                              \
   @(negedge clk);                                   \
   `CLEAR_BUS

// ---------------------------------------------------------------------------
// FSM test helpers (new for hw03 Prof. Milman 6-case requirement)
// ---------------------------------------------------------------------------

// Read Status register bits[3:0] and compare against expected FSM state
`define READ_STATUS(expected_state)    \
   @(negedge clk);                    \
   `SET_READ(7'h04, 1'b1)             \
   @(posedge clk);                    \
   if (data_out[3:0] !== expected_state) \
      $display("FSM MISMATCH: got state %0h expected %0h at %t", \
               data_out[3:0], expected_state, $time()); \
   @(negedge clk);                    \
   `CLEAR_BUS                         \
   @(posedge clk);

// Issue an illegal/reserved command (CMD=4'hA, Valid=1)
`define ISSUE_BAD_CMD                  \
   @(negedge clk);                    \
   `SET_WRITE(7'h08, 16'h800A, 2'b11, 1'b1) \
   @(posedge clk);                    \
   @(negedge clk);                    \
   `CLEAR_BUS                         \
   @(posedge clk);                    \
   `CLK_WAIT

// Issue an export-violation command (export_disable=1 + SHL command)
`define ISSUE_EXPVIO_CMD               \
   @(negedge clk);                    \
   export_disable <= 1'b1;            \
   `SET_WRITE(7'h08, 16'h8006, 2'b11, 1'b1) \
   @(posedge clk);                    \
   @(negedge clk);                    \
   export_disable <= 1'b0;            \
   `CLEAR_BUS                         \
   @(posedge clk);                    \
   `CLK_WAIT

// Full chip reset then transition into Normal state cleanly
`define GOTO_NORMAL                    \
   `CLEAR_ALL                         \
   `CHIP_RESET                        \
   @(negedge clk);                    \
   `STATE_RESET_TO_NORMAL             \
   @(posedge clk);                    \
   `CLK_WAIT                          \
   @(negedge clk);                    \
   maroon <= 1'b0; gold <= 1'b0;      \
   @(posedge clk);                    \
   `CLK_WAIT

// Put chip into Error state from Normal (bad command)
`define GOTO_ERROR                     \
   `GOTO_NORMAL                       \
   `ISSUE_BAD_CMD

// Put chip into Export Violation state from Normal
`define GOTO_EXPVIO                    \
   `GOTO_NORMAL                       \
   `ISSUE_EXPVIO_CMD

// ---------------------------------------------------------------------------
// Module
// ---------------------------------------------------------------------------

module top_verichip5 ();

logic clk;
logic rst_b;
logic export_disable;
logic interrupt_1;
logic interrupt_2;

logic maroon;
logic gold;

logic chip_select;
logic [6:0] address;
logic [1:0] byte_en;
logic       rw_;
logic [15:0] data_in;
logic [15:0] data_out;

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

localparam ONE  = 1'b1;
localparam ZERO = 1'b0;

// FSM state encodings (Status register bits [3:0])
localparam FSM_RESET  = 4'h0;
localparam FSM_NORMAL = 4'h1;
localparam FSM_ERROR  = 4'h2;
localparam FSM_EXPVIO = 4'h8;

// Clock generation
initial clk = 0;
always #5 clk = ~clk;

// ---------------------------------------------------------------------------
// Test program
// ---------------------------------------------------------------------------
initial begin

   // Initialise all signals
   `CLEAR_ALL
   rst_b <= 1'b1;
   @(posedge clk);

   // =========================================================================
   // ORIGINAL hw03 smoke tests (preserved)
   // =========================================================================

   $display("\n\nVerifying in Reset state\n\n");
   `CLEAR_ALL
   `CHIP_RESET
   `STATE_TESTER(16'h0000)

   $display("\n\nVerifying Reset -> Normal state transition\n\n");
   `CLEAR_ALL
   `CHIP_RESET
   @(negedge clk);
   `STATE_RESET_TO_NORMAL
   @(posedge clk);
   `CLK_WAIT
   `STATE_TESTER(16'h0003)

   $display("\n\nVerifying Normal -> Export Violation state\n\n");
   `CLEAR_ALL
   `CHIP_RESET
   @(negedge clk);
   `STATE_RESET_TO_NORMAL
   @(posedge clk);
   `CLK_WAIT
   `EXPORT_STATE

   // =========================================================================
   // FSM STATE TESTS  (Prof. Milman: 6 cases per state)
   //
   // The 6 inputs tested in every state are:
   //   1. maroon=0, gold=0   (no transition signal)
   //   2. maroon=0, gold=1   (Reset->Normal signal)
   //   3. maroon=1, gold=0   (Error->Normal signal)
   //   4. maroon=1, gold=1   (illegal combination)
   //   5. Illegal command    (CMD=4'hA with Valid=1)
   //   6. Export violation   (export_disable=1 + restricted CMD)
   // =========================================================================

   // -------------------------------------------------------------------------
   // STATE: RESET  (FSM_RESET = 4'h0)
   // -------------------------------------------------------------------------
   $display("\n\n=== FSM TESTS: RESET STATE ===\n");

   // R1: maroon=0 gold=0 in Reset => stays Reset
   $display("R1: Reset + m=0 g=0 => stays Reset");
   `CLEAR_ALL
   `CHIP_RESET
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_RESET)

   // R2: maroon=0 gold=1 in Reset => transitions to Normal
   $display("R2: Reset + m=0 g=1 => Normal");
   `CLEAR_ALL
   `CHIP_RESET
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b1;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_NORMAL)

   // R3: maroon=1 gold=0 in Reset => stays Reset (Error->Normal only valid from Error)
   $display("R3: Reset + m=1 g=0 => stays Reset");
   `CLEAR_ALL
   `CHIP_RESET
   @(negedge clk);
   maroon <= 1'b1; gold <= 1'b0;
   @(posedge clk);
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_RESET)

   // R4: maroon=1 gold=1 in Reset => stays Reset (invalid combination)
   $display("R4: Reset + m=1 g=1 => stays Reset");
   `CLEAR_ALL
   `CHIP_RESET
   @(negedge clk);
   maroon <= 1'b1; gold <= 1'b1;
   @(posedge clk);
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_RESET)

   // R5: Illegal command in Reset => stays Reset (commands ignored in Reset)
   $display("R5: Reset + illegal cmd => stays Reset");
   `CLEAR_ALL
   `CHIP_RESET
   `ISSUE_BAD_CMD
   `CLK_WAIT
   `CLK_WAIT
   `READ_STATUS(FSM_RESET)
   // Also verify ALU commands are still ignored (confirms Reset behavior)
   `STATE_TESTER(16'h0000)

   // R6: Export violation command in Reset => stays Reset (commands ignored)
   $display("R6: Reset + export_disable + cmd => stays Reset");
   `CLEAR_ALL
   `CHIP_RESET
   `ISSUE_EXPVIO_CMD
   `READ_STATUS(FSM_RESET)

   // -------------------------------------------------------------------------
   // STATE: NORMAL  (FSM_NORMAL = 4'h1)
   // -------------------------------------------------------------------------
   $display("\n\n=== FSM TESTS: NORMAL STATE ===\n");

   // N1: maroon=0 gold=0 in Normal => stays Normal
   $display("N1: Normal + m=0 g=0 => stays Normal");
   `GOTO_NORMAL
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_NORMAL)

   // N2: maroon=0 gold=1 in Normal => stays Normal (already in Normal)
   $display("N2: Normal + m=0 g=1 => stays Normal");
   `GOTO_NORMAL
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b1;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_NORMAL)

   // N3: maroon=1 gold=0 in Normal => stays Normal (Error->Normal only from Error)
   $display("N3: Normal + m=1 g=0 => stays Normal");
   `GOTO_NORMAL
   @(negedge clk);
   maroon <= 1'b1; gold <= 1'b0;
   @(posedge clk);
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_NORMAL)

   // N4: maroon=1 gold=1 in Normal => stays Normal (invalid combination)
   $display("N4: Normal + m=1 g=1 => stays Normal");
   `GOTO_NORMAL
   @(negedge clk);
   maroon <= 1'b1; gold <= 1'b1;
   @(posedge clk);
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_NORMAL)

   // N5: Illegal command in Normal => transitions to Error
   $display("N5: Normal + illegal cmd => Error");
   `GOTO_NORMAL
   `ISSUE_BAD_CMD
   `READ_STATUS(FSM_ERROR)

   // N6: Export violation command in Normal => transitions to Export Violation
   $display("N6: Normal + export_disable + cmd => Export Violation");
   `GOTO_NORMAL
   `ISSUE_EXPVIO_CMD
   `READ_STATUS(FSM_EXPVIO)

   // -------------------------------------------------------------------------
   // STATE: ERROR  (FSM_ERROR = 4'h2)
   // -------------------------------------------------------------------------
   $display("\n\n=== FSM TESTS: ERROR STATE ===\n");

   // E1: maroon=0 gold=0 in Error => stays Error
   $display("E1: Error + m=0 g=0 => stays Error");
   `GOTO_ERROR
   `CLK_WAIT
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `CLK_WAIT
   `READ_STATUS(FSM_ERROR)
   // Verify writes are disabled (Error behavior): write to Left, confirm unchanged
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hBEEF, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 1'b1)

   // E2: maroon=0 gold=1 in Error => stays Error (Reset->Normal signal invalid here)
   $display("E2: Error + m=0 g=1 => stays Error");
   `GOTO_ERROR
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b1;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_ERROR)

   // E3: maroon=1 gold=0 in Error => transitions to Normal
   $display("E3: Error + m=1 g=0 => Normal");
   `GOTO_ERROR
   `CLK_WAIT
   @(negedge clk);
   maroon <= 1'b1; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `CLK_WAIT
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `CLK_WAIT
   `READ_STATUS(FSM_NORMAL)
   // Verify writes are enabled (Normal behavior): write to Left, confirm written
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hCAFE, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR, 16'hCAFE, 1'b1)

   // E4: maroon=1 gold=1 in Error => stays Error (invalid combination)
   $display("E4: Error + m=1 g=1 => stays Error");
   `GOTO_ERROR
   @(negedge clk);
   maroon <= 1'b1; gold <= 1'b1;
   @(posedge clk);
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_ERROR)

   // E5: Illegal command in Error => stays Error (writes are disabled)
   $display("E5: Error + illegal cmd => stays Error");
   `GOTO_ERROR
   `ISSUE_BAD_CMD
   `READ_STATUS(FSM_ERROR)

   // E6: Export violation command in Error => stays Error (writes are disabled)
   $display("E6: Error + export_disable + cmd => stays Error");
   `GOTO_ERROR
   `ISSUE_EXPVIO_CMD
   `READ_STATUS(FSM_ERROR)

// -------------------------------------------------------------------------
   // STATE: EXPORT VIOLATION  (FSM_EXPVIO = 4'h8)
   // Only rst_b exits this state; all other inputs are ignored.
   // -------------------------------------------------------------------------
   $display("\n\n=== FSM TESTS: EXPORT VIOLATION STATE ===\n");
 
   // X1: maroon=0 gold=0 in ExpVio => stays ExpVio
   $display("X1: ExpVio + m=0 g=0 => stays ExpVio");
   `GOTO_EXPVIO
   `CLK_WAIT
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `CLK_WAIT
   `READ_STATUS(FSM_EXPVIO)
   // Verify Left register is reset (ExpVio resets registers)
   // and write is disabled
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hDEAD, 2'b11, 1'b1)
   `CLK_WAIT
 
   // X2: maroon=0 gold=1 in ExpVio => stays ExpVio
   $display("X2: ExpVio + m=0 g=1 => stays ExpVio");
   `GOTO_EXPVIO
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b1;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_EXPVIO)
 
   // X3: maroon=1 gold=0 in ExpVio => stays ExpVio
   $display("X3: ExpVio + m=1 g=0 => stays ExpVio");
   `GOTO_EXPVIO
   @(negedge clk);
   maroon <= 1'b1; gold <= 1'b0;
   @(posedge clk);
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_EXPVIO)
 
   // X4: maroon=1 gold=1 in ExpVio => stays ExpVio
   $display("X4: ExpVio + m=1 g=1 => stays ExpVio");
   `GOTO_EXPVIO
   @(negedge clk);
   maroon <= 1'b1; gold <= 1'b1;
   @(posedge clk);
   @(negedge clk);
   maroon <= 1'b0; gold <= 1'b0;
   @(posedge clk);
   `CLK_WAIT
   `READ_STATUS(FSM_EXPVIO)
 
   // X5: Illegal command in ExpVio => stays ExpVio (writes ignored)
   $display("X5: ExpVio + illegal cmd => stays ExpVio");
   `GOTO_EXPVIO
   `ISSUE_BAD_CMD
   `READ_STATUS(FSM_EXPVIO)
 
   // X6: Export violation command in ExpVio => stays ExpVio
   $display("X6: ExpVio + export_disable + cmd => stays ExpVio");
   `GOTO_EXPVIO
   @(negedge clk);
   export_disable <= 1'b1;
   `SET_WRITE(7'h08, 16'h8006, 2'b11, 1'b1)
   @(posedge clk);
   @(negedge clk);
   export_disable <= 1'b0;
   `CLEAR_BUS
   @(posedge clk);
   `CLK_WAIT
   `CLK_WAIT
   `READ_STATUS(FSM_EXPVIO)
 
   // =========================================================================
   $display("\n\nAll FSM state tests complete.\n\n");
   #5 $finish;
end

// ---------------------------------------------------------------------------
// DUT instantiation
// ---------------------------------------------------------------------------
verichip5 verichip5 (
   .clk           ( clk            ),
   .rst_b         ( rst_b          ),
   .export_disable( export_disable ),
   .interrupt_1   ( interrupt_1    ),
   .interrupt_2   ( interrupt_2    ),
   .maroon        ( maroon         ),
   .gold          ( gold           ),
   .chip_select   ( chip_select    ),
   .address       ( address        ),
   .byte_en       ( byte_en        ),
   .rw_           ( rw_            ),
   .data_in       ( data_in        ),
   .data_out      ( data_out       )
);

initial begin
   $dumpfile("verichip.vcd");
   $dumpvars(0, top_verichip5);
end

endmodule