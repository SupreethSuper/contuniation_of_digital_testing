#include "acc_user.h"


//changes 1 for test 1 :

// test 0 :
// 1) added a 32 * 4 buffer for char fetch

// 2) data_out_str uses the buffer now

// 3) Debug printf statements are added

int pli_function(char * value);   // declare prototype

int counter = 0; // global counter variable

my_setup()
{
  counter = 0; // initialize counter to 0
}

pli_test_next()
{
  int next_value;
  char buffer_for_acc_fetch_value[32]; // buffer to hold the value fetched from data_out

  // $pli_test_next(data_out,data_in);
  handle h_data_out = acc_handle_tfarg(1); // get h_data_out is the pli_test_next for the data out in sv
  handle h_data_in = acc_handle_tfarg(2); // get h_data_in is the pli_test_next for the data in in sv

  

  char *data_out_str = acc_fetch_value(h_data_out, "%h", buffer_for_acc_fetch_value); // fetch the current value of data_out and store it in data_out_str

  // get the current value of data_out
  // data_out_str = "5"; //old functionality scrapped
  printf("Current value of data_out: %h\n", data_out_str); // print the current value of data_out
  printf("The buffer contains: %h\n", buffer_for_acc_fetch_value); // print the contents of the buffer

  next_value = pli_function(data_out_str);

  static s_setval_delay delay_s = {{0,1,0,0.0}, accNoDelay}; // set the delay for the value assignment
  static s_setval_value value_s = {accInt}; // set the type and initial value for the value assignment
  value_s.value.integer = counter;
  acc_set_value(h_data_in, &value_s, &delay_s); //error_dealth with
  counter++;
 

  // set the value of data_in
}
