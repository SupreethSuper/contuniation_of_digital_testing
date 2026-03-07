#clean any prev runs
#run command -> vsim -do tb_runner.do
quit -sim;

#make a work library
vlib work;
vmap work work;

#compile all files
vlog -sv verichip.sv;
vlog -sv top_verichip.sv;

#invoking testbench

vsim work.top_verichip;


#view waves
add wave -r *;

run -all;
onfinish exit; # to acknowledge finish