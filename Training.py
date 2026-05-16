import tensorflow as tf
from tensorflow.keras import layers, models
import numpy as np
import sys

# Ensure numpy doesn't truncate the output arrays with '...' when writing to the file
np.set_printoptions(threshold=sys.maxsize)

# 1. Load and preprocess the MNIST dataset
mnist = tf.keras.datasets.mnist
(x_train, y_train), (x_test, y_test) = mnist.load_data()

# Normalize pixel values to be between 0 and 1
x_train, x_test = x_train / 255.0, x_test / 255.0

# Add a channels dimension (required for CNNs)
x_train = x_train[..., tf.newaxis]
x_test = x_test[..., tf.newaxis]

# 2. Build the Model
model = models.Sequential([
    # Convolutional Layer 1: 8 filters, 3x3 kernel, stride 1, no padding ('valid')
    layers.Conv2D(8, (3, 3), strides=1, padding='valid', activation='relu', input_shape=(28, 28, 1), name='conv_1'),
    # Max Pooling 1: stride 2 (pool size 2x2 is standard for a stride of 2)
    layers.MaxPooling2D(pool_size=(2, 2), strides=2, name='pool_1'),
    
    # Convolutional Layer 2: 16 filters, 3x3 kernel, stride 1, no padding ('valid')
    layers.Conv2D(16, (3, 3), strides=1, padding='valid', activation='relu', name='conv_2'),
    # Max Pooling 2: stride 2
    layers.MaxPooling2D(pool_size=(2, 2), strides=2, name='pool_2'),
    
    # Flattening the 16 5x5 images into a 1D vector (16 * 5 * 5 = 400 features)
    layers.Flatten(name='flatten'),
    
    # Fully Connected (Dense) Layer: 10 units for the 10 digit classes
    layers.Dense(10, activation='softmax', name='dense_out')
])

# Display architecture to confirm dimensions (you will see the 5x5x16 before the flatten layer)
model.summary()

# 3. Compile and Train the Model
model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

print("\nStarting Training...")
# Training for 2 epochs for demonstration. Increase epochs for better accuracy.
model.fit(x_train, y_train, epochs=2, validation_data=(x_test, y_test))

# 4. Extract Weights and Biases and save to a .doc file
# Note: Writing plain text to a .doc extension creates a file MS Word can open cleanly.
file_name = 'model_weights_and_biases.doc'

print(f"\nExtracting weights and saving to {file_name}...")
with open(file_name, 'w') as f:
    f.write("CNN Model Weights and Biases\n")
    f.write("============================\n\n")
    
    for layer in model.layers:
        # Check if the layer has weights (e.g., pooling/flatten layers do not)
        if len(layer.get_weights()) > 0:
            weights, biases = layer.get_weights()
            
            f.write(f"Layer Name: {layer.name.upper()}\n")
            f.write(f"Weights Shape: {weights.shape}\n")
            f.write(f"Biases Shape: {biases.shape}\n\n")
            
            f.write("--- WEIGHTS ---\n")
            # array2string formats the array cleanly
            f.write(np.array2string(weights, separator=', '))
            f.write("\n\n")
            
            f.write("--- BIASES ---\n")
            f.write(np.array2string(biases, separator=', '))
            f.write("\n\n")
            f.write("*" * 50 + "\n\n")

print("Process Complete. Check your directory for the .doc file.")
