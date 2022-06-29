#!/bin/bash
module load OneAPI_2022/dpct

# remove previuously converted sources and copy back originals
rm src_sycl/*.[ch]pp src_sycl/*.yaml
cp -r src/*[ch]pp src_sycl/

# convert cuda file
dpct --out-root=src_sycl \
     --assume-nd-range-dim=1 \
     --use-custom-helper=none \
     --stop-on-parse-err \
     --sycl-named-lambda \
     --cuda-include-path=/cm/shared/apps/cuda11.1/toolkit/11.1.1/include \
     src/simulator.cu

# change references to headers in other files
sed -i 's/simulator.cuh/simulator.dp.hpp/g' src_sycl/renderer.hpp
sed -i 's/simulator.cuh/simulator.dp.hpp/g' src_sycl/nbody.cpp

