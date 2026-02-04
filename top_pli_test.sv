module top_pli_test;

logic clk;                       // system clock
logic rst_b;                     // chip reset
logic [15:0] data_in;            // input data bus
logic [15:0] data_out;           // output data bus

logic [15:0] start_val;          // start value to use
logic [15:0] limit;              // how many tests to run
integer      count;              // loop counter

initial   // get command line args
begin
   if ( $value$plusargs("START_VALUE=%h",start_val) )
      $display("using provided start value %h",start_val);
   else
   begin
      start_val = 16'h0;
      $display("using default start value %h",start_val);
   end
   if ( $value$plusargs("RUN_LIMIT=%h",limit) )
      $display("using run limit of %h",limit);
   else
   begin
      limit = 10;
      $display("using default start value %h",start_val);
   end
end

initial   // create clock and reset
begin
   clk      <= 1'b0;
   rst_b    <= 1'b0;
   data_in  <= 16'h0;
   #1;
   data_in  <= start_val;
   #4 rst_b <= 1'b1;

   while ( 1 )
   begin
      #5 clk <= 1'b1;
      #5 clk <= 1'b0;
   end
end

initial      // the loop!
begin
  wait ( rst_b === 1'b1 );        // get out of reset
  wait ( clk == 1'b1 );           // wait for start value to be loaded
   
  for ( count = 0 ; count < limit ; count = count + 1 )
  begin
    wait ( clk == 1'b0 );
    $pli_test_next(data_out,data_in);
    wait ( clk == 1'b1 );
  end

  wait(clk == 1'b0);   // MUST LEAVE SO GRADING WORKS!
  wait(clk == 1'b1);
  wait(clk == 1'b0);
  $finish;
end

pli_test pli_test (.clk           ( clk            ),    // system clock
                   .rst_b         ( rst_b          ),    // chip reset
                   .data_in       ( data_in        ),    // data bus

                   .data_out      ( data_out       ) );  // output data bus

always @ ( * )
  $display("%t data_in %h data_out %h",$time(),data_in,data_out);

// initial
// begin
// $fsdbDumpfile("top_pli_test.fsdb");
// $fsdbDumpvars(0,pli_test);
// end

endmodule
