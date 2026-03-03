#include "acc_user.h"


//changes 1 for test 1 :

// test 0 :
// 1) added a 32 * 4 buffer for char fetch

// 2) data_out_str uses the buffer now

// 3) Debug printf statements are added

// ===================================MAJOR CHANGES FOR TEST 4===================================
// 1) Change the format specifier in acc_fetch_value from "%h" to "%d" as a trial. Found out that %d is fetched in pli function
// 2) Change  static s_setval_value value_s = {accInt}; to  static s_setval_value value_s = {accIntVal};, bug fixed
// 3) my_setup() is commented out as it is not used in this test, as it was doing nothing, and no changes were observed
// ===============================END OF MAJOR CHANGES FOR TEST 4===================================

int pli_function(char * value);   // declare prototype

int counter = 0; // global counter variable

// my_setup()
// {
//   counter = 0; // initialize counter to 0
// }

pli_test_next()
{
  int next_value;
  char buffer_for_acc_fetch_value[32]; // buffer to hold the value fetched from data_out

  // $pli_test_next(data_out,data_in);
  handle h_data_out = acc_handle_tfarg(1); // get h_data_out is the pli_test_next for the data out in sv
  handle h_data_in = acc_handle_tfarg(2); // get h_data_in is the pli_test_next for the data in in sv

  

  // char *data_out_str = acc_fetch_value(h_data_out, "%h", buffer_for_acc_fetch_value); // fetch the current value of data_out and store it in data_out_str

  char *data_out_str = acc_fetch_value(h_data_out, "%d", buffer_for_acc_fetch_value); // changed the format specifier to "%d" as a trial. Found out that %d is fetched in pli function

  printf("Current value of data_out: %s\n", data_out_str);
  printf("The buffer contains: %s\n", buffer_for_acc_fetch_value);

  next_value = pli_function(data_out_str);

  static s_setval_delay delay_s = {{0,0,0,0.0}, accNoDelay};   // (also fixed the "1" -> "0")
  static s_setval_value value_s = {accIntVal};

  value_s.value.integer = (next_value & 0xFFFF);
  acc_set_value(h_data_in, &value_s, &delay_s);


  //counter++;
 

  // set the value of data_in
}
