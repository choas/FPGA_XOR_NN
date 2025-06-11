rm ./obj_dir/Vxor_nn
verilator --cc --exe --build -j 0 ../src/xor_nn.v xor_nn_tb.cpp && ./obj_dir/Vxor_nn
