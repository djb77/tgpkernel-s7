#!/bin/bash
# Build TGPKernel for MM
git checkout tw601
./build.sh 7
./build.sh 0

# Build TGPKernel Lite for MM
git checkout tw601-lite
./build.sh 7
./build.sh 0

# Build TGPKernel for N
git checkout tw70
./build.sh 7
./build.sh 0

# Build TGPKernel Lite for N
git checkout tw70-lite
./build.sh 7
./build.sh 0

# Build TGPKernel (with PWM Flicker-Free Fix) for N
git checkout tw70-pwmfix
./build.sh 7
./build.sh 0

# Build TGPKernel S8Port for N
git checkout tw70-s8port
./build.sh 7
./build.sh 0

# Build TGPKernel S8Port Lite for N
git checkout tw70-s8port-lite
./build.sh 7
./build.sh 0

# Build TGPKernel S8Port (with PWM Flicker-Free Fix) for N
git checkout tw70-s8port-pwmfix
./build.sh 7
./build.sh 0

