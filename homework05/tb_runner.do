quit -sim

vlib work
vmap work work

# compile
vlog -sv verichip5.sv
vlog -sv top_verichip5.sv

# simulate
vsim work.top_verichip5

add wave -r *
run -all

onfinish exit