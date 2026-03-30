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

`define CHECK_VER(addr,wval,rval,export_disable, bytes,cs)   \
wait( clk == 1'b0 );    \
`WRITE_REG(addr,wval,bytes,cs) \
`READ_REG(addr,rval,cs)
 


module top_verichip5();

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

   // 1. RESET STATE
   // reset clears to 0000, write FFFF->5555->AAAA->0000
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 16'hFFFF, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR, 16'h5555, 16'h5555, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 16'hAAAA, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)

   // byte enables in reset
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR,  16'hFFFF, 16'hFFFF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR,  16'hFFAA, 16'h00AA, 2'b01, 1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR,  16'hAAFF, 16'hAA00, 2'b10, 1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hBEEF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h1234, 2'b00, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hBEEF,        1'b1)



   // aliasing reset: cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `WRITE_REG(7'h50,               16'h5555, 2'b11, 1'b1)
   `READ_REG(7'h50,                16'h0000,        1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hAAAA,        1'b1)

   // aliasing reset: cs=0 addr=7'h10 write ignored, cs=0 read returns 0
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b0)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hAAAA,        1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000,        1'b0)

   // 2. NORMAL STATE
   `CHANGE_STATE_TO_NORMAL

   // normal state: FFFF->5555->AAAA->0000
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 16'hFFFF, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR, 16'h5555, 16'h5555, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 16'hAAAA, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)

   // byte enables in normal
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR,  16'hFFAA, 16'h00AA, 2'b01, 1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_LEFT_ADDR,  16'hAAFF, 16'hAA00, 2'b10, 1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hDEAD, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h1234, 2'b00, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hDEAD,        1'b1)

   // aliasing normal: cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `WRITE_REG(7'h50,               16'h5555, 2'b11, 1'b1)
   `READ_REG(7'h50,                16'h0000,        1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hAAAA,        1'b1)

   // aliasing normal: cs=0 addr=7'h10 write ignored, cs=0 read returns 0
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b0)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hAAAA,        1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000,        1'b0)

   // 3. STATE_ERR
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hABCD, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR

   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hABCD,        1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hABCD,        1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hABCD,        1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hABCD,        1'b1)

   // aliasing err: cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `READ_REG(7'h50,                16'h0000,        1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'hABCD,        1'b1)
   // aliasing err: cs=0 addr=7'h10 read returns 0
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000,        1'b0)

   // 4. STATE_EXP
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h5A5A, 2'b11, 1'b1)
   `CHANGE_STATE_TO_EXP

   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000,        1'b1)

   // aliasing exp: cs=1 addr=7'h50 returns 0
   `READ_REG(7'h50,                16'h0000,        1'b1)
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000,        1'b1)
   // aliasing exp: cs=0 addr=7'h10 read returns 0
   `READ_REG(VCHIP_ALU_LEFT_ADDR,  16'h0000,        1'b0)


  // reset state version register
    `CLEAR_ALL
   `CHIP_RESET

 
 
   `CHECK_RW(VCHIP_VER_ADDR, 16'hFFFF, 16'h0210, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_VER_ADDR, 16'h5555, 16'h0210, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_VER_ADDR, 16'hAAAA, 16'h0210, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_VER_ADDR, 16'h0000, 16'h0210, 2'b11, 1'b1)


   // byte enable for reset state of version register
    `WRITE_REG(VCHIP_VER_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_VER_ADDR,  16'hFFFF, 16'h0210, 2'b11, 1'b1)
 
   `WRITE_REG(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_VER_ADDR,  16'hFFAA, 16'h0210, 2'b01, 1'b1)
   `WRITE_REG(VCHIP_VER_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_VER_ADDR,  16'hAAFF, 16'h0210, 2'b10, 1'b1)
   `WRITE_REG(VCHIP_VER_ADDR, 16'hBEEF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_VER_ADDR, 16'h1234, 2'b00, 1'b1)
   `READ_REG(VCHIP_VER_ADDR,  16'h0210,        1'b1)

   // aliasing : cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `WRITE_REG(VCHIP_VER_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `WRITE_REG(7'h40,               16'h5555, 2'b11, 1'b1)
   `READ_REG(7'h40,                16'h0000,        1'b1)
   `READ_REG(VCHIP_VER_ADDR,  16'h0210,        1'b1)
   `WRITE_REG(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_VER_ADDR,  16'h0210,        1'b1)

   
 // aliasing : cs=0 addr=7'h10 write ignored, cs=0 read returns 0
  //  `WRITE_REG(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_VER_ADDR, 16'h5555, 2'b11, 1'b0)
//   `READ_REG(VCHIP_VER_ADDR,  16'h0210,        1'b1)
   `READ_REG(VCHIP_VER_ADDR,  16'h0000,        1'b0)
   `WRITE_REG(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b0)
    `READ_REG(VCHIP_VER_ADDR,  16'h0000,        1'b0)
    `WRITE_REG(7'h10,               16'h5555, 2'b11, 1'b0)
    `READ_REG(7'h10,                16'h0000,        1'b0)




// normal state of  version register
   `CLEAR_ALL
   `CHIP_RESET
  `CHANGE_STATE_TO_NORMAL

  export_disable = 1;
   wait(clk == 1'b1)
    `CHECK_VER(VCHIP_VER_ADDR,16'hFFFF,16'h8210,1'b1, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h5555,16'h8210,1'b1, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'hAAAA,16'h8210,1'b1, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h0000,16'h8210,1'b1, 2'b11,1'b1)
//
export_disable = 0;
wait(clk == 1'b0)
`CHECK_VER(VCHIP_VER_ADDR,16'hFFFF,16'h0210,1'b0, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h5555,16'h0210,1'b0, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'hAAAA,16'h0210,1'b0, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h0000,16'h0210,1'b0, 2'b11,1'b1)

// error_state of version register
  wait(clk == 1'b0)
    `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
    wait(clk == 0)
  `CHANGE_STATE_TO_ERR


  export_disable = 1;
   wait(clk == 1'b1)
    `CHECK_VER(VCHIP_VER_ADDR,16'hFFFF,16'h8210,1'b1, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h5555,16'h8210,1'b1, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'hAAAA,16'h8210,1'b1, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h0000,16'h8210,1'b1, 2'b11,1'b1)


//
export_disable = 0;
wait(clk == 1'b0)
`CHECK_VER(VCHIP_VER_ADDR,16'hFFFF,16'h0210,1'b0, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h5555,16'h0210,1'b0, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'hAAAA,16'h0210,1'b0, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h0000,16'h0210,1'b0, 2'b11,1'b1)


// export_voilation state of version register


    wait(clk == 1'b0)
    `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
    wait(clk == 0)
   `CHANGE_STATE_TO_EXP

  export_disable = 1;
   wait(clk == 1'b1)
    `CHECK_VER(VCHIP_VER_ADDR,16'hFFFF,16'h8210,1'b1, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h5555,16'h8210,1'b1, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'hAAAA,16'h8210,1'b1, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h0000,16'h8210,1'b1, 2'b11,1'b1)
//
export_disable = 0;
wait(clk == 1'b0)
`CHECK_VER(VCHIP_VER_ADDR,16'hFFFF,16'h0210,1'b0, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h5555,16'h0210,1'b0, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'hAAAA,16'h0210,1'b0, 2'b11,1'b1)
    wait(clk == 1'b1);
    `CHECK_VER(VCHIP_VER_ADDR,16'h0000,16'h0210,1'b0, 2'b11,1'b1)




// reset state of status register

  `CLEAR_ALL
   `CHIP_RESET


   `CHECK_RW(VCHIP_STA_ADDR, 16'hFFFF, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'h5555, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'hAAAA, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)

 // byte enable for reset state of version register
    `WRITE_REG(VCHIP_STA_ADDR, 16'hAAAA, 2'b11, 1'b1)
    `CHECK_RW(VCHIP_STA_ADDR,  16'hFFFF, 16'h0210, 2'b11, 1'b1)

   `WRITE_REG(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR,  16'hFFAA, 16'h0000, 2'b01, 1'b1)
   `WRITE_REG(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR,  16'hAAFF, 16'h0000, 2'b10, 1'b1)
   `WRITE_REG(VCHIP_STA_ADDR, 16'hBEEF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_STA_ADDR, 16'h1234, 2'b00, 1'b1)
   `READ_REG(VCHIP_STA_ADDR,  16'h0000,        1'b1)


// aliasing : cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `WRITE_REG(VCHIP_STA_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `WRITE_REG(7'h44,               16'h5555, 2'b11, 1'b1)
   `READ_REG(7'h44,                16'h0000,        1'b1)
   `READ_REG(VCHIP_STA_ADDR,  16'h0210,        1'b1)
   `WRITE_REG(VCHIP_STA_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_STA_ADDR,  16'h0210,        1'b1)



 // aliasing : cs=0 addr=7'h10 write ignored, cs=0 read returns 0
  //  `WRITE_REG(VCHIP_VER_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_STA_ADDR, 16'h5555, 2'b11, 1'b0)
//   `READ_REG(VCHIP_VER_ADDR,  16'h0210,        1'b1)
   `READ_REG(VCHIP_STA_ADDR,  16'h0000,        1'b0)
   `WRITE_REG(VCHIP_STA_ADDR, 16'hFFFF, 2'b11, 1'b0)
    `READ_REG(VCHIP_STA_ADDR,  16'h0000,        1'b0)
   `WRITE_REG(7'h44,               16'h5555, 2'b11, 1'b0)
   `READ_REG(7'h44,                16'h0000,        1'b0)

// RESET: both interrupt outputs low and status=0
`CLEAR_ALL
`CHIP_RESET
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b0) $display("FAIL int1 reset expected 0 got %b at %t", interrupt_1, $time());
if (interrupt_2 !== 1'b0) $display("FAIL int2 reset expected 0 got %b at %t", interrupt_2, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0000, 1'b1)




// NORMAL: both interrupt outputs low
`CHANGE_STATE_TO_NORMAL
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b0) $display("FAIL int1 normal expected 0 got %b at %t", interrupt_1, $time());
if (interrupt_2 !== 1'b0) $display("FAIL int2 normal expected 0 got %b at %t", interrupt_2, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0001, 1'b1)




// NORMAL -> ERROR by reserved command, INT1 disabled: state goes to ERR, INT1 stays 0
`CLEAR_ALL
`CHIP_RESET
`CHANGE_STATE_TO_NORMAL
`CHANGE_STATE_TO_ERR
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b0) $display("FAIL int1 err disabled expected 0 got %b at %t", interrupt_1, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0002, 1'b1)


// NORMAL -> ERROR by reserved command, INT1 enabled: INT1 sets
`CLEAR_ALL
`CHIP_RESET
`CHANGE_STATE_TO_NORMAL
`WRITE_REG(VCHIP_CON_ADDR, 16'h0100, 2'b10, 1'b1)
`CHANGE_STATE_TO_ERR
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b1) $display("FAIL int1 err enabled expected 1 got %b at %t", interrupt_1, $time());
if (interrupt_2 !== 1'b0) $display("FAIL int2 should remain 0 got %b at %t", interrupt_2, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)
// ERROR: write 0 does not clear INT1
`WRITE_REG(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b1) $display("FAIL int1 err write0 should not clear at %t", $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)

// ERROR: write 1 clears INT1
`WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b10, 1'b1)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b0) $display("FAIL int1 err clear expected 0 got %b at %t", interrupt_1, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0002, 1'b1)

// NORMAL overflow path to INT1
`CLEAR_ALL
`CHIP_RESET
`CHANGE_STATE_TO_NORMAL
`WRITE_REG(VCHIP_CON_ADDR, 16'h0100, 2'b10, 1'b1)
`WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h7FFF, 2'b11, 1'b1)
`WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0001, 2'b11, 1'b1)
`MATH_CMD(VCHIP_ALU_ADD)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b1) $display("FAIL int1 overflow expected 1 got %b at %t", interrupt_1, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)

// Return to NORMAL from ERROR_state, INT1 must persist until cleared
wait( clk == 1'b0 );
maroon <= 1'b1;
gold <= 1'b0;
wait( clk == 1'b1 );
wait( clk == 1'b0 );
maroon <= 1'b0;
gold <= 1'b0;
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b1) $display("FAIL int1 should persist back in normal at %t", $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0101, 1'b1)





// NORMAL: write 0 does not clear INT1
`WRITE_REG(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b1) $display("FAIL int1 normal write0 should not clear at %t", $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0101, 1'b1)





// NORMAL: write 1 clears INT1
`WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b10, 1'b1)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b0) $display("FAIL int1 normal clear expected 0 got %b at %t", interrupt_1, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0001, 1'b1)

// EXPORT VIOLATION with only INT2 enabled: INT1=0, INT2=1
`CLEAR_ALL
`CHIP_RESET
`CHANGE_STATE_TO_NORMAL
`WRITE_REG(VCHIP_CON_ADDR, 16'h0200, 2'b10, 1'b1)
`CHANGE_STATE_TO_EXP
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b0) $display("FAIL int1 exp expected 0 got %b at %t", interrupt_1, $time());
if (interrupt_2 !== 1'b1) $display("FAIL int2 exp expected 1 got %b at %t", interrupt_2, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)

// EXP: write 0 does not clear INT2
`WRITE_REG(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_2 !== 1'b1) $display("FAIL int2 exp write0 should not clear at %t", $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)

// EXP: write INT1 clear only must not affect INT2
`WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b10, 1'b1)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_2 !== 1'b1) $display("FAIL int2 changed when clearing int1 at %t", $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)

// EXP: write INT2 clear works
`WRITE_REG(VCHIP_STA_ADDR, 16'h0200, 2'b10, 1'b1)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_2 !== 1'b0) $display("FAIL int2 exp clear expected 0 got %b at %t", interrupt_2, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0008, 1'b1)






// Build both INT1 and INT2, then clear only INT1 in EXP and ensure INT2 unaffected
`CLEAR_ALL
`CHIP_RESET
`CHANGE_STATE_TO_NORMAL
`WRITE_REG(VCHIP_CON_ADDR, 16'h0300, 2'b10, 1'b1)

// First set INT1 by overflow -> ERROR
`WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h7FFF, 2'b11, 1'b1)
`WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0001, 2'b11, 1'b1)
`MATH_CMD(VCHIP_ALU_ADD)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
`READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)






// Return to NORMAL preserving INT1
wait( clk == 1'b0 );
maroon <= 1'b1;
gold <= 1'b0;
wait( clk == 1'b1 );
wait( clk == 1'b0 );
maroon <= 1'b0;
gold <= 1'b0;
wait( clk == 1'b1 ); wait( clk == 1'b0 );
`READ_REG(VCHIP_STA_ADDR, 16'h0101, 1'b1)

// Enter EXPORT VIOLATION, INT2 sets, INT1 persists
`CHANGE_STATE_TO_EXP
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b1) $display("FAIL int1 exp both-set expected 1 got %b at %t", interrupt_1, $time());
if (interrupt_2 !== 1'b1) $display("FAIL int2 exp both-set expected 1 got %b at %t", interrupt_2, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0308, 1'b1)

// EXP: write 0 does not clear either
`WRITE_REG(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
`READ_REG(VCHIP_STA_ADDR, 16'h0308, 1'b1)

// EXP: clear only INT1, INT2 must remain
`WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b10, 1'b1)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b0) $display("FAIL int1 exp clear expected 0 got %b at %t", interrupt_1, $time());
if (interrupt_2 !== 1'b1) $display("FAIL int2 changed when clearing int1 in exp at %t", $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)

// EXP: clear only INT2
`WRITE_REG(VCHIP_STA_ADDR, 16'h0200, 2'b10, 1'b1)
wait( clk == 1'b1 ); wait( clk == 1'b0 );
if (interrupt_1 !== 1'b0) $display("FAIL int1 changed when clearing int2 in exp at %t", $time());
if (interrupt_2 !== 1'b0) $display("FAIL int2 exp clear expected 0 got %b at %t", interrupt_2, $time());
`READ_REG(VCHIP_STA_ADDR, 16'h0008, 1'b1)







// normal state of status register
 `CLEAR_ALL
   `CHIP_RESET
  `CHANGE_STATE_TO_NORMAL

   `CHECK_RW(VCHIP_STA_ADDR, 16'hFFFF, 16'h0001, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'h5555, 16'h0001, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'hAAAA, 16'h0001, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'h0000, 16'h0001, 2'b11, 1'b1)


/*

   `CLEAR_ALL
   `CHIP_RESET
  `CHANGE_STATE_TO_NORMAL


  `WRITE_REG(VCHIP_CON_ADDR, 16'h0100, 2'b10, 1'b1)
`CHANGE_STATE_TO_ERR
`READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)

// _state: write 0 does not clear INT1

`WRITE_REG(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
wait(clk == 1'b1)
`READ_REG(VCHIP_STA_ADDR, 16'h0102, 1'b1)

// clearing int1
`WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b10, 1'b1)
wait(clk == 1'b1)
`READ_REG(VCHIP_STA_ADDR, 16'h0002, 1'b1)

`CLEAR_ALL
`CHIP_RESET
`CHANGE_STATE_TO_NORMAL
`WRITE_REG(VCHIP_CON_ADDR, 16'h0200, 2'b10, 1'b1)
`CHANGE_STATE_TO_EXP
wait( clk == 1'b1 )

`WRITE_REG(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
wait(clk == 1'b1)
`READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)


wait(clk == 1'b0)
`WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b10, 1'b1)
wait( clk == 1'b1 )
`READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)

wait(clk == 1'b0)

`WRITE_REG(VCHIP_STA_ADDR, 16'h0200, 2'b10, 1'b1)
wait( clk == 1'b1 )
`READ_REG(VCHIP_STA_ADDR, 16'h0008, 1'b1)

wait(clk == 1'b0)


`CHANGE_STATE_TO_EXP
wait( clk == 1'b1 );

`WRITE_REG(VCHIP_STA_ADDR, 16'h0000, 2'b11, 1'b1)
wait( clk == 1'b1 )
`READ_REG(VCHIP_STA_ADDR, 16'h0308, 1'b1)

wait(clk == 1'b0)

`WRITE_REG(VCHIP_STA_ADDR, 16'h0100, 2'b10, 1'b1)
wait( clk == 1'b1 )
`READ_REG(VCHIP_STA_ADDR, 16'h0208, 1'b1)


// EXP: clear only INT2
`WRITE_REG(VCHIP_STA_ADDR, 16'h0200, 2'b10, 1'b1)
wait( clk == 1'b1 )
`READ_REG(VCHIP_STA_ADDR, 16'h0008, 1'b1)



//error_state of status register

  wait(clk == 1'b0)
    `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
    wait(clk == 1'b0)
  `CHANGE_STATE_TO_ERR

   `CHECK_RW(VCHIP_STA_ADDR, 16'hFFFF, 16'h0002, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'h5555, 16'h0002, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'hAAAA, 16'h0002, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'h0000, 16'h0002, 2'b11, 1'b1)



//export_voilation state of status register

 wait(clk == 1'b0)
    `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
    wait(clk == 0)
   `CHANGE_STATE_TO_EXP

   `CHECK_RW(VCHIP_STA_ADDR, 16'hFFFF, 16'h0008, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'h5555, 16'h0008, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'hAAAA, 16'h0008, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_STA_ADDR, 16'h0000, 16'h0008, 2'b11, 1'b1)
*/


//reset state for command register
`CLEAR_ALL
   `CHIP_RESET


   `CHECK_RW(VCHIP_CMD_ADDR, 16'hFFFF, 16'h800F, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR, 16'h5555, 16'h0005, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR, 16'hAAAA, 16'h800A, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)

   // byte enable for reset state of version register
    `WRITE_REG(VCHIP_CMD_ADDR, 16'hAAAA, 2'b11, 1'b1)
    `CHECK_RW(VCHIP_CMD_ADDR,  16'hFFFF, 16'h800F, 2'b11, 1'b1)

   `WRITE_REG(VCHIP_CMD_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR,  16'hFFAA, 16'h000A, 2'b01, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR,  16'hAAFF, 16'h8000, 2'b10, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, 16'hBEEF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, 16'h1234, 2'b00, 1'b1)
   `READ_REG(VCHIP_CMD_ADDR,  16'h000F,        1'b1)


// aliasing : cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `WRITE_REG(VCHIP_CMD_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `WRITE_REG(7'h48,               16'h5555, 2'b11, 1'b1)
   `READ_REG(7'h48,                16'h0000,        1'b1)
   `READ_REG(VCHIP_CMD_ADDR,  16'h000A,        1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_CMD_ADDR,  16'h800F,        1'b1)

 // aliasing : cs=0 addr=7'h10 write ignored, cs=0 read returns 0
  //  `WRITE_REG(VCHIP_CMD_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CMD_ADDR, 16'h5555, 2'b11, 1'b0)
//   `READ_REG(VCHIP_CMD_ADDR,  16'h0210,        1'b1)
   `READ_REG(VCHIP_CMD_ADDR,  16'h0000,        1'b0)
   `WRITE_REG(VCHIP_CMD_ADDR, 16'hFFFF, 2'b11, 1'b0)
    `READ_REG(VCHIP_CMD_ADDR,  16'h0000,        1'b0)
   `WRITE_REG(7'h48,               16'h5555, 2'b11, 1'b0)
   `READ_REG(7'h48,                16'h0000,        1'b0)



// normal state for command register

 `CLEAR_ALL
   `CHIP_RESET
  `CHANGE_STATE_TO_NORMAL
 

   
   `WRITE_REG(VCHIP_CMD_ADDR, 16'h5555, 2'b11, 1'b1)
  `READ_REG(VCHIP_CMD_ADDR,  16'h0005,        1'b1)
   
//  `WRITE_REG(VCHIP_CMD_ADDR, 16'hAAAA, 2'b11, 1'b1)
//  `READ_REG(VCHIP_CMD_ADDR,  16'h000A,        1'b1)
 
 `WRITE_REG(VCHIP_CMD_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_CMD_ADDR,  16'h0000,        1'b1)

`CLEAR_ALL
   `CHIP_RESET
  `CHANGE_STATE_TO_NORMAL

   `WRITE_REG(VCHIP_CMD_ADDR, 16'hFFFF, 2'b11, 1'b1)
    `READ_REG(VCHIP_CMD_ADDR,  16'h000F,        1'b1)  

`CLEAR_ALL
   `CHIP_RESET
  `CHANGE_STATE_TO_NORMAL

  `WRITE_REG(VCHIP_CMD_ADDR, 16'hAAAA, 2'b11, 1'b1)
  `READ_REG(VCHIP_CMD_ADDR,  16'h000A,        1'b1)


//error_state for command register
   wait(clk == 1'b0)
    `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
    wait(clk == 1'b0)
  `CHANGE_STATE_TO_ERR


   `CHECK_RW(VCHIP_CMD_ADDR, 16'hFFFF, 16'h800F, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR, 16'h5555, 16'h000F, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR, 16'hAAAA, 16'h000F, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR, 16'h0000, 16'h000F, 2'b11, 1'b1)



//export voilation for command register

wait(clk == 1'b0)
    `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
    wait(clk == 0)
   `CHANGE_STATE_TO_EXP

   `CHECK_RW(VCHIP_CMD_ADDR, 16'hFFFF, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR, 16'h5555, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR, 16'hAAAA, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CMD_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)





//configuration register

  //reset state for config reg

   `CLEAR_ALL
   `CHIP_RESET


   `CHECK_RW(VCHIP_CON_ADDR, 16'hFFFF, 16'h0300, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'h5555, 16'h0100, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'hAAAA, 16'h0200, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)

   // byte enable for reset state of version register
    `WRITE_REG(VCHIP_CON_ADDR, 16'hAAAA, 2'b11, 1'b1)
    `CHECK_RW(VCHIP_CON_ADDR,  16'hFFFF, 16'h0300, 2'b11, 1'b1)

   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR,  16'hFFAA, 16'h0000, 2'b01, 1'b1)
   `WRITE_REG(VCHIP_CON_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR,  16'hAAFF, 16'h0200, 2'b10, 1'b1)
   `WRITE_REG(VCHIP_CON_ADDR, 16'hBEEF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CON_ADDR, 16'h1234, 2'b00, 1'b1)
   `READ_REG(VCHIP_CON_ADDR,  16'h0200,        1'b1)


// aliasing : cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `WRITE_REG(VCHIP_CON_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `WRITE_REG(7'h4C,               16'h5555, 2'b11, 1'b1)
   `READ_REG(7'h4C,                16'h0000,        1'b1)
   `READ_REG(VCHIP_CON_ADDR,  16'h0200,        1'b1)
   `WRITE_REG(VCHIP_CON_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_CON_ADDR,  16'h0300,        1'b1)

 // aliasing : cs=0 addr=7'h10 write ignored, cs=0 read returns 0
  //  `WRITE_REG(VCHIP_CMD_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_CON_ADDR, 16'h5555, 2'b11, 1'b0)
//   `READ_REG(VCHIP_CON_ADDR,  16'h0210,        1'b1)
   `READ_REG(VCHIP_CON_ADDR,  16'h0000,        1'b0)
   `WRITE_REG(VCHIP_CON_ADDR, 16'hFFFF, 2'b11, 1'b0)
    `READ_REG(VCHIP_CON_ADDR,  16'h0000,        1'b0)
   `WRITE_REG(7'h48,               16'h5555, 2'b11, 1'b0)
   `READ_REG(7'h48,                16'h0000,        1'b0)


//normal state of configuration register

   `CLEAR_ALL
   `CHIP_RESET
  `CHANGE_STATE_TO_NORMAL


   `CHECK_RW(VCHIP_CON_ADDR, 16'hFFFF, 16'h0300, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'h5555, 16'h0100, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'hAAAA, 16'h0200, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)


// error_state of configuration register

  wait(clk == 1'b0)
    `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
    wait(clk == 1'b0)
  `CHANGE_STATE_TO_ERR
 
 
   `CHECK_RW(VCHIP_CON_ADDR, 16'hFFFF, 16'h0300, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'h5555, 16'h0300, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'hAAAA, 16'h0300, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'h0000, 16'h0300, 2'b11, 1'b1)

//export_voilation state of configuration register

 wait(clk == 1'b0)
    `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
    wait(clk == 0)
   `CHANGE_STATE_TO_EXP

 
   `CHECK_RW(VCHIP_CON_ADDR, 16'hFFFF, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'h5555, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'hAAAA, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_CON_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)











//alu_right register


 `CLEAR_ALL
   `CHIP_RESET

   // 1. RESET STATE
   // reset clears to 0000, write FFFF->5555->AAAA->0000
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 16'hFFFF, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR, 16'h5555, 16'h5555, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 16'hAAAA, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)

   // byte enables in reset
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR,  16'hFFFF, 16'hFFFF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR,  16'hFFAA, 16'h00AA, 2'b01, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR,  16'hAAFF, 16'hAA00, 2'b10, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hBEEF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h1234, 2'b00, 1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hBEEF,        1'b1)

   // aliasing reset: cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `WRITE_REG(7'h54,               16'h5555, 2'b11, 1'b1)
   `READ_REG(7'h54,                16'h0000,        1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hAAAA,        1'b1)
   // aliasing reset: cs=0 addr=7'h10 write ignored, cs=0 read returns 0
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h5555, 2'b11, 1'b0)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hAAAA,        1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000,        1'b0)

   // 2. NORMAL STATE
   `CHANGE_STATE_TO_NORMAL

   // normal state: FFFF->5555->AAAA->0000
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 16'hFFFF, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR, 16'h5555, 16'h5555, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 16'hAAAA, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)

   // byte enables in normal
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR,  16'hFFAA, 16'h00AA, 2'b01, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_RIGHT_ADDR,  16'hAAFF, 16'hAA00, 2'b10, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hDEAD, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h1234, 2'b00, 1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hDEAD,        1'b1)

   // aliasing normal: cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `WRITE_REG(7'h54,               16'h5555, 2'b11, 1'b1)
   `READ_REG(7'h54,                16'h0000,        1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hAAAA,        1'b1)
   // aliasing normal: cs=0 addr=7'h10 write ignored, cs=0 read returns 0
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h5555, 2'b11, 1'b0)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hAAAA,        1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000,        1'b0)

   // 3. STATE_ERR
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hABCD, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR

   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hABCD,        1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h5555, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hABCD,        1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hABCD,        1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hABCD,        1'b1)

   // aliasing err: cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `READ_REG(7'h50,                16'h0000,        1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'hABCD,        1'b1)
   // aliasing err: cs=0 addr=7'h10 read returns 0
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000,        1'b0)

   // 4. STATE_EXP
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h5A5A, 2'b11, 1'b1)
   `CHANGE_STATE_TO_EXP

   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h5555, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000,        1'b1)

   // aliasing exp: cs=1 addr=7'h50 returns 0
   `READ_REG(7'h50,                16'h0000,        1'b1)
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000,        1'b1)
   // aliasing exp: cs=0 addr=7'h10 read returns 0
   `READ_REG(VCHIP_ALU_RIGHT_ADDR,  16'h0000,        1'b0)


//alu_out register

 `CLEAR_ALL
   `CHIP_RESET

   // 1. RESET STATE
   // reset clears to 0000, write FFFF->5555->AAAA->0000
   `CHECK_RW(VCHIP_ALU_OUT_ADDR, 16'hFFFF, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_OUT_ADDR, 16'h5555, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_OUT_ADDR, 16'hAAAA, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_OUT_ADDR, 16'h0000, 16'h0000, 2'b11, 1'b1)

   // byte enables in reset
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_OUT_ADDR,  16'hFFFF, 16'h0000, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_OUT_ADDR,  16'hFFAA, 16'h0000, 2'b01, 1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h0000, 2'b11, 1'b1)
   `CHECK_RW(VCHIP_ALU_OUT_ADDR,  16'hAAFF, 16'h0000, 2'b10, 1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'hBEEF, 2'b11, 1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h1234, 2'b00, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)

   // aliasing reset: cs=1 addr=7'h50 returns 0, does not affect 7'h10
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `WRITE_REG(7'h58,               16'h5555, 2'b11, 1'b1)
   `READ_REG(7'h58,                16'h0000,        1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
 
 // aliasing reset: cs=0 addr=7'h10 write ignored, cs=0 read returns 0
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h5555, 2'b11, 1'b0)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b0)



   // 2. NORMAL STATE
     `CLEAR_ALL
   `CHIP_RESET

   `CHANGE_STATE_TO_NORMAL

   // normal state: FFFF->5555->AAAA->0000

   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h5555, 2'b11, 1'b1)
  `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)

 
 
`WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'h5555, 2'b11, 1'b1)
 `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
 `WRITE_REG(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
wait(clk == 1'b1)
 `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h5555,        1'b1)


`WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hAAAA, 2'b11, 1'b1)
 `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
 `WRITE_REG(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
wait(clk == 1'b1)
 `READ_REG(VCHIP_ALU_OUT_ADDR,  16'hAAAA,        1'b1)


`WRITE_REG(VCHIP_ALU_LEFT_ADDR, 16'hFFFF, 2'b11, 1'b1)
 `WRITE_REG(VCHIP_ALU_RIGHT_ADDR, 16'h0000, 2'b11, 1'b1)
 `WRITE_REG(VCHIP_CMD_ADDR, 16'h8001, 2'b11, 1'b1)
wait(clk == 1'b1)
 `READ_REG(VCHIP_ALU_OUT_ADDR,  16'hFFFF,        1'b1)




   // 3. STATE_ERR
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'hABCD, 2'b11, 1'b1)
   `CHANGE_STATE_TO_ERR

   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h5555, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)

 
   // 4. STATE_EXP
   `CLEAR_ALL
   `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h5A5A, 2'b11, 1'b1)
   `CHANGE_STATE_TO_EXP

   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'hFFFF, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h5555, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'hAAAA, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)
   `WRITE_REG(VCHIP_ALU_OUT_ADDR, 16'h0000, 2'b11, 1'b1)
   `READ_REG(VCHIP_ALU_OUT_ADDR,  16'h0000,        1'b1)


// reset_state  state_machine
   
 `CLEAR_ALL
 `CHIP_RESET

wait(clk == 1'b1)
wait(clk == 1'b0)
    maroon = 1'b1;
    gold   = 1'b1;
  wait(clk == 1'b1)
wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0000,        1'b1)


`CLEAR_ALL
 `CHIP_RESET

        wait(clk == 1'b1)
        wait(clk == 1'b0)
    maroon = 1'b1;
    gold   = 1'b0;
        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0000,        1'b1)



`CLEAR_ALL
 `CHIP_RESET

        wait(clk == 1'b1)
        wait(clk == 1'b0)

 `CHANGE_STATE_TO_ERR
   
        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0000,        1'b1)



`CLEAR_ALL
 `CHIP_RESET

        wait(clk == 1'b1)
        wait(clk == 1'b0)

   `CHANGE_STATE_TO_EXP

        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0000,        1'b1)


// normal_state in the state machine

  `CLEAR_ALL
   `CHIP_RESET

   `CHANGE_STATE_TO_NORMAL

   wait(clk == 1'b1)
        wait(clk == 1'b0)
    maroon = 1'b1;
    gold   = 1'b1;
        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0001,        1'b1)



 `CLEAR_ALL
   `CHIP_RESET

   `CHANGE_STATE_TO_NORMAL

        wait(clk == 1'b1)
        wait(clk == 1'b0)
    maroon = 1'b1;
    gold   = 1'b0;
        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0001,        1'b1)


 `CLEAR_ALL
   `CHIP_RESET

   `CHANGE_STATE_TO_NORMAL

   wait(clk == 1'b1)
        wait(clk == 1'b0)
    maroon = 1'b0;
    gold   = 1'b1;
        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0001,        1'b1)
////////



// error_state state machine

`CLEAR_ALL
 `CHIP_RESET
   `CHANGE_STATE_TO_NORMAL


        wait(clk == 1'b1)
        wait(clk == 1'b0)

 `CHANGE_STATE_TO_ERR

        wait(clk == 1'b1)
        wait(clk == 1'b0)

 `CHANGE_STATE_TO_ERR

        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0002,        1'b1)


//

`CLEAR_ALL
 `CHIP_RESET

`CHANGE_STATE_TO_NORMAL


        wait(clk == 1'b1)
        wait(clk == 1'b0)

 `CHANGE_STATE_TO_ERR

        wait(clk == 1'b1)
        wait(clk == 1'b0)

   `CHANGE_STATE_TO_EXP

        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0002,        1'b1)


//

 `CLEAR_ALL
   `CHIP_RESET

   `CHANGE_STATE_TO_NORMAL

     wait(clk == 1'b1)
        wait(clk == 1'b0)

 `CHANGE_STATE_TO_ERR

        wait(clk == 1'b1)
        wait(clk == 1'b0)
    maroon = 1'b1;
    gold   = 1'b1;
        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0002,        1'b1)

  //

 `CLEAR_ALL
   `CHIP_RESET

   `CHANGE_STATE_TO_NORMAL

     wait(clk == 1'b1)
        wait(clk == 1'b0)

 `CHANGE_STATE_TO_ERR

        wait(clk == 1'b1)
        wait(clk == 1'b0)
 
      maroon = 1'b1;
      gold   = 1'b0;


        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0001,        1'b1)

`CLEAR_ALL
   `CHIP_RESET

   `CHANGE_STATE_TO_NORMAL

     wait(clk == 1'b1)
        wait(clk == 1'b0)

 `CHANGE_STATE_TO_ERR

        wait(clk == 1'b1)
        wait(clk == 1'b0)

      maroon = 1'b0;
      gold   = 1'b1;


        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0002,        1'b1)


//export_voilation_state for state_machine


 `CLEAR_ALL
   `CHIP_RESET

   `CHANGE_STATE_TO_NORMAL

     wait(clk == 1'b1)
        wait(clk == 1'b0)

 `CHANGE_STATE_TO_EXP

        wait(clk == 1'b1)
        wait(clk == 1'b0)

      maroon = 1'b1;
      gold   = 1'b0;


        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0008,        1'b1)

//

 `CLEAR_ALL
   `CHIP_RESET

   `CHANGE_STATE_TO_NORMAL

     wait(clk == 1'b1)
        wait(clk == 1'b0)

 `CHANGE_STATE_TO_EXP

        wait(clk == 1'b1)
        wait(clk == 1'b0)

      maroon = 1'b0;
      gold   = 1'b1;

   

        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0008,        1'b1)

//


`CLEAR_ALL
   `CHIP_RESET

   `CHANGE_STATE_TO_NORMAL

     wait(clk == 1'b1)
        wait(clk == 1'b0)

 `CHANGE_STATE_TO_EXP

        wait(clk == 1'b1)
        wait(clk == 1'b0)

      maroon = 1'b1;
      gold   = 1'b1;

        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0008,        1'b1)


// export_voilation state to error_state

`CLEAR_ALL
 `CHIP_RESET

`CHANGE_STATE_TO_NORMAL


        wait(clk == 1'b1)
        wait(clk == 1'b0)

   `CHANGE_STATE_TO_EXP
       

        wait(clk == 1'b1)
        wait(clk == 1'b0)

 //     `CHANGE_STATE_TO_ERR

      export_disable <= 1'b0;
     
        wait(clk == 1'b1)
        wait(clk == 1'b0)
 
     `WRITE_REG(VCHIP_CMD_ADDR, (VCHIP_ALU_VALID | 16'h000F), 2'b11, 1'b1)
 
        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0008,        1'b1)


// export_voilation state to export_voilation state


`CLEAR_ALL
 `CHIP_RESET

`CHANGE_STATE_TO_NORMAL


        wait(clk == 1'b1)
        wait(clk == 1'b0)

   `CHANGE_STATE_TO_EXP


        wait(clk == 1'b1)
        wait(clk == 1'b0)

  `CHANGE_STATE_TO_EXP

        wait(clk == 1'b1)
        wait(clk == 1'b0)
   `READ_REG(VCHIP_STA_ADDR,  16'h0008,        1'b1)



   #5 $finish;

end // initial begin

verichip5 verichip      (.clk     ( clk ),    // system clock
         
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

endmodule