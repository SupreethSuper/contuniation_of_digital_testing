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

localparam ONE = 1'b1;
localparam ZERO = 1'b0;

task check_state;
begin
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk == 1'b1);
   #1;

   case (data_out[3:0])
      4'h0: $display("STATE = RESET");
      4'h1: $display("STATE = NORMAL");
      4'h2: $display("STATE = eRR");
      4'h8: $display("STATE = EXPORT");
      4'hF: $display("STATE = LOST");
      default: $display("STATE = UNKNOWN");
   endcase

   `CLEAR_BUS
end
endtask

task automatic alu_write(
    input logic [15:0] left_val,
    input logic [15:0] right_val,
    input logic [15:0] cmmd
);
begin
   // write left
   wait(clk == ONE);
   wait(clk == ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR, left_val, 2'b11, 1'b1)
   wait(clk == ONE);
   wait(clk == ZERO);
   `CLEAR_BUS

   // write right
   wait(clk == ONE);
   wait(clk == ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR, right_val, 2'b11, 1'b1)
   wait(clk == ONE);
   wait(clk == ZERO);
   `CLEAR_BUS
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,cmmd,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

end
endtask

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

   // YOUR STIMULUS GOES HERE!
   
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);

   // RESET STATE TESTS 
   
   $display ("RESET STATE");
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hFFFF)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h5555)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hAAAA)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // ENTER NORMAL STATE
   
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   // NORMAL STATE VALUE TESTS

   $display ("NORMAL STATE");
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hFFFF)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h5555)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hAAAA)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
    
   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // BYTE ENABLE COVERAGE
   
   $display ("BYTE coverage");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'h1234,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   // low byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hAAAA,2'b01,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h12AA)
   $display("value is %h at addrs  %h for byte check 01 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // high byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hBB00,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hBBAA)
   $display("value is %h at addrs  %h for byte check 10 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // 00 (no write)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hFFFF,2'b00,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hBBAA)
   $display("value is %h at addrs  %h for byte check 00 time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // ENTER eRR STATE

   $display("Err State");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
    wait(clk==ZERO);
    wait(clk==ONE);
    
   // Attempt write in eRR STATE (should not change)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hBBAA)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // EXPORT STATE
   
   $display("EXPT STATE");
   
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   export_disable <= 1'b1;
   wait(clk==ONE);
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   wait(clk==ONE); 
   
   // Attempt write in EXPORT state (should be ignored)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Read should be disabled (0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // ALIAS TEST
   
   $display("ALLIAS");
    
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);
   
   // Write to LEFT
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Read RIGHT (should be unaffected)
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // write RIGHT only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hBBBB,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Read LEFT (should still be AAAA)
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hAAAA)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
    
   // attempt write with cs=0 (should do nothing)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'h1234,2'b11,1'b0)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Read LEFT after Chip select (should still be AAAA)
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hAAAA)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // read with cs = 0 (should return 0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b0)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // attempt write to invalid address
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h50,16'hDEAD,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // LEFT should remain unchanged
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hAAAA)
   wait(clk==ZERO);
   `CLEAR_BUS
    
    // read from unused address
   wait(clk==ZERO);
   `SET_READ(7'h7F,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Alias test: 0x10 <-> 0x50

   // Write base (0x10), read alias (0x50)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h10,16'hABCD,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(7'h50,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Write alias (0x50), read base (0x10)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h50,16'hDCBA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(7'h10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   //////////////////////////////////////////////////////
   //RIGHT ALU 
   //////////////////////////////////////////////////////
   
   $display ("  ");
   $display ("ALU RIGHT REG");
   
   `CLEAR_ALL
   `CHIP_RESET   
   
   $display ("RESET STATE");
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hFFFF)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

//check_state();

   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h5555)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hAAAA)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   /////////////////////////////////////////////////
   // ENTER NORMAL STATE
   /////////////////////////////////////////////////
   
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   // NORMAL STATE VALUE TESTS

   $display ("NORMAL STATE");

   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hFFFF)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

//check_state();

   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h5555)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hAAAA)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // BYTE ENABLE COVERAGE
   
   $display ("BYTE coverage");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'h1234,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   // low byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hAAAA,2'b01,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h12AA)
 //  $display("value is %h at addrs  %h for byte check 01 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // high byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hBB00,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hBBAA)
 //  $display("value is %h at addrs  %h for byte check 10 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // 00 (no write)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hFFFF,2'b00,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hBBAA)
 //  $display("value is %h at addrs  %h for byte check 00 time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // ENTER eRR STATE

   $display("Err State");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
    wait(clk==ZERO);
    wait(clk==ONE);
    
   // Attempt write in eRR STATE (should not change)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hBBAA)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   /////////////////////////////////
   // EXPORT STATE
   
   $display("EXPT STATE");
   
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   export_disable <= 1'b1;
   wait(clk==ONE);
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   wait(clk==ONE); 
   
   // Attempt write in EXPORT state (should be ignored)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Read should be disabled (0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
	
   ///////////////////////////////
   // ALIAS TEST
   
   $display("ALLIAS");
    
   `CHIP_RESET
   wait(clk==0);
   maroon <= 0;
   gold   <= 1;
   wait(clk==1'b1);
   wait(clk==0);
   
   // Write to RIGHT
   wait(clk==1);
   wait(clk==0);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==1'b1);
   wait(clk==0);
   `CLEAR_BUS
   
   // Read LEFT (should be unaffected)
   wait(clk==0);
   `SET_READ(VCHIP_ALU_LEFT_ADDR,1'b1)
   wait(clk==1'b1);
   #1 `CHECK_VAL(16'h0000)
 //  $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==0);
   `CLEAR_BUS
   
   // write to LEFT 
   wait(clk==1);
   wait(clk==0);
   `SET_WRITE(VCHIP_ALU_LEFT_ADDR,16'hBBBB,2'b11,1'b1)
   wait(clk==1'b1);
   wait(clk==0);
   `CLEAR_BUS
    
   // Read RIGHT (should still be AAAA)
   wait(clk==0);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==1'b1);
   #1 `CHECK_VAL(16'hAAAA)
 //  $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==0);
   `CLEAR_BUS
    
   // attempt write with cs=0 (should do nothing)
   wait(clk==1);
   wait(clk==0);
   `SET_WRITE(VCHIP_ALU_RIGHT_ADDR,16'h1234,2'b11,1'b0)
   wait(clk==1'b1);
   wait(clk==0);
   `CLEAR_BUS
    
   // Read RIGHT after Chip select (should still be AAAA)
   wait(clk==0);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==1'b1);
   #1 `CHECK_VAL(16'hAAAA)
//   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==0);
   `CLEAR_BUS
   
   // read with cs = 0 (should return 0)
   wait(clk==0);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b0)
   wait(clk==1);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==0);
   `CLEAR_BUS
    
   // attempt write to invalid address
   wait(clk==1);
   wait(clk==0);
   `SET_WRITE(7'h50,16'hDEAD,2'b11,1'b1)
   wait(clk==1);
   wait(clk==0);
   `CLEAR_BUS
    
   // LEFT should remain unchanged
   wait(clk==0);
   `SET_READ(VCHIP_ALU_RIGHT_ADDR,1'b1)
   wait(clk==1);
   #1 `CHECK_VAL(16'hAAAA)
   wait(clk==0);
   `CLEAR_BUS
    
    // read from unused address
   wait(clk==0);
   `SET_READ(7'h7F,1'b1)
   wait(clk==1);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==0);
   `CLEAR_BUS
   
   // RIGHT alias test: 0x14 <-> 0x54
   
   // Write base (0x14), read alias (0x54)
   wait(clk==1);
   wait(clk==0);
   `SET_WRITE(7'h14,16'hABCD,2'b11,1'b1)
   wait(clk==1);
   wait(clk==0);
   `CLEAR_BUS
   
   wait(clk==0);
   `SET_READ(7'h54,1'b1)
   wait(clk==1);
   wait(clk==0);
   `CLEAR_BUS
   
   // Write alias (0x54), read base (0x14)
   wait(clk==1);
   wait(clk==0);
   `SET_WRITE(7'h54,16'hDCBA,2'b11,1'b1)
   wait(clk==1);
   wait(clk==0);
   `CLEAR_BUS
   
   wait(clk==0);
   `SET_READ(7'h14,1'b1)
   wait(clk==1);
   wait(clk==0);
   `CLEAR_BUS
   
   //////////////////////////////////////////////////////////
   ///////////      VERSION REGESTER            /////////////
   //////////////////////////////////////////////////////////

   $display("   ");
   $display("VERSION REGESTER");

   `CLEAR_ALL
   `CHIP_RESET
   
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);

   // RESET STATE READ
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   //#1 `CHECK_VAL(16'h0000)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   //NORMAL STATE READ

   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 $display("value is %h at addrs %h at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS
	
   //eRR STATE READ and write
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   wait(clk==ONE);

   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 $display("value is %h at addrs %h at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   $display ("RESET STATE WRITE TEST");
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS


   //////Version Protection test//////
	
   //RESET STATE WRITE TEST
	
   `CLEAR_ALL
   `CHIP_RESET
   wait(clk==ZERO);
   $display ("RESET STATE WRITE TEST");
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);

   wait(clk==ONE);
   wait(clk==ZERO);

   `SET_WRITE(VCHIP_VER_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS
   
//check_state();

   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS
 
   //NORMAL STATE WRITE TEST

   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= ZERO;
   gold   <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   wait(clk==ONE);

   $display ("NORMAL WRITE TEST");
   // 00FF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // 0055
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // 00AA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS
   
   /////////////////////////////////////////
   // BYTE ENABLE COVERAGE
   
   $display ("BYTE coverage");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'h1234,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   // low byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'hAAAA,2'b01,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h for byte check 01 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // high byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'hBB00,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h for byte check 10 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // 00 (no write)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'hFFFF,2'b00,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0210)
   $display("value is %h at addrs  %h for byte check 00 time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

//check_state();

   ///////////////////////////////
   // EXPORT STATE
   
   $display("EXPT STATE");
   
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   export_disable <= 1'b1;
   wait(clk==ONE);
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);

   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
 
   wait(clk==ZERO);
   wait(clk==ONE); 
 
//check_state();

   // Attempt write in EXPORT state (should be ignored)
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_VER_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Read should be disabled (0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   //ALIASING ACCESS TEST

   $display("ALLIAS");
    
   `CHIP_RESET
   wait(clk==0);
   maroon <= 0;
   gold   <= 1;
   wait(clk==1'b1);
   wait(clk==0);

    //check_state();
    
    // VERSION alias test (0x00 <-> 0x40)
    
    // Read base address (0x00)
    wait(clk==ONE);
    wait(clk==ZERO);
    `SET_READ(7'h00,1'b1)
    wait(clk==ONE);
    wait(clk==ZERO);
    `CLEAR_BUS
    
    // Read alias address (0x40)
    wait(clk==ZERO);
    `SET_READ(7'h40,1'b1)
    wait(clk==ONE);
    wait(clk==ZERO);
    `CLEAR_BUS
    
    // Write attempt at alias (should not change)
    wait(clk==ONE);
    wait(clk==ZERO);
    `SET_WRITE(7'h40,16'hDEAD,2'b11,1'b1)
    wait(clk==ONE);
    wait(clk==ZERO);
    `CLEAR_BUS
    
    // Read base again
    wait(clk==ZERO);
    `SET_READ(7'h00,1'b1)
    wait(clk==ONE);
    wait(clk==ZERO);
    `CLEAR_BUS

   // attempt write with cs=0 (should do nothing)
   wait(clk==1);
   wait(clk==0);
   `SET_WRITE(VCHIP_VER_ADDR,16'h1234,2'b11,1'b0)
   wait(clk==1'b1);
   wait(clk==0);
   `CLEAR_BUS
    
   // Read RIGHT after Chip select (should still be AAAA)
   wait(clk==0);
   `SET_READ(VCHIP_VER_ADDR,1'b1)
   wait(clk==1'b1);
   #1 `CHECK_VAL(16'h8210)
//   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==0);
   `CLEAR_BUS
   
   // read with cs = 0 (should return 0)
   wait(clk==0);
   `SET_READ(VCHIP_VER_ADDR,1'b0)
   wait(clk==1);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==0);
   `CLEAR_BUS

//////////////////////////////////////////
///////    Status Register      //////////
//////////////////////////////////////////

   $display ("  ");
   $display ("STATUS REGESTER");

   `CLEAR_ALL
   `CHIP_RESET

   // YOUR STIMULUS GOES HERE!
   
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);

   // RESET STATE TESTS 
   
   $display ("RESET STATE");
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // ENTER NORMAL STATE
   
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   // NORMAL STATE VALUE TESTS

   $display ("NORMAL STATE");
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0001)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0001)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0001)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
    
   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0001)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // BYTE ENABLE COVERAGE
   
   $display ("BYTE coverage");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'h1234,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   // low byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'hAAAA,2'b01,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0001)
   $display("value is %h at addrs  %h for byte check 01 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // high byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'hBB00,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0001)
   $display("value is %h at addrs  %h for byte check 10 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // 00 (no write)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'hFFFF,2'b00,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0001)
   $display("value is %h at addrs  %h for byte check 00 time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // ENTER eRR STATE

   $display("Err State");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
    wait(clk==ZERO);
    wait(clk==ONE);
    
   // Attempt write in eRR STATE (should not change)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0002)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time()); 
   wait(clk==ZERO);
   `CLEAR_BUS

   // EXPORT STATE
   
   $display("EXPT STATE");
   
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   export_disable <= 1'b1;
   wait(clk==ONE);
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   wait(clk==ONE); 
   
   // Attempt write in EXPORT state (should be ignored)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Read should be disabled (0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0008)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // ALIAS TEST
   
   $display("ALLIAS");
    
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);
   
   // attempt write with cs=0 (should do nothing)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'h1234,2'b11,1'b0)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Read LEFT after Chip select (should still be AAAA)
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0001)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // read with cs = 0 (should return 0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b0)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Write base (0x04), read alias (0x44)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h04,16'hABCD,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(7'h44,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Write alias (0x44), read base (0x04)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h44,16'hDCBA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(7'h04,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   ////////////////////////////////
   //Interrupt test
   
   //check_state();
        
   $display(" ");
   $display("INT1 COMPLETE TEST");
    
   //////////////
   // RESET STATE : INT1 = 0
    
   `CLEAR_ALL
   `CHIP_RESET
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);
    
   //check_state();
    
   // try bad command while still in RESET
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);
      
   // expect RESET, INT1 = 0
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
      
   /////////////
   // NORMAL STATE : INT1 = 0
      
   `CLEAR_ALL
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= ZERO;
   gold   <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
   
   //check_state();
   
   // expect NORMAL, INT1 = 0
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0001)
   wait(clk==ZERO);
   `CLEAR_BUS
    
   //////////////////
   // NORMAL STATE : INT1 = 1
   // set INT1 in NORMAL, enter eRR, recover to NORMAL
    
   $display("in nor");
   `CLEAR_ALL
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= ZERO;
   gold   <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // enable INT1
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'h0100,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // bad command sets INT1 and enters eRR
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
      
   // recover eRR to NORMAL with INT1 still set
   maroon <= ONE;
   gold   <= ZERO;
   wait(clk==ONE);
   wait(clk==ZERO);
     
   //check_state();
     
   // expect NORMAL + INT1
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0101)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   wait(clk==ZERO);
   `CLEAR_BUS
      
   /////////////
   //NORMAL STATE : clear INT1 while in NORMAL
      
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'h0100,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
     
   //check_state();
     
   // expect NORMAL, INT1 cleared
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0001)
   wait(clk==ZERO);
   `CLEAR_BUS
   
   ///////////
   //eRR STATE : INT1 = 0
   
   `CLEAR_ALL
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= ZERO;
   gold   <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // INT1 disabled, bad command -> eRR only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   //check_state();
   
   // expect eRR, INT1 = 0
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0002)
   wait(clk==ZERO);
   `CLEAR_BUS
   
   ////////////
   //eRR STATE : INT1 = 1
    
   `CLEAR_ALL
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= ZERO;
   gold   <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // enable INT1
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'h0100,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // bad command sets INT1 and enters eRR
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   //check_state();
    
   // expect eRR + INT1
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0102)
   wait(clk==ZERO);
   `CLEAR_BUS
    
   ///////////
   //eRR STATE : clear INT1 while in eRR
    
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'h0100,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   //check_state();
    
   // expect eRR, INT1 cleared
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0002)
   wait(clk==ZERO);
   `CLEAR_BUS
    
   ///////////
   //EXPORT STATE : INT1 = 0
    
   `CLEAR_ALL
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= ZERO;
   gold   <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
   
   export_disable <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // illegal command EXPORT with INT1 = 0
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   //check_state();
   
   // expect EXPORT, INT1 = 0
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0008)
   wait(clk==ZERO);
   `CLEAR_BUS
    
   ///////////
   // EXPORT STATE : INT1 = 1
    
   `CLEAR_ALL
   `CHIP_RESET
    
   // enter NORMAL
   wait(clk==ZERO);
   maroon <= ZERO;
   gold   <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // enable INT1
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'h0100,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // bad command sets INT1 and enter eRR
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // confirm eRR + INT1
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0102)
   wait(clk==ZERO);
   `CLEAR_BUS
     
   // recover eRR to NORMAL, keep INT1 set
   maroon <= ONE;
   gold   <= ZERO;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // confirm NORMAL + INT1
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0101)
   wait(clk==ZERO);
   `CLEAR_BUS
   
   maroon <= ZERO;
   gold   <= ONE;
   export_disable <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
     
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
     
   //check_state();
     
   // expect EXPORT + INT1
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0108)
   wait(clk==ZERO);
   `CLEAR_BUS
     
   //////////
   // EXPORT STATE : clear INT1 while in EXPORT
      
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'h0100,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
      
   //check_state();
   
   // expect EXPORT, INT1 cleared
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0008)
   wait(clk==ZERO);
   `CLEAR_BUS


   //int 2
    
   // enter NORMAL first
   $display("int2 test");
    
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= ZERO;
   gold   <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // enable INT2
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'h0200,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // assert export_disable
   export_disable <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // trigger export violation
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);
    
   //check_state();
    
   // check INT2 + EXPORT
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0208)
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // clear INT2
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_STA_ADDR,16'h0200,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // verify cleared
   wait(clk==ZERO);
   `SET_READ(VCHIP_STA_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0008)
   wait(clk==ZERO);
   `CLEAR_BUS

//////////////////////////////////////////
///////  Configuration Regester  /////////
//////////////////////////////////////////
    
    $display ("  ");
    $display ("Configuration Register");

   `CLEAR_ALL
   `CHIP_RESET

   // YOUR STIMULUS GOES HERE!
   
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);

   // RESET STATE TESTS 
   
   $display ("RESET STATE");
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0300)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0100)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0200)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // ENTER NORMAL STATE
   
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   // NORMAL STATE VALUE TESTS

   $display ("NORMAL STATE");
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0300)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0100)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0200)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
    
   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // BYTE ENABLE COVERAGE
   
   $display ("BYTE coverage");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'h1234,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   // low byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'hAAAA,2'b01,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0200)
   //$display("value is %h at addrs  %h for byte check 01 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // high byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'hBB00,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0300)
   //$display("value is %h at addrs  %h for byte check 10 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // 00 (no write)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'hFFFF,2'b00,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0300)
   //$display("value is %h at addrs  %h for byte check 00 time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // ENTER eRR STATE

   $display("Err State");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
    wait(clk==ZERO);
    wait(clk==ONE);
    
   // Attempt write in eRR STATE (should not change)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0300)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // EXPORT STATE
   
   $display("EXPT STATE");
   
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   export_disable <= 1'b1;
   wait(clk==ONE);
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   wait(clk==ONE); 
   
   // Attempt write in EXPORT state (should be ignored)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Read should be disabled (0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // ALIAS TEST
   
   $display("ALLIAS");
    
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // attempt write with cs=0 (should do nothing)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CON_ADDR,16'h1234,2'b11,1'b0)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Read LEFT after Chip select (should still be AAAA)
   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // read with cs = 0 (should return 0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b0)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // attempt write to invalid address
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h50,16'hDEAD,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // LEFT should remain unchanged
   wait(clk==ZERO);
   `SET_READ(VCHIP_CON_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
    
    // read from unused address
   wait(clk==ZERO);
   `SET_READ(7'h7F,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Alias test: 0x10 <-> 0x50

   // Write base (0x0C), read alias (0x4C)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h0C,16'hABCD,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(7'h4C,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Write alias (0x4C), read base (0x0C)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h4C,16'hDCBA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(7'h0C,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS


//////////////////////////////////////////
///////  Command Regester  /////////
//////////////////////////////////////////
    
    $display ("  ");
    $display ("Command Register");

   `CLEAR_ALL
   `CHIP_RESET

   // YOUR STIMULUS GOES HERE!
   
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);

   // RESET STATE TESTS 
   
   $display ("RESET STATE");
   
//check_state();

   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0005)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);   
   `SET_WRITE(VCHIP_CMD_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h000F)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
//check_state();

   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h000A)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   
   // ENTER NORMAL STATE
   
   $display ("NORMAL STATE");
   `CLEAR_ALL
   `CHIP_RESET   
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   // NORMAL STATE VALUE TESTS
 
 //check_state();
   
   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0005)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
       
   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

//check_state();
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h000F)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   
   wait(clk==ZERO);
   `CLEAR_BUS

//check_state();

   `CLEAR_ALL
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= ZERO;
   gold   <= ONE;
   wait(clk==ONE);
   wait(clk==ZERO);
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h000A)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

//check_state();

/////////////////////////////////////////////////////////////////////
/*   
   // 8000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
//check_state();

   // 8005
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8005,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0005)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   //`SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0003)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 8004
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8004,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0004)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // 8005
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8005,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0005)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // 8006
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8006,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0006)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // 8007
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8007,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0007)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // 8007
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8008,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0008)
   $display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
*/
//////////////////////////////////////////////////////////




   // BYTE ENABLE COVERAGE
   
   $display ("BYTE coverage");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h1234,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   // low byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'hAAAA,2'b01,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h000A)
   $display("value is %h at addrs  %h for byte check 01 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // high byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'hBB00,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h000A)
   $display("value is %h at addrs  %h for byte check 10 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // 00 (no write)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'hFFFF,2'b00,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h000A)
   $display("value is %h at addrs  %h for byte check 00 time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // ENTER eRR STATE

   $display("Err State");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
    wait(clk==ZERO);
    wait(clk==ONE);
    
   // Attempt write in eRR STATE (should not change)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h000A)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // EXPORT STATE
   
   $display("EXPT STATE");
   
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   export_disable <= 1'b1;
   wait(clk==ONE);
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   wait(clk==ONE); 

//check_state();

   // Attempt write in EXPORT state (should be ignored)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Read should be disabled (0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // ALIAS TEST
   
   $display("ALLIAS");
    
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // attempt write with cs=0 (should do nothing)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b0)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Read after Chip select (should still be AAAA)
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // read with cs = 0 (should return 0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b0)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // attempt write to invalid address
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h50,16'hDEAD,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // LEFT should remain unchanged
   wait(clk==ZERO);
   `SET_READ(VCHIP_CMD_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
    
    // read from unused address
   wait(clk==ZERO);
   `SET_READ(7'h7F,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
   
//check_state();

   // Alias test: 0x08 <-> 0x48

   // Write base (0x08), read alias (0x48)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h08,16'h0003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(7'h48,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Write alias (0x48), read base (0x08)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h48,16'h0004,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(7'h08,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS


//////////////////////////////////////////
///////  ALU OUT Regester  /////////
//////////////////////////////////////////

    $display ("  ");
    $display ("ALU OUT Register");

   `CLEAR_ALL
   `CHIP_RESET

   // YOUR STIMULUS GOES HERE!
   
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);

   // RESET STATE TESTS 
   
   $display ("RESET STATE");
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

alu_write(16'hAAAA, 16'h0000, 16'h8001);

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // ENTER NORMAL STATE
   
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   // NORMAL STATE VALUE TESTS

   $display ("NORMAL STATE");
   
alu_write(16'hFFFF, 16'h0000, 16'h8001);
//check_state();
 
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8001,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // FFFF
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hFFFF)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
alu_write(16'h5555, 16'h0000, 16'h8001);
//check_state();
   
   // 5555
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'h5555,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h5555)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
alu_write(16'hAAAA, 16'h0000, 16'h8001);
//check_state();
   
   // AAAA
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'hAAAA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'hAAAA)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

alu_write(16'h1111, 16'h1111, 16'h8002);
//check_state();
      
   // 0000
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'h0000,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // BYTE ENABLE COVERAGE
   
   $display ("BYTE coverage");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'h1234,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   // low byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'hAAAA,2'b01,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   $display("value is %h at addrs  %h for byte check 01 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // high byte only
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'hBB00,2'b10,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   $display("value is %h at addrs  %h for byte check 10 time %t ",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // 00 (no write)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'hFFFF,2'b00,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   $display("value is %h at addrs  %h for byte check 00 time %t",data_out, address, $time());
   wait(clk==ZERO);
   `CLEAR_BUS

   // ENTER eRR STATE

   $display("Err State");
   
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h800F,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
    wait(clk==ZERO);
    wait(clk==ONE);
    
   // Attempt write in eRR STATE (should not change)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS

   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // EXPORT STATE
   
   $display("EXPT STATE");
   
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);

   export_disable <= 1'b1;
   wait(clk==ONE);
   wait(clk==ZERO);
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_CMD_ADDR,16'h8003,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   wait(clk==ONE); 
   
   // Attempt write in EXPORT state (should be ignored)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'hFFFF,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Read should be disabled (0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS

   // ALIAS TEST
   
   $display("ALLIAS");
    
   `CHIP_RESET
   wait(clk==ZERO);
   maroon <= 0;
   gold   <= 1;
   wait(clk==ONE);
   wait(clk==ZERO);
    
   // attempt write with cs=0 (should do nothing)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(VCHIP_ALU_OUT_ADDR,16'h1234,2'b11,1'b0)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Read LEFT after Chip select (should still be AAAA)
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   //$display("value is %h at addrs  %h after at time %t",data_out, address, $time());   wait(clk==ZERO);
   `CLEAR_BUS
   
   // read with cs = 0 (should return 0)
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b0)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // attempt write to invalid address
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h50,16'hDEAD,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // LEFT should remain unchanged
   wait(clk==ZERO);
   `SET_READ(VCHIP_ALU_OUT_ADDR,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
    
    // read from unused address
   wait(clk==ZERO);
   `SET_READ(7'h7F,1'b1)
   wait(clk==ONE);
   #1 `CHECK_VAL(16'h0000)
   wait(clk==ZERO);
   `CLEAR_BUS
   
   // Alias test: 0x18 <-> 0x58

   // Write base (0x18), read alias (0x58)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h18,16'hABCD,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(7'h58,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   // Write alias (0x58), read base (0x18)
   wait(clk==ONE);
   wait(clk==ZERO);
   `SET_WRITE(7'h58,16'hDCBA,2'b11,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS
    
   wait(clk==ZERO);
   `SET_READ(7'h18,1'b1)
   wait(clk==ONE);
   wait(clk==ZERO);
   `CLEAR_BUS


//-----------------start of hw5-------------------------------------------


































   #5 $finish;
end // initial begin


verichip5 verichip5 (.clk           ( clk            ),    // system clock
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

initial 
begin
    $dumpfile("verichip.vcd");
    $dumpvars(0,top_verichip5);
end

endmodule
