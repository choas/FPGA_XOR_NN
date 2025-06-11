import numpy as np

def sigmoid(x):
    return 1 / (1 + np.exp(-x))

def sigmoid_derivative(x):
    return x * (1 - x)

# Training data for XOR
X = np.array([[0, 0], [0, 1], [1, 0], [1, 1]])
y = np.array([[0], [1], [1], [0]])

# Network architecture
input_size = 2
hidden_size = 8
output_size = 1

# Initialize weights
np.random.seed(42)
weights_hidden = np.random.randn(input_size, hidden_size)
bias_hidden = np.zeros((1, hidden_size))
weights_output = np.random.randn(hidden_size, output_size)
bias_output = np.zeros((1, output_size))

# Training
learning_rate = 0.5
epochs = 10000

for epoch in range(epochs):
    # Forward propagation
    hidden_input = np.dot(X, weights_hidden) + bias_hidden
    hidden_output = sigmoid(hidden_input)
    
    output_input = np.dot(hidden_output, weights_output) + bias_output
    predicted_output = sigmoid(output_input)
    
    # Backward propagation
    error = y - predicted_output
    if epoch % 1000 == 0:
        print(f"Epoch {epoch}, Error: {np.mean(np.abs(error)):.4f}")
    
    d_output = error * sigmoid_derivative(predicted_output)
    error_hidden = d_output.dot(weights_output.T)
    d_hidden = error_hidden * sigmoid_derivative(hidden_output)
    
    # Update weights
    weights_output += hidden_output.T.dot(d_output) * learning_rate
    bias_output += np.sum(d_output, axis=0, keepdims=True) * learning_rate
    weights_hidden += X.T.dot(d_hidden) * learning_rate
    bias_hidden += np.sum(d_hidden, axis=0, keepdims=True) * learning_rate

# Convert to fixed-point format
def to_fixed_point(value, frac_bits=8):
    return int(value * (1 << frac_bits))

print("Trained weights in fixed-point format:")
print("// Hidden weights:")
for i in range(hidden_size):
    for j in range(input_size):
        fp_value = to_fixed_point(weights_hidden[j, i])
        print(f"w_hidden[{i*2+j}] = 16'h{fp_value & 0xFFFF:04X};  // {weights_hidden[j, i]:.3f}")

print("\n// Hidden biases:")
for i in range(hidden_size):
    fp_value = to_fixed_point(bias_hidden[0, i])
    print(f"b_hidden[{i}] = 16'h{fp_value & 0xFFFF:04X};  // {bias_hidden[0, i]:.3f}")

print("\n// Output weights:")
for i in range(hidden_size):
    fp_value = to_fixed_point(weights_output[i, 0])
    print(f"w_output[{i}] = 16'h{fp_value & 0xFFFF:04X};  // {weights_output[i, 0]:.3f}")

print("\n// Output bias:")
fp_value = to_fixed_point(bias_output[0, 0])
print(f"b_output = 16'h{fp_value & 0xFFFF:04X};  // {bias_output[0, 0]:.3f}")

# Test the network
print("\nTesting:")
for i in range(len(X)):
    hidden = sigmoid(np.dot(X[i], weights_hidden) + bias_hidden)
    output = sigmoid(np.dot(hidden, weights_output) + bias_output)
    print(f"Input: {X[i]} -> Output: {float(output[0][0]):.3f} (Expected: {y[i][0]})")
