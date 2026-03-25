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

// FIX: maroon=0, gold=1 to satisfy !maroon && gold condition in FSM
`define STATE_RESET_TO_NORMAL          \
   maroon <= 1'b0;                    \
   gold   <= 1'b1;

`define STATE_ERROR_TO_NORMAL          \
   maroon <= 1'b1;                    \
   gold   <= 1'b0;

`define CHECK_VAL(val)                 \
   if ( data_out !== val )            \
      $display("bad read, got %h but expected %h at %t", data_out, val, $time());

// FIX: define WRITE_REG and READ_REG so CHECK_RW works
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

`define CHIP_RESET                     \
   @(negedge clk);                    \
   rst_b <= 1'b0;                     \
   @(posedge clk);                    \
   @(negedge clk);                    \
   rst_b <= 1'b1;                     \
   @(posedge clk);

`define CLK_WAIT                       \
   @(posedge clk);

// FIX: STATE_TESTER rewritten as valid macro (no space before args,
//      no mid-line comments inside macro body, all lines continued)
// Writes LEFT=1, RIGHT=2, issues ADD, then reads ALU_OUT.
// In Reset state ALU is ignored so ALU_OUT stays 0 (expected val=16'h0000).
// In Normal state ADD executes so ALU_OUT = 3 (expected val=16'h0003).
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

// FIX: export_disable=1 must be set before issuing restricted command (CMD>2)
//      CMD=6 (SHL) with export_disable=1 triggers Export Violation
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

// FIX: clock generation (was missing entirely)
initial clk = 0;
always #5 clk = ~clk;

initial begin

   // initialise all signals before reset
   `CLEAR_ALL
   rst_b <= 1'b1;
   @(posedge clk);

   // ---------------------------------------------------------------
   // Verify behaviour in Reset state
   // ---------------------------------------------------------------
   $display("\n\nVerifying in Reset state\n\n");
   `CLEAR_ALL
   `CHIP_RESET
   // In Reset state the ALU ignores commands, so ALU_OUT stays 16'h0000
   `STATE_TESTER(16'h0000)

   // ---------------------------------------------------------------
   // Verify transition Reset -> Normal and ALU execution
   // ---------------------------------------------------------------
   $display("\n\nVerifying Reset -> Normal state transition\n\n");
   `CLEAR_ALL
   `CHIP_RESET
   @(negedge clk);
   `STATE_RESET_TO_NORMAL
   @(posedge clk);
   `CLK_WAIT
   // In Normal state ADD(1+2)=3 should execute
   `STATE_TESTER(16'h0003)

   // ---------------------------------------------------------------
   // Verify Normal -> Export Violation
   // ---------------------------------------------------------------
   $display("\n\nVerifying Normal -> Export Violation state\n\n");
   `CLEAR_ALL
   `CHIP_RESET
   @(negedge clk);
   `STATE_RESET_TO_NORMAL
   @(posedge clk);
   `CLK_WAIT
   `EXPORT_STATE

   #5 $finish;
end


// FIX: instantiate verichip4 (matches the provided design file)
verichip4 verichip4 (
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

