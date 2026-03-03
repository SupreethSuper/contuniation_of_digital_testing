#include <stdio.h>

// function to increase current value by 1
int pli_function(char * value)
{
  int int_val;                  // hold the current value
  int new_val;                  // hold the new value
  sscanf(value,"%d",&int_val);  // get current value
  new_val = int_val + 1;        // increment by 1
  return new_val;               // return it
}
