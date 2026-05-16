## 📌 Overview

This project is a custom, from-scratch hardware implementation of a Convolutional Neural Network (CNN) written entirely in Verilog. Bypassing High-Level Synthesis (HLS) tools and third-party IP blocks, this project implements a deep, pipelined architecture at the Register-Transfer Level (RTL) using pure digital logic.

The architecture is designed to classify images (e.g., handwritten digits) using a deeply parallelized datapath, custom finite state machines (FSMs), and 8-bit fixed-point arithmetic.

## 🧠 Module-Level Architecture

The network is built using a highly modular, hierarchical Verilog design. Data streams continuously through the pipeline, coordinated by strict `valid_in` and `valid_out` handshaking signals to prevent data corruption between processing stages.

### 1. `window` (Sliding Window Buffer)

In hardware, you cannot fetch a 3x3 grid of pixels from a single-port memory simultaneously. The `window` module acts as a smart caching system (using shift registers and line buffers). It delays the incoming sequential pixel stream just enough to output a parallel 3x3 receptive field on a single clock edge. This prevents the convolution engines from stalling while waiting for memory reads.

### 2. `Convulation` (The Math Engine & Activation)

This is the fundamental processing element of the network, designed for maximum throughput using a deeply pipelined architecture.

* **Stage 0 (Multiplication):** Instantiates 9 parallel multipliers to compute the dot product of the 3x3 pixel window and the 8-bit fixed-point weights.
* **Stage 1 & 2 (Addition Tree):** Instead of adding all 9 products in a single clock cycle—which would create a massive combinational delay and ruin the maximum clock frequency—the addition is broken down into an addition tree over three clock cycles.
* **Hardware ReLU & Scaling:** Before outputting the final feature map, the accumulated sum is logically shifted right (`>>> FRAC_BITS`) to rescale the fixed-point math and safely add the hardware bias. Finally, a native hardware Rectified Linear Unit (ReLU) checks the 2's complement sign-bit (`shifted_sum[23] == 1`). If negative, it outputs zero; if positive, it passes the value (while applying saturation logic to prevent 8-bit overflow).

### 3. `Pooling` (Dimensionality Reduction)

This module implements 2x2 Max Pooling to reduce the spatial dimensions of the feature maps, drastically cutting the computational load for deeper layers.

* **Memory-Efficient Buffering:** Instead of storing the entire image, it uses a single line buffer (`Buffer0`) to hold the previous row of pixels.
* **Combinational Max Logic:** It uses instantaneous combinational comparators to evaluate a 2x2 grid. It finds the maximum of the current row, the maximum of the buffered previous row, and then compares those two results to output the absolute maximum pixel.
* **Smart Counters:** It uses `row_count` and `col_count` logic to know exactly when a 2x2 grid is complete, only pulsing `valid_out` high on odd rows and odd columns.

### 4. `Filter` (Processing Wrapper)

A structural wrapper that acts as a complete single-channel feature extractor. It seamlessly wires one `Convulation` module directly into one `Pooling` module. It takes the raw 3x3 window, performs the convolution, applies the ReLU, and feeds the activated stream immediately into the down-sampling pooling logic, outputting a fully processed, reduced feature map.

### 5. `conv_layer1` (First Spatial Extractor)

The entry point of the network. It takes the raw 1-channel input image (e.g., 28x28 grayscale) and generates the sliding windows. It broadcasts these 3x3 parallel pixel grids to multiple `Filter` modules instantiated in parallel. If the layer is designed for 8 filters, it computes and streams 8 distinct feature maps simultaneously.

### 6. `conv_layer2` (Deep Multi-Channel Aggregation)

The heaviest computational block in the design. Unlike Layer 1, Layer 2 must process multiple input channels simultaneously to find complex patterns. It relies on a massive, perfectly balanced addition tree to compute the dot products across all incoming channels for a single output pixel (e.g., multiplying and summing 72 parallel values for an 8-channel input) before routing the final sum through the bias and ReLU activation. If the layer is designed for 16 filters, it computes and streams 16 distinct feature maps (5X5) simultaneously.

### 7. `dense_layer` (Fully Connected Classifier)

A highly optimized sequential Multiply-Accumulate (MAC) unit governed by a custom 5-stage Finite State Machine (`IDEAL`, `FLAT`, `MULTIPLY`, `ADD`, `DONE`).

* **Dynamic Memory Mapping:** It captures the parallel multi-channel output from the final convolutional layer and dynamically routes it into a 1D sequential buffer, perfectly mirroring the standard Keras `channels_last` memory layout.
* **Sequential Processing:** It computes the final class scores by streaming the flattened pixels against the dense weight memory over hundreds of clock cycles, reusing multipliers to save expensive FPGA DSP slices.
* **Safe Accumulation:** It performs an internal fractional shift on the intermediate MAC products, matching the scale of the 8-bit hardware biases before the final addition to prevent catastrophic quantization overflow.

### 8. `top_layer` (Top-Level SoC Orchestrator)

The structural root of the design. It instantiates all the layers, wires the massive parallel datapaths together, distributes the global clock and reset signals, and manages the pipeline timing. It accepts the raw image data from memory and outputs the final unnormalized digit predictions (`n0` through `n9`) for classification.

## ⚙️ Core Highlights

### Custom State Machine for Dense Processing

To bridge the gap between 2D spatial feature maps and 1D dense weights, the `dense_layer` utilizes a custom FSM. It efficiently handles the massive fan-in required for fully connected layers without exhausting the FPGA's routing resources or DSP slices.

### Fixed-Point Math & Hardware Scaling

Floating-point arithmetic is too resource-heavy for raw RTL. This network is quantized to 8-bit fixed-point integers (`SIZE=8`, `FRAC_BITS=8`).

* Fractional scaling is handled via bit-shifting rather than division to save logic.
* To prevent overflow and maintain precision during bias addition, scaling is dynamically tracked across multiplier boundaries.

## 🔬 Known Limitations: Quantization Error

While the Verilog datapaths, state machines, and addition trees are mathematically verified and functionally sound, the current iteration experiences a drop in predictive accuracy compared to its Python counterpart.

This is a well-documented hardware phenomenon known as **Quantization Loss**.

* The baseline model was trained in Python using 32-bit floating-point precision.
* The weights were extracted via Post-Training Quantization (PTQ) and truncated to 8-bit 2's complement integers.
* Because the network was not trained using **Quantization-Aware Training (QAT)**, it struggles to absorb the aggressive truncation of its weights and feature maps at each layer depth.

**Future Work:** Implementing QAT in TensorFlow to simulate 8-bit truncation during the backward pass will force the model to adapt to the hardware's strict `FRAC_BITS` boundaries, restoring parity between the software model and the Verilog RTL.

## 🚀 How to Run the Simulation

1. Load the Verilog source files (`top_layer.v`, `conv_layer.v`, `pooling.v`, `dense_layer.v`, etc.) into your preferred simulator (Vivado, ModelSim, or Icarus Verilog).
2. Ensure the hex memory files (`.mem`) containing the exported weights, biases, and test images are placed in the root simulation directory.
3. Run the top-level testbench. The design will pulse `valid_out` high and populate the `n0` through `n9` registers with the final unnormalized class confidence scores.

---
