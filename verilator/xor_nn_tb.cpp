// xor_nn_tb.cpp
#include <iostream>
#include <iomanip>
#include <cmath>
#include "Vxor_nn.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    // Create instance of our module
    Vxor_nn* xor_nn = new Vxor_nn;
    
    // Test cases for XOR
    float test_inputs[4][2] = {{0, 0}, {0, 1}, {1, 0}, {1, 1}};
    float expected[4] = {0, 1, 1, 0};
    
    // Initialize
    xor_nn->clk = 0;
    xor_nn->rst = 1;
    xor_nn->start = 0;
    
    // Reset
    for (int i = 0; i < 5; i++) {
        xor_nn->clk = 0;
        xor_nn->eval();
        xor_nn->clk = 1;
        xor_nn->eval();
    }
    
    xor_nn->rst = 0;
    
    std::cout << "XOR Neural Network Test Results\n";
    std::cout << "================================\n";
    std::cout << std::fixed << std::setprecision(3);
    
    // Test each input combination
    for (int test = 0; test < 4; test++) {
        // Set inputs
        xor_nn->x1 = test_inputs[test][0];
        xor_nn->x2 = test_inputs[test][1];
        xor_nn->start = 1;
        
        // Clock once to start
        xor_nn->clk = 0;
        xor_nn->eval();
        xor_nn->clk = 1;
        xor_nn->eval();
        
        xor_nn->start = 0;
        
        // Wait for done signal
        int cycles = 0;
        while (!xor_nn->done && cycles < 100) {
            xor_nn->clk = 0;
            xor_nn->eval();
            xor_nn->clk = 1;
            xor_nn->eval();
            cycles++;
        }
        
        // Get output
        float output = xor_nn->y_out;
        
        // Check if output is correct (using threshold of 0.5)
        bool pass = (expected[test] > 0.5 && output > 0.5) || 
                    (expected[test] < 0.5 && output < 0.5);
        
        std::cout << "Input: (" << test_inputs[test][0] << ", " 
                  << test_inputs[test][1] << ") -> Output: " 
                  << output << " (Expected: " << expected[test] 
                  << ") - " << (pass ? "PASS" : "FAIL")
                  << " [" << cycles << " cycles]\n";
    }
    
    delete xor_nn;
    return 0;
}
