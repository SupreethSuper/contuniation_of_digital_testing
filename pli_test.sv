module pli_test(input logic clk,                       // system clock
                input logic rst_b,                     // chip reset
                input logic [15:0] data_in,            // input data bus

                output logic [15:0] data_out);         // output data bus

always_ff @ ( posedge clk or negedge rst_b )
begin
  if ( !rst_b )
  begin
     data_out <= 16'h0;
  end // if ( !rst_b )
  else
  begin
     data_out <= data_in;
  end // else: !if( !rst_b )
end

endmodule
       
