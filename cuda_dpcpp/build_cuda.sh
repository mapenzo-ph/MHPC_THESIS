#!/bin/bash

# Copyright (C) 2022 Codeplay Software Limited
# This work is licensed under the terms of the MIT license.
# For a copy, see https://opensource.org/licenses/MIT.

BUILD_DIR="build_cuda"

rm -rf $BUILD_DIR
mkdir $BUILD_DIR
cd $BUILD_DIR || exit

export PKG_CONFIG_PATH="$HOME/opengl_libs/glew/lib64/pkgconfig":$PKG_CONFIG_PATH
OGL="$HOME/opengl_libs"

cmake ../ \
-DBACKEND="CUDA" \
-Dglm_DIR="$HOME/opengl_libs/glm/cmake/glm" \
-Dglfw3_DIR="$HOME/opengl_libs/glfw/lib64/cmake/glfw3" \
-DCMAKE_CXX_FLAGS="-I$OGL/glfw/include -I$OGL/glew/include -I$OGL/glm/include" \
-DCMAKE_CXX_STANDARD_LIBRARIES="-lGLdispatch" \
-DCMAKE_EXPORT_COMPILE_COMMANDS=on || exit

make

