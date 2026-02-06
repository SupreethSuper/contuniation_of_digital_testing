#include "acc_user.h"


//changes 1 for test 1 :

// test 0 :
// 1) added a 32 * 4 buffer for char fetch

// 2) data_out_str uses the buffer now

// 3) Debug printf statements are added

int pli_function(char * value);   // declare prototype

pli_test_next()
{
  int next_value;
  char buffer_for_acc_fetch_value[32]; // buffer to hold the value fetched from data_out

  

  char *data_out_str = acc_fetch_value(h_data_out, "%h", buffer_for_acc_fetch_value); // fetch the current value of data_out and store it in data_out_str

  // get the current value of data_out
  // data_out_str = "5"; //old functionality scrapped
  printf("Current value of data_out: %h\n", data_out_str); // print the current value of data_out
  printf("The buffer contains: %h\n", buffer_for_acc_fetch_value); // print the contents of the buffer

  next_value = pli_function(data_out_str);

  // set the value of data_in
}
