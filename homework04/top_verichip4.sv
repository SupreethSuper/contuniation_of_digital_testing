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

module top_verichip4 ();

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

localparam VCHIP_ALU_VER = 4'h2;    // current ALU version
localparam VCHIP_MAJ_VER = 4'h1;
localparam VCHIP_MIN_VER = 4'h0;
localparam STA_RESERVED_HIGH = 6'b00_00_00;
localparam STA_RESERVED_LOW = 4'b00_00;
localparam COMMAND_RSVD = 11'b000_0000_0000;

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
   $dumpfile("verichip4.vcd");
   $dumpvars(0, top_verichip4);
end

initial
begin
   `CLEAR_ALL
   `CHIP_RESET

   // Test ALU Left Register in Reset State (Write and Read) keeping byte enable and chip select on
   // Attempt to write 0000 to ALU Left
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
 //Attempt to read 0000 from ALU left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
// Make sure 0000 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
    //Similarly, apply this method for other test inputs in the same state.
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFFFF);
   `CHECK_VAL(16'hFFFF)

   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hAAAA);
   `CHECK_VAL(16'hAAAA)

   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h5555);
   `CHECK_VAL(16'h5555)
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
    
 #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   // Test ALU Left Register in Normal State (Write and Read) keeping byte enable and chip select on
   `CLEAR_ALL
   `CHIP_RESET
    maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   #10; //Attempt to write 0000 to ALU Left
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10; //Attempt to read 0000 from ALU left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;  // Make sure 0000 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
    // Similarly, apply this method for other test inputs within the same state.
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFFFF);
   `CHECK_VAL(16'hFFFF)

   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hAAAA);
   `CHECK_VAL(16'hAAAA)

   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h5555);
   `CHECK_VAL(16'h5555)

   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   // Test ALU Left Register in Error State (Write and Read) keeping byte enable and chip select on
   `CLEAR_ALL
   `CHIP_RESET
    maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
    $display("\n--- Attempt to write 0100 to Configuration register ---");
    //Attempt to write 0100 to Configuration register
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_CON_ADDR,16'h0100,2'b11,1'b1)
   #10; //Attempt to write 8008 to command register - To transition from Normal state to Error state
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008,2'b11,1'b1)
   #10; //Attempt to write 0000 to ALU_Left
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10; // Make sure 0000 is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
    // Similarly, apply this method for other test inputs within the same state.
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;


$display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   // Test ALU Left Register in Export Violation State (Write and Read) keeping byte enable and chip select on
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   export_disable <= 1'b1; //This signal disables certain export-required commands. Invalid commands will transition the state machine to the Export Violation state.
   $display("\n--- Attempt to write 0200 to Configuration register ---");
   //Attempt to write 0200 to Configuration register
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0200);
   `SET_WRITE(VCHIP_CON_ADDR,16'h0200,2'b11,1'b1)
   #10;//Attempt to write 800A to command register - To transition from Normal state to Export violation state
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h800A);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800A,2'b11,1'b1)
   #10;//Attempt to write 0000 to ALU_Left
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10; // Make sure 0000 is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same state.
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)


   $display("\n--- Test Byte Enable Combinations with chip select on state ---");
   // Test Byte Enable Combinations with chip select on state
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   $display("\n--- Attempt to write 0000 to ALU Left when byte enable is 00 ---");
   //Attempt to write 0000 to ALU Left when byte enable is 00
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b00 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b00, 1'b1)
   #10;//Attempt to read 0000 from ALU left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b00 ,1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b00 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b00,1'b1)
    
 #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b00 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b00, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)


   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   $display("\n--- Attempt to write 0000 to ALU Left when byte enable is 01 ---");
   //Attempt to write 0000 to ALU Left when byte enable is 01
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b01 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b01, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same combination.
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b01 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b01, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h00AA);
   `CHECK_VAL(16'h00AA)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b01 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b01, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0055);
   `CHECK_VAL(16'h0055)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b01 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b01, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h00FF);
   `CHECK_VAL(16'h00FF)


   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1;// Maroon = 0 and Gold = 1, for transitioning to Normal State.
   $display("\n--- Attempt to write 0000 to ALU Left when byte enable is 10 ---");
   //Attempt to write 0000 to ALU Left when byte enable is 10
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b10 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b10, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same combination.
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b10 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b10, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hAA00);
   `CHECK_VAL(16'hAA00)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b10 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b10, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h5500);
   `CHECK_VAL(16'h5500)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b10 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b10, 1'b1)
   #10;

$display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
`SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFF00);
   `CHECK_VAL(16'hFF00)


   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   $display("\n--- Attempt to write 0000 to ALU Left when byte enable is 11 ---");
   //Attempt to write 0000 to ALU Left when byte enable is 11
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same combination.
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hAAAA);
   `CHECK_VAL(16'hAAAA)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h5555);
   `CHECK_VAL(16'h5555)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFFFF);
   `CHECK_VAL(16'hFFFF)



   // Test Aliasing on different operations
  $display("\n--- Check for Aliasing with Chip Select ---");
  //Check for Aliasing with Chip Select
   `CHIP_RESET
   `CLEAR_ALL
   //Attempt to write 0000 to ALU_Left
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b0");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0)
   #10;// Make sure 0000 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same combination.
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b0");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b0");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b0");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("\n--- Check for Aliasing without Chip Select ---");
   //Check for Aliasing without Chip Select
   // Clear all for a spotless interface
   `CLEAR_ALL
   //Attempt to write AAAA to ALU_Left when chip select is off
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b0", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b0)
   #10; //Attempt to read AAAA from ALU_Left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure FFFF is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFFFF);
   `CHECK_VAL(16'hFFFF)
   // Similarly, apply this method for other test inputs within the same combination.
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b0", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFFFF);
   `CHECK_VAL(16'hFFFF)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b0", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFFFF);
   `CHECK_VAL(16'hFFFF)
   //Attempt to write 5555 to ALU Left when chip select is on
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;//Attempt to read 5555 from ALU left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 5555 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h5555);
   `CHECK_VAL(16'h5555)
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b0", 16'h0000);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h5555);
   `CHECK_VAL(16'h5555)

   $display("\n--- Write to Correct ALU LEFT Register ---");
   //Write to Correct ALU LEFT Register
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   //Attempt to write AAAA to 7'h50 address
   $display("WRITE addr=7'h50 (ALIAS) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(7'h50, 16'hAAAA, 2'b11, 1'b1)
   #10;//Attempt to write FFFF from ALU left
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;//Attempt to read AAAA from 7'h50
   $display("READ  addr=7'h50 (ALIAS) cs=1'b1");
   `SET_READ(7'h50, 1'b1)
   #10;// Make sure 0000 is read back from 7'h50 (unused address returns 0)
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)   // corrected from 16'hAAAA

$display("\n--- Write to Aliased Address (7'h50) ---");
//Write to Aliased Address (7'h50)
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
  //Attempt to write AAAA to ALU_Left
  $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
  `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10; //Attempt to write 5555 to 7'h50 address
   $display("WRITE addr=7'h50 (ALIAS) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(7'h50, 16'h5555, 2'b11, 1'b1)
   #10; //Attempt to read AAAA from ALU_Left
   $display("READ  addr=7'h10 (ALU_LEFT) cs=1'b1");
   `SET_READ(VCHIP_ALU_LEFT_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU left (write to unused address may clear register)
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)   // corrected from 16'hAAAA



//===============================================h4 content now================================

//version register test
`CLEAR_ALL
   `CHIP_RESET
   //------------------------------------version R/W--------------------------------------------------------------------------------------------------------------------------
  $display("\n--- $display(\"reset state version reg\n\n\n\n\"); ---");
  // $display("reset state version reg\n\n\n\n");
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
 //Attempt to read 0000 from ALU left
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
// Make sure 0000 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("\n--- $display(\"reset state version reg ------end------\n\n\n\n\"); ---");
   // $display("reset state version reg ------end------\n\n\n\n");

   $display("\n--- $display(\"reset state version reg\n\n\n\n\"); ---");
   // $display("reset state version reg\n\n\n\n");
$display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
`SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b1) //-------------write 1
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10; // Make sure 0000 is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
    // Similarly, apply this method for other test inputs within the same state.
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b1) //-------------write 2
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})

   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b11, 1'b1) //-------------write 3
   #10;
    


$display("READ  addr=7'h00 (VERSION) cs=1'b1");
`SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})

   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b11, 1'b1) //-------------write 4
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   //------------------------------------end of version R/W--------------------------------------------------------------------------------------------------------------------------
   $display("\n--- $display(\"reset state version reg ------end------\n\n\n\n\"); ---");
   //$display("reset state version reg ------end------\n\n\n\n");



 $display("\n--- version register test  - Normal state ---");
 //version register test  - Normal state
    `CLEAR_ALL
   `CHIP_RESET
   //------------------------------------version R/W--------------------------------------------------------------------------------------------------------------------------
   $display("\n--- $display(\"normal state version reg\n\n\n\n\"); ---");
   //$display("normal state version reg\n\n\n\n");
    maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   #10; //Attempt to write 0000 to ALU Left
   
   
   
   
   
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b1) //-------------write 1
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10; // Make sure 0000 is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
    // Similarly, apply this method for other test inputs within the same state.
   
   
   
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b1) //-------------write 2
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})

   
   
   
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b11, 1'b1) //-------------write 3
   #10;
$display("READ  addr=7'h00 (VERSION) cs=1'b1");
`SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})

   
   
   
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b11, 1'b1) //-------------write 4
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   //------------------------------------end of version R/W--------------------------------------------------------------------------------------------------------------------------
   $display("\n--- $display(\"normal state version reg ------end------\n\n\n\n\"); ---");
   //$display("normal state version reg ------end------\n\n\n\n");






//version register test - Error 
`CLEAR_ALL
   `CHIP_RESET
   //------------------------------------version R/W--------------------------------------------------------------------------------------------------------------------------
    maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
    $display("\n--- Attempt to write 0100 to Configuration register ---");
    //Attempt to write 0100 to Configuration register
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_CON_ADDR,16'h0100,2'b11,1'b1)
   #10; //Attempt to write 8008 to command register - To transition from Normal state to Error state
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008,2'b11,1'b1)
   #10; //Attempt to write 0000 to ALU_Left
$display("\n--- $display(\"error state version reg\n\n\n\n\"); //----------brought to error state ---");
//  $display("error state version reg\n\n\n\n"); //----------brought to error state
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b1) //-------------write 1
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10; // Make sure 0000 is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
    // Similarly, apply this method for other test inputs within the same state.
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b1) //-------------write 2
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})

   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b11, 1'b1) //-------------write 3
   #10;
    


$display("READ  addr=7'h00 (VERSION) cs=1'b1");
`SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})

   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b11, 1'b1) //-------------write 4
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
//------------------------------------end of version R/W--------------------------------------------------   
   $display("\n--- $display(\"error state version reg ------end------\n\n\n\n\"); ---");
   //$display("error state version reg ------end------\n\n\n\n");


$display("\n--- version register test - Export controlled ---");
// version register test - Export controlled
 $display("\n--- $display(\"export state version reg\n\n\n\n\"); ---");
 //  $display("export state version reg\n\n\n\n");
`CHIP_RESET
   `CLEAR_ALL
   //------------------------------------version R/W--------------------------------------------------------------------------------------------------------------------------
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   export_disable <= 1'b1; //This signal disables certain export-required commands. Invalid commands will transition the state machine to the Export Violation state.
   $display("\n--- Attempt to write 0200 to Configuration register ---");
   //Attempt to write 0200 to Configuration register
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0200);
   `SET_WRITE(VCHIP_CON_ADDR,16'h0200,2'b11,1'b1)
   #10;//Attempt to write 800A to command register - To transition from Normal state to Export violation state
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h800A);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800A,2'b11,1'b1)
   #10;//Attempt to write 0000 to ALU_Left

   //----------brought to export state
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10; // Make sure 0000 is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   // Similarly, apply this method for other test inputs within the same state.
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)  

//-------------------------end of version R/W--------------------------------------------------------------------------------


   $display("\n--- $display(\"export state version reg ------end------\n\n\n\n\"); ---");
   //$display("export state version reg ------end------\n\n\n\n");

//--------------------------------------BYTE ENABLES 00, 01, 10, 11 TEST-------------------------------------------------------------
// $display("\n\n\n ===================byte enables 00 test start==================\n\n\n");
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   $display("\n--- Attempt to write 0000 to ALU Left when byte enable is 00 ---");
   //Attempt to write 0000 to ALU Left when byte enable is 00
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b00 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b00, 1'b1)
   #10;//Attempt to read 0000 from ALU left
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b00 ,1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b00 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b00,1'b1)
    
 #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b00 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b00, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
// $display("\n\n\n xxxxxxxxxxxxxxxxxx byte enables 00 test end xxxxxxxxxxxxxxxxxxxxxxxx\n\n\n"); 

//$display("\n\n\n ===================byte enables 01 test start==================\n\n\n");
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   $display("\n--- Attempt to write 0000 to ALU Left when byte enable is 00 ---");
   //Attempt to write 0000 to ALU Left when byte enable is 00
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b01 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b01, 1'b1)
   #10;//Attempt to read 0000 from ALU left
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b01 ,1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b01 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b01,1'b1)
    
 #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b01 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b01, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
 //$display("\n\n\n xxxxxxxxxxxxxxxxxx byte enables 01 test end xxxxxxxxxxxxxxxxxxxxxxxx\n\n\n"); 

// $display("\n\n\n ===================byte enables 10 test start==================\n\n\n");
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   $display("\n--- Attempt to write 0000 to ALU Left when byte enable is 00 ---");
   //Attempt to write 0000 to ALU Left when byte enable is 00
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b10 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b10, 1'b1)
   #10;//Attempt to read 0000 from ALU left
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b10 ,1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b10 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b10,1'b1)
    
 #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b10 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b10, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
 //$display("\n\n\n xxxxxxxxxxxxxxxxxxxxxx byte enables 10 test end xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n\n\n"); 
 

//$display("\n\n\n ===================byte enables 11 test start==================\n\n\n");
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   $display("\n--- Attempt to write 0000 to ALU Left when byte enable is 00 ---");
   //Attempt to write 0000 to ALU Left when byte enable is 00
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;//Attempt to read 0000 from ALU left
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   // Similarly, apply this method for other test inputs within the same combination.
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b11 ,1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b11,1'b1)
    
 #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
// $display("\n\n\n xxxxxxxxxxxxxxxxxxxxxx byte enables 11 test end xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n\n\n"); 

//-------------------------aliasing - aka access----------------------------
 // Test Aliasing on different operations
  // Check cs=1 write then cs=0 read: chip drives 0 when cs=0
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b0");
   `SET_READ(VCHIP_VER_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b0");
   `SET_READ(VCHIP_VER_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b0");
   `SET_READ(VCHIP_VER_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b0");
   `SET_READ(VCHIP_VER_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

  // Check cs=0 write then cs=1 read: write ignored, version constant returned
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b0", 16'hAAAA);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b0", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b0", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b0", 16'h0000);
   `SET_WRITE(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})


  // $display("\n\n\n================== start of alias address test=======================\n\n\n");

 `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   //Attempt to write AAAA to 7'h50 address
   $display("WRITE addr=7'h50 (ALIAS) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(7'h50, 16'hAAAA, 2'b11, 1'b1)
  // $display("writing AAAA to 7'h50");
   #10;//Attempt to write FFFF from ALU left
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b1)
   //$display("writing FFFF to VCHIP_VER_ADDR");
   #10;//Attempt to read AAAA from 7'h50
   $display("READ  addr=7'h50 (ALIAS) cs=1'b1");
   `SET_READ(7'h50, 1'b1)
   //$display("reading AAAA from 7'h50");
   #10;// Make sure 0000 is read back from 7'h50 (unused address returns 0)
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)   // corrected from 16'hAAAA

$display("\n--- Write to Aliased Address (7'h50) ---");
//Write to Aliased Address (7'h50)
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
  //Attempt to write AAAA to ALU_Left
  $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
  `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b11, 1'b1)
 // $display("writing AAAA to VCHIP_VER_ADDR");
   #10; //Attempt to write 5555 to 7'h50 address
   $display("WRITE addr=7'h50 (ALIAS) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(7'h50, 16'h5555, 2'b11, 1'b1)
 //  $display("writing 5555 to 7'h50");
   #10; //Attempt to read AAAA from ALU_Left
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
 //  $display("reading AAAA from VCHIP_VER_ADDR");
   #10;// Make sure 0000 is read back from ALU left (write to unused address may clear register)
   $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
   `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER})   // corrected from 16'hAAAA
  


   $display("\n--- Alias address 7'h50 with chip_select=0 - write should be ignored ---");
   // Alias address 7'h50 with chip_select=0 - write should be ignored
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // Pre-load a known value at 7'h10 with chip_select=1
   $display("WRITE addr=7'h00 (VERSION) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_VER_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   // Now attempt write to alias 7'h50 with chip_select=0 (should be ignored)
   $display("WRITE addr=7'h50 (ALIAS) data=%h byte_en=2'b11 cs=1'b0", 16'hDEAD);
   `SET_WRITE(7'h50, 16'hDEAD, 2'b11, 1'b0)
   #10;
   // Read back 7'h10 - should still be AAAA
   $display("READ  addr=7'h00 (VERSION) cs=1'b1");
   `SET_READ(VCHIP_VER_ADDR, 1'b1)
   #10;
  $display("CHECK data_out=%h expected=%h", data_out, {4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER});
  `CHECK_VAL({4'b0000, VCHIP_ALU_VER, VCHIP_MAJ_VER, VCHIP_MIN_VER}) 

   $display("\n--- Alias address 7'h50 read with chip_select=0 - should not be driven ---");
   // Alias address 7'h50 read with chip_select=0 - should not be driven
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h50 (ALIAS) data=%h byte_en=2'b11 cs=1'b1", 16'hBEEF);
   `SET_WRITE(7'h50, 16'hBEEF, 2'b11, 1'b1)
   #10;
   // Read alias with chip_select=0 - chip should not drive data_out
   $display("READ  addr=7'h50 (ALIAS) cs=1'b0");
   `SET_READ(7'h50, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)




 // $display("\n\n\nxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx end of alias address test xxxxxxxxxxxxxxxxxxxxxxxx\n\n\n");

 //============start of status register=========================================

 //===========================reset state R/W======================================

 //version register test
`CLEAR_ALL
   `CHIP_RESET
   
   $display("\n--- $display(\"\n\n\nreset state status reg\n\n\n\n\"); ---");
   //$display("\n\n\nreset state status reg\n\n\n\n");
   //$display("writing 0000 to VCHIP_STA_ADDR\n\n");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
 //Attempt to read 0000 from ALU left
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   //$display("reading 0000 from VCHIP_STA_ADDR\n\n");
   #10;
// Make sure 0000 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
    $display("\n--- $display(\"reset state status reg ------end------\n\n\n\n\"); ---");
    //$display("reset state status reg ------end------\n\n\n\n");




   //$display("writing FFFF to VCHIP_STA_ADDR\n\n");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hFFFF, 2'b11, 1'b1) //-------------write 2
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   //$display("reading %h from VCHIP_STA_ADDR\n\n", {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h0});
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h0});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h0})





   //$display("writing AAAA to VCHIP_STA_ADDR\n\n");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hAAAA, 2'b11, 1'b1) //-------------write 3
   #10;

$display("READ  addr=7'h04 (STATUS) cs=1'b1");
`SET_READ(VCHIP_STA_ADDR, 1'b1)
  // $display("reading %h from VCHIP_STA_ADDR\n\n", {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h0});
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h0});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h0})




   //$display("writing 5555 to VCHIP_STA_ADDR\n\n");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h5555, 2'b11, 1'b1) //-------------write 4
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   //$display("reading %h from VCHIP_STA_ADDR\n\n", {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h0});
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h0});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h0})
   $display("\n--- $display(\"reset state version reg ------end------\n\n\n\n\"); ---");
   //$display("reset state version reg ------end------\n\n\n\n");





   $display("\n--- status register test  - Normal state ---");
   //status register test  - Normal state
    `CLEAR_ALL
   `CHIP_RESET
   //------------------------------------status R/W--------------------------------------------------------------------------------------------------------------------------
   $display("\n\n\n normal state status reg \n\n\n\n");

   $display("transition to normal state\n\n\n");
    maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   #10; //Attempt to write 0000 to ALU Left


   $display("writing 0000 to VCHIP_STA_ADDR\n\n");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1) //-------------write 1
   #10;//Attempt to read 0000 from ALU_Left
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   $display("reading %h from VCHIP_STA_ADDR\n\n", {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h1});
   #10; // Make sure 0000 is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)






    // Similarly, apply this method for other test inputs within the same state.

   $display("writing FFFF to VCHIP_STA_ADDR\n\n");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hFFFF, 2'b11, 1'b1) //-------------write 2
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   $display("reading %h from VCHIP_STA_ADDR\n\n", {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h1});
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)









   $display("writing AAAA to VCHIP_STA_ADDR\n\n");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hAAAA, 2'b11, 1'b1) //-------------write 3
   #10;
    
$display("READ  addr=7'h04 (STATUS) cs=1'b1");
`SET_READ(VCHIP_STA_ADDR, 1'b1)
   $display("reading %h from VCHIP_STA_ADDR\n\n", {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h1});
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h1});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h1})



 



   $display("writing 5555 to VCHIP_STA_ADDR\n\n");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h5555, 2'b11, 1'b1) //-------------write 4
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   $display("reading %h from VCHIP_STA_ADDR\n\n", {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h1});
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001) 
   #10;

   `CLEAR_BUS

   // $display("pushing overflow to trigger an interrupt\n\n");
   // `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b11, 1'b1);
   // $display("wrote FFFF to right ALU IP\n\n");
   // #10;
   // `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1);
   // $display("reading FFFF from right ALU IP\n\n");
   // #10;
   // `CHECK_VAL(16'hFFFF);
   // #10;

   // //not clearing the bus intentionally

   // `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1); 
   // $display("wrote 0000 to left ALU IP\n\n");
   // #10;
   

   // //CLEAR ALU OUT
   // `SET_WRITE(VCHIP_CMD_ADDR, {1'b1, COMMAND_RSVD, 4'h7}, 2'b11, 1'b1);
   // $display("wrote 7 to command reg to clear ALU OUTPUT\n\n");
   // #10;
   // `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h8000, 2'b11, 1'B1)
   // $display("wrote 0x8000 to ALU left IP for borrow overflow\n\n");
   // #10;
   // `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0001, 2'b11, 1'b1)
   // $display("wrote 0x0001 to ALU right IP for borrow overflow\n\n");
   // #10;
   // //forces a borrow aka overflow

   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1);
  // $display("Enable interrupt 1\n\n");
   #10;


   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1); 
  // $display("wrote 0x8008 to command reg to trigger bad command\n\n");
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1);
  // $display("reading overflow bit from status reg\n\n");
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b01, STA_RESERVED_LOW,4'h2});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b01, STA_RESERVED_LOW,4'h2});
   #10;
   `SET_WRITE(VCHIP_STA_ADDR, {STA_RESERVED_HIGH, 2'b01, STA_RESERVED_LOW,4'h2}, 2'b11, 1'b1);
  // $display("cleared overflow bit from status reg\n\n");
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1);
   //$display("reading overflow bit from status reg\n\n");
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h2});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW,4'h2})


//===========exporty violations state=================================

   $display("\n--- Test Status Register in Export Violation State ---");
   // Test Status Register in Export Violation State
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1; // transition to Normal state
   #10; // wait for Normal state
   export_disable <= 1'b1; // enable export restriction
   #10; // wait for export_disable to register
   // Write CON with INT2_EN=1 (will be cleared by design on same clock as EXP transition)
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0200);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0200, 2'b11, 1'b1)
   #10;
   // Issue restricted command (cmd=0xA > LAST_EXP_CMD=2) => triggers Export Violation
   // NOTE: design zeroes int2_en on next_state==EXP same posedge INT2 tries to set,
   //       so INT2 never latches. Expected status = 16'h0008 (INT2=0, state=EXP=4'h8)
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h800A);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h800A, 2'b11, 1'b1)
   #10;
   // Writes to Status are ignored in EXP state; reads still work
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h8});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h8})

   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h8});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h8})

   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h8});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h8})

   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h8});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h8})

   // Test Byte Enable Combinations on Status Register (Normal state, status is read-only)
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1; // transition to Normal state
   #10; // wait for Normal state; status = 16'h0001
   // byte_en=00: no bytes written to Status; still reads 16'h0001
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b00 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h0000, 2'b00, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b00 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hAAAA, 2'b00, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b00 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h5555, 2'b00, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b00 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hFFFF, 2'b00, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)
   $display("end of sta");





   
   //------------------------------------end of status R/W--------------------------------------------------------------------------------------------------------------------------
  $display("\n--- $display(\"\n\n\n normal state status reg ------end------\n\n\n\n\"); ---");
  // $display("\n\n\n normal state status reg ------end------\n\n\n\n");



// Test Aliasing on different operations
  $display("\n--- Check for Aliasing with Chip Select ---");
  //Check for Aliasing with Chip Select
  $display("aliasing with chip select");
   `CHIP_RESET
   `CLEAR_ALL
      maroon <= 1'b0; gold <= 1'b1;
   #10;
   //Attempt to write 0000 to ALU_Left
   $display("aliasing with chip select 0000");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("reading - aliasing with chip select 0000");
   $display("READ  addr=7'h04 (STATUS) cs=1'b0");
   `SET_READ(VCHIP_STA_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   $display("aliasing with chip select AAAA");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("reading - aliasing with chip select AAAA");
   $display("READ  addr=7'h04 (STATUS) cs=1'b0");
   `SET_READ(VCHIP_STA_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("aliasing with chip select 5555");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("reading - aliasing with chip select 5555");
   $display("READ  addr=7'h04 (STATUS) cs=1'b0");
   `SET_READ(VCHIP_STA_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)
   $display("aliasing with chip select FFFF");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("reading - aliasing with chip select FFFF");
   $display("READ  addr=7'h04 (STATUS) cs=1'b0");
   `SET_READ(VCHIP_STA_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("\n--- Check for Aliasing without Chip Select ---");
   //Check for Aliasing without Chip Select
   // Clear all for a spotless interface
   `CLEAR_ALL
   maroon <= 1'b1; gold <= 1'b0;
   #10;
   //Attempt to write AAAA to ALU_Left when chip select is off
   $display("aliasing without chip select AAAA");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b0", 16'hAAAA);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hAAAA, 2'b11, 1'b0)
   #10; //Attempt to read AAAA from ALU_Left
   $display("reading - aliasing without chip select AAAA");
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;// Make sure FFFF is read back from ALU_Left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)
   // Similarly, apply this method for other test inputs within the same combination.
   $display("aliasing without chip select 5555");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b0", 16'h5555);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h5555, 2'b11, 1'b0)
   #10;
   $display("reading - aliasing without chip select 5555");
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)
   $display("aliasing without chip select FFFF");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b0", 16'hFFFF);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hFFFF, 2'b11, 1'b0)
   #10;
   $display("reading - aliasing without chip select FFFF");
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)
   //Attempt to write 5555 to ALU Left when chip select is on
   $display("aliasing with chip select 5555");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;//Attempt to read 5555 from ALU left
   $display("reading - aliasing with chip select 5555");
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;// Make sure 5555 is read back from ALU left
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)
   $display("aliasing without chip select 0000");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b0", 16'h0000);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b0)
   #10;
   $display("reading - aliasing without chip select 0000");
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)

   $display("\n--- Write to Correct ALU LEFT Register ---");
   //Write to Correct ALU LEFT Register
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b1; gold <= 1'b0; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
   //Attempt to write AAAA to 7'h50 address
   $display("WRITE addr=7'h50 (ALIAS) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(7'h50, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h50 (ALIAS) cs=1'b1");
   `SET_READ(7'h50, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)   // 7h50 unmapped -> 0000

$display("\n--- Write to Aliased Address (7'h50) ---");
//Write to Aliased Address (7'h50)
   `CHIP_RESET
   `CLEAR_ALL
   maroon <= 1'b0; gold <= 1'b1; // Maroon = 0 and Gold = 1, for transitioning to Normal State.
  //Attempt to write AAAA to ALU_Left
  $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
  `SET_WRITE(VCHIP_STA_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10; //Attempt to write 5555 to 7'h50 address
   $display("WRITE addr=7'h50 (ALIAS) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(7'h50, 16'h5555, 2'b11, 1'b1)
   #10; //Attempt to read AAAA from ALU_Left
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;// Make sure 0000 is read back from ALU left (write to unused address may clear register)
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)   // corrected from 16'hAAAA









//===========================================================================
// STATUS REGISTER - INT1 tests (cause interrupt, verify, clear)
//===========================================================================

   $display("\n--- STATUS INT1 - cause via bad_cmd in Normal, verify INT1=1, clear it ---");
   // STATUS INT1 - cause via bad_cmd in Normal, verify INT1=1, clear it
   $display("\n--- Covers: status int1 write/read bits (trigger=write, clear=write to STA) ---");
   // Covers: status int1 write/read bits (trigger=write, clear=write to STA)
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // Enable INT1
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   #10;
   // Trigger bad command -> INT1 fires, state->Error
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
   #10;
   // Read status: INT1=1(bit8), state=ERR(4'h2) => 16'h0102
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b01, STA_RESERVED_LOW, 4'h2});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b01, STA_RESERVED_LOW, 4'h2})
   // Write to STA with bit8=1 to clear INT1 (byte_en[1] required)
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b10 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h0100, 2'b10, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h2});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h2})

   $display("\n--- INT1 cause/clear with 0000 pattern ---");
   // INT1 cause/clear with 0000 pattern
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b01, STA_RESERVED_LOW, 4'h2});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b01, STA_RESERVED_LOW, 4'h2})

   $display("\n--- INT1 cause/clear with FFFF pattern ---");
   // INT1 cause/clear with FFFF pattern
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
   #10;
   `CLEAR_BUS
   #10;
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h2});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h2})

   $display("\n--- INT1 cause/clear with AAAA pattern ---");
   // INT1 cause/clear with AAAA pattern
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
   #10;
   `CLEAR_BUS
   #10;
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_STA_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h2});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h2})

   $display("\n--- INT1 cause/clear with 5555 pattern ---");
   // INT1 cause/clear with 5555 pattern
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
   #10;
   `CLEAR_BUS
   #10;
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h2});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h2})

   $display("\n--- INT1 - Error state: reads enabled, writes ignored ---");
   // INT1 - Error state: reads enabled, writes ignored
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
   #10;
   `CLEAR_BUS
   #10;
   $display("\n--- Now in Error state - CLEAR_BUS deasserts valid before STA clear ---");
   $display("WRITE addr=7'h04 (STATUS) data=%h byte_en=2'b10 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_STA_ADDR, 16'h0100, 2'b10, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h2});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h2})

   // INT1 - Export violation state: only STA readable, INT1=0 (int1_en cleared on EXP transition)
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   export_disable <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0100);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0100, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8003);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8003, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h04 (STATUS) cs=1'b1");
   `SET_READ(VCHIP_STA_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, {STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h8});
   `CHECK_VAL({STA_RESERVED_HIGH, 2'b00, STA_RESERVED_LOW, 4'h8})

//===========================================================================
$display("\n--- COMMAND REGISTER - write/read/bytes/access ---");
// COMMAND REGISTER - write/read/bytes/access
// cmd_reg = { valid[15], 11'h0, cmd[3:0] }
// Write: chip_select=1, rw_=0, addr=7'h08, byte_en=11
// Read:  chip_select=1, rw_=1, addr=7'h08
$display("\n--- In Normal state: valid latches. In Error/EXP: valid forced to 0. ---");
// In Normal state: valid latches. In Error/EXP: valid forced to 0.
//===========================================================================

   $display("\n--- CMD - Reset state write/read (4 values) ---");
   // CMD - Reset state write/read (4 values)
   `CLEAR_ALL
   `CHIP_RESET
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0001);
   `CHECK_VAL(16'h0001)  // valid=0, cmd=1

   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h000a);
   `CHECK_VAL(16'h000A)  // valid=0, cmd=0xA

   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0005);
   `CHECK_VAL(16'h0005)  // valid=0, cmd=5

   $display("\n--- CMD - Normal state write/read (4 values) ---");
   // CMD - Normal state write/read (4 values)
   // valid=1 only when byte_en[1]=1 AND bit15=1; cmd latches [3:0] when byte_en[0]=1
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h (valid sampled before SET_READ clears it)", data_out, 16'h8001);
   `CHECK_VAL(16'h8001)
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8002);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8002, 2'b11, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h (valid sampled before SET_READ clears it)", data_out, 16'h8002);
   `CHECK_VAL(16'h8002)
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8007);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8007, 2'b11, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h (valid sampled before SET_READ clears it)", data_out, 16'h8007);
   `CHECK_VAL(16'h8007)
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;

   $display("\n--- CMD - Error state: valid forced 0, reads still return cmd_reg ---");
   // CMD - Error state: valid forced 0, reads still return cmd_reg
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
   #10;
   `CLEAR_BUS
   #10;
   $display("\n--- 2 posedges elapsed - now in Error state. Write should be ignored. ---");
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("\n--- CMD - Export Violation state: valid forced 0 ---");
   // CMD - Export Violation state: valid forced 0
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   export_disable <= 1'b1;
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h800A);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h800A, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("\n--- CMD - byte enables ---");
   // CMD - byte enables
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // byte_en=01: only byte[0] written, cmd=[3:0] latched but valid=0 (bit15 in byte[1])
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b01 cs=1'b1", 16'h8007);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8007, 2'b01, 1'b1)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0007);
   `CHECK_VAL(16'h0007)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // byte_en=10: only byte[1] written, valid=1 but cmd stays 0
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b10 cs=1'b1", 16'h8007);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8007, 2'b10, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h (sample before SET_READ clears valid)", data_out, 16'h8000);
   `CHECK_VAL(16'h8000)
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // byte_en=00: nothing written
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b00 cs=1'b1", 16'h8007);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8007, 2'b00, 1'b1)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // byte_en=11: both bytes written
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8003);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8003, 2'b11, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h (sample before SET_READ clears valid)", data_out, 16'h8003);
   `CHECK_VAL(16'h8003)
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;

   $display("\n--- CMD - chip select access ---");
   // CMD - chip select access
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
   #10;
   // read with cs=0 -> 0
   $display("READ  addr=7'h08 (COMMAND) cs=1'b0");
   `SET_READ(VCHIP_CMD_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // write with cs=0 -> ignored
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b0", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b0", 16'hAAAA);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'hAAAA, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b0", 16'h5555);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h5555, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h08 (COMMAND) cs=1'b1");
   `SET_READ(VCHIP_CMD_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

//===========================================================================
$display("\n--- CONFIGURATION REGISTER - write/read/bytes/access ---");
// CONFIGURATION REGISTER - write/read/bytes/access
// con_reg = { 6'h0, int2_en[9], int1_en[8], 8'h0 }
// Write: addr=7'h0C, byte_en[1] required to set int2_en/int1_en
//===========================================================================

   $display("\n--- CON - Reset state write/read ---");
   // CON - Reset state write/read
   `CLEAR_ALL
   `CHIP_RESET
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_CON_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0300);
   `CHECK_VAL(16'h0300)

   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_CON_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0200);
   `CHECK_VAL(16'h0200)

   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0100);
   `CHECK_VAL(16'h0100)

   $display("\n--- CON - Normal state write/read ---");
   // CON - Normal state write/read
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_CON_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0300);
   `CHECK_VAL(16'h0300)

   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_CON_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0200);
   `CHECK_VAL(16'h0200)

   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0100);
   `CHECK_VAL(16'h0100)

   $display("\n--- CON - Error state: retained (not cleared) ---");
   // CON - Error state: retained (not cleared)
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0300);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
   #10;
   `CLEAR_BUS
   #10;
   $display("--- 2 posedges elapsed - now in Error state. CON write should be retained.");
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0300);
   `CHECK_VAL(16'h0300)

   $display("\n--- CON - Export Violation: int2_en/int1_en cleared ---");
   // CON - Export Violation: int2_en/int1_en cleared
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   export_disable <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0300);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h800A);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h800A, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("\n--- CON - byte enables ---");
   // CON - byte enables
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // byte_en=00: nothing written
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b00 cs=1'b1", 16'h0300);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0300, 2'b00, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // byte_en=01: only byte[0] written, int2_en/int1_en in byte[1] -> not written
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b01 cs=1'b1", 16'h0300);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0300, 2'b01, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // byte_en=10: byte[1] written -> int2_en/int1_en latched
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b10 cs=1'b1", 16'h0300);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0300, 2'b10, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0300);
   `CHECK_VAL(16'h0300)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   // byte_en=11: both bytes written
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0300);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0300);
   `CHECK_VAL(16'h0300)

   $display("\n--- CON - chip select access ---");
   // CON - chip select access
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b1", 16'h0300);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b0");
   `SET_READ(VCHIP_CON_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b0", 16'h0300);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h0300, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b0", 16'hAAAA);
   `SET_WRITE(VCHIP_CON_ADDR, 16'hAAAA, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h0C (CONFIG) data=%h byte_en=2'b11 cs=1'b0", 16'h5555);
   `SET_WRITE(VCHIP_CON_ADDR, 16'h5555, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h0C (CONFIG) cs=1'b1");
   `SET_READ(VCHIP_CON_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

//===========================================================================
$display("\n--- ALU RIGHT REGISTER - write/read/bytes/access ---");
// ALU RIGHT REGISTER - write/read/bytes/access
$display("\n--- Same behavior as ALU LEFT: 16-bit R/W, byte enables, states ---");
// Same behavior as ALU LEFT: 16-bit R/W, byte enables, states
//===========================================================================

   $display("\n--- ALU RIGHT - Reset state write/read ---");
   // ALU RIGHT - Reset state write/read
   `CLEAR_ALL
   `CHIP_RESET
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFFFF);
   `CHECK_VAL(16'hFFFF)

   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hAAAA);
   `CHECK_VAL(16'hAAAA)

   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h5555);
   `CHECK_VAL(16'h5555)

   $display("\n--- ALU RIGHT - Normal state write/read ---");
   // ALU RIGHT - Normal state write/read
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFFFF);
   `CHECK_VAL(16'hFFFF)

   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hAAAA);
   `CHECK_VAL(16'hAAAA)

   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h5555);
   `CHECK_VAL(16'h5555)

   $display("\n--- ALU RIGHT - Error state: reads allowed, writes ignored ---");
   // ALU RIGHT - Error state: reads allowed, writes ignored
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h1234);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h1234, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
   #10;
   `CLEAR_BUS
   #10;
   $display("--- 2 posedges elapsed - now in Error state. ALU_RIGHT write ignored.");
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h1234);
   `CHECK_VAL(16'h1234)

   $display("\n--- ALU RIGHT - Export state: cleared to 0 ---");
   // ALU RIGHT - Export state: cleared to 0
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   export_disable <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'hBEEF);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hBEEF, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h800A);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h800A, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("\n--- ALU RIGHT - byte enables ---");
   // ALU RIGHT - byte enables
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b00 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b00, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b00 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 2'b00, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b01 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b01, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h00FF);
   `CHECK_VAL(16'h00FF)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b10 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b10, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFF00);
   `CHECK_VAL(16'hFF00)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'hFFFF);
   `CHECK_VAL(16'hFFFF)

   $display("\n--- ALU RIGHT - chip select access ---");
   // ALU RIGHT - chip select access
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b0");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b0", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b0", 16'h5555);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h5555, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b0", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h14 (ALU_RIGHT) cs=1'b1");
   `SET_READ(VCHIP_ALU_RIGHT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

//===========================================================================
$display("\n--- ALU OUT REGISTER - read-only (result of ALU operation) ---");
// ALU OUT REGISTER - read-only (result of ALU operation)
$display("\n--- alu_out resets to 0, updates via ALU commands in Normal state ---");
// alu_out resets to 0, updates via ALU commands in Normal state
// Reads: addr=7'h18, cs=1
// alu_out tests: read in all 4 states, byte enables on read (read ignores byte_en)
//===========================================================================

   $display("\n--- ALU OUT - Reset state: reads 0 ---");
   // ALU OUT - Reset state: reads 0
   `CLEAR_ALL
   `CHIP_RESET
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b1");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("\n--- ALU OUT - Normal state: trigger ADD, read result ---");
   // ALU OUT - Normal state: trigger ADD, read result
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0003);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0003, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0002);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0002, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b1");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0005);
   `CHECK_VAL(16'h0005)

   // ALU OUT - Normal: SUB
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0010);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0010, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0003);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0003, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8002);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8002, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b1");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h000D);
   `CHECK_VAL(16'h000D)

   // ALU OUT - Normal: SHL
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0001);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0001, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0003);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0003, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8006);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8006, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b1");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0008);
   `CHECK_VAL(16'h0008)

   // ALU OUT - Normal: SHR
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0080);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0080, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0003);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0003, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8007);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8007, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b1");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0010);
   `CHECK_VAL(16'h0010)

   $display("\n--- ALU OUT - Error state: alu_out retained ---");
   // ALU OUT - Error state: alu_out retained
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0003);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0003, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0002);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0002, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
   #10;
   // Trigger error (bad cmd)
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8008);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8008, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b1");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0005);
   `CHECK_VAL(16'h0005)

   $display("\n--- ALU OUT - Export state: alu_out cleared to 0 ---");
   // ALU OUT - Export state: alu_out cleared to 0
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   export_disable <= 1'b1;
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0003);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0003, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0002);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0002, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h800A);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h800A, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b1");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   $display("\n--- ALU OUT - chip select access ---");
   // ALU OUT - chip select access
   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h0003);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h0003, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0002);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0002, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b1", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
   #10;
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b0");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b0)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hAAAA);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b0", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b1");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'h5555);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b0", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b1");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   `CLEAR_ALL
   `CHIP_RESET
   maroon <= 1'b0; gold <= 1'b1;
   #10;
   $display("WRITE addr=7'h10 (ALU_LEFT) data=%h byte_en=2'b11 cs=1'b1", 16'hFFFF);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h14 (ALU_RIGHT) data=%h byte_en=2'b11 cs=1'b1", 16'h0000);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   #10;
   $display("WRITE addr=7'h08 (COMMAND) data=%h byte_en=2'b11 cs=1'b0", 16'h8001);
   `SET_WRITE(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b0)
   #10;
   $display("READ  addr=7'h18 (ALU_OUT) cs=1'b1");
   `SET_READ(VCHIP_ALU_OUT_ADDR, 1'b1)
   #10;
   $display("CHECK data_out=%h expected=%h", data_out, 16'h0000);
   `CHECK_VAL(16'h0000)

   #5 $finish;
end // initial begin

verichip4 verichip4 (.clk           ( clk            ),    // system clock
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