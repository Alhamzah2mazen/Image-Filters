Multi-Functional Computer Vision & Image Processing Toolbox
University of Jordan | Computer Vision (Task 3)

A comprehensive MATLAB App Designer-based GUI for real-time image enhancement, spatial/frequency domain filtering, feature detection, and stereo vision analysis. This tool provides an interactive environment to visualize complex computer vision algorithms through a stacked-filter architecture.

🚀 Key Features
🛠 Image Enhancement & Spatial Filtering
Point Operations: Gamma Correction, Histogram Equalization, and Brightness Adjustment.

Smoothing: Box, Weighted Average (Gaussian), and Median filtering.

Sharpening: Laplacian, High-boost filtering, Sobel, and Prewitt operators.

🧬 Advanced Feature Detection
Edge Detection: Sobel, Canny, and Prewitt.

Corner Detection: Harris and FAST (Features from Accelerated Segment Test) algorithms.

Descriptor Extraction: Histogram of Oriented Gradients (HOG) with customizable cell and block sizes.

📐 Geometric & Stereo Vision
Hough Transform: Circular object detection with radius and sensitivity tuning.

RANSAC: Robust Line and Circle detection through iterative estimation.

Stereo Vision: Fundamental Matrix estimation using SURF features and RANSAC, including Epipolar line visualization across dual-view images.

🏗 Architecture
Stackable Filter Chain: Apply multiple filters sequentially using the "Add Filter" functionality.

Pyramidal Analysis: Gaussian and Laplacian pyramid decomposition (up to 6 levels).

Interactive Template Matching: User-defined ROI (Region of Interest) selection for Normalized Cross-Correlation.

📸 Screenshots
<img width="1682" height="946" alt="image" src="https://github.com/user-attachments/assets/7aec79cd-308d-4b12-a1dd-550194907799" />
<img width="345" height="521" alt="image" src="https://github.com/user-attachments/assets/96c5e93a-cd58-41d3-b7f7-0ca89d6c0749" />


🛠 Installation & Usage
Prerequisites
MATLAB (R2021a or later recommended)

Required Toolboxes: * Image Processing Toolbox

Computer Vision Toolbox

How to Run
Clone the repository:

Bash
git clone https://github.com/Alhamzah2mazen/Image-Filters.git
Open MATLAB and navigate to the project folder.

Type Task3_2220165_exported in the Command Window or open the file in App Designer and click Run.

📂 Project Structure
Task3_2220165_exported.mlapp / .m: The core application logic and UI layout.

.gitignore: Configured to exclude MATLAB autosaves (.asv) and large binary data.

🎓 Academic Context
Course: Computer Vision (First Semester - Fourth Year)

Student: Alhamzah Alsaad

Institution: University of Jordan
