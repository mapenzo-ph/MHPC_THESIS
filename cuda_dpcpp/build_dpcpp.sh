#!/bin/bash

# Copyright (C) 2022 Codeplay Software Limited
# This work is licensed under the terms of the MIT license.
# For a copy, see https://opensource.org/licenses/MIT.

BUILD_DIR="build_dpcpp"

rm -rf $BUILD_DIR
mkdir $BUILD_DIR
cd $BUILD_DIR || exit

DPCPP_HOME="$HOME/zip_sycl"
OGL="$HOME/opengl_libs"

PKG_CONFIG_PATH="$OGL/glew/lib64/pkgconfig":$PKG_CONFIG_PATH \
CXX=$DPCPP_HOME/llvm/build/bin/clang++ \
CC=$DPCPP_HOME/llvm/build/bin/clang \
cmake ../ \
-Dglm_DIR="$OGL/glm/cmake/glm" \
-Dglfw3_DIR="$OGL/glfw/lib64/cmake/glfw3" \
-DCMAKE_CXX_FLAGS="-I$OGL/glfw/include -I$OGL/glew/include -I$OGL/glm/include --cuda-path=/cm/shared/apps/cuda11.1/toolkit/11.1.1" \
-DCMAKE_CXX_STANDARD_LIBRARIES="-lGLdispatch" \
-DBACKEND=DPCPP -DDPCPP_CUDA_SUPPORT=on || exit

make

