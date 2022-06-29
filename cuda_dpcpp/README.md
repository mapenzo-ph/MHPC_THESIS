# Compiling nbody

## Generalities
The nbody code can be compiled using both CUDA or SYCL backend. Regardless of the chosen backend, some extra libraries are required, in order to render the graphical part of the code.

The required libraries to be installed are

- [GLM](https://github.com/g-truc/glm)
- [GLFW](https://www.glfw.org/)
- [GLEW](http://glew.sourceforge.net/) 

Further information on how to install the libraries can be found on their deidicated web pages, below we will provide a brief guide on how to install them from source (specific for RHEL).

Note that the GLM library is header-only, thus it does not need to compiled. The following illustrates how to compile the remaining two libraries from source.

### Compiling GLFW and GLEW

Both GLFW and GLEW have native CMake support (CMake 3.4.0 or later) for building. For GLFW the compilation goes as follows: first enter the root folder of the library source code (`glfw-master`), then execute the following commands:
	
	mkdir build && cd build
	cmake .. -DCMAKE_INSTALL_PREFIX=/path/to/desired/location
	cmake --build .
	cmake --build . --target install

 
For GLEW the procedure is similar, enter the `glew-2.2.0/build` folder, then eexecute
	
	cmake ./cmake -DCMAKE_INSTALL_PREFIX=/path/to/desired/location 	-DOpenGL_GL_PREFERENCE="GLVND"
	cmake --build .
	cmake --build . --target install

The `OpenGL_GL_PREFERENCE` can be adjusted, in our case it may be "GLVND", which is the preferred solution, or "legacy", to support older applications. 


###Useful resources:

- [Cmake User Guide](https://cmake.org/cmake/help/latest/guide/user-interaction/)
- [GLFW Installation Guide](https://www.glfw.org/docs/latest/compile_guide.html#compile_cmake)
- [GLEW GitHub page](https://github.com/nigels-com/glew) 



## Compiling with CUDA
In order to compile using the CUDA backend we simply need to modify `scripts/build_cuda.sh` to let CMake find the previously installed libraries. 

For GLFW the build system searches for a file named `glmConfig.cmake`, in order to configure the corresponding module. When building GLFW as above, this file should be stored in `glfw_prefix/lib64/cmake/glfw3`, where `glfw_prefix` is the directory specified during installation. The path to the `.config` file should be provided to CMake via the command-line definition `-Dglfw_Dir=glfw_prefix/lib64/cmake/glfw3` when calling `cmake` in the build script.
Also, we need to tell the compiler the include directories for the 

An analogus situation holds for GLM. In this case the `glmConfig.cmake` file should be in `glm_prefix/cmake/glm`, thus we simply need to add the definition `-Dglm_Dir=glm_prefix/cmake/glm` in the build script.

For GLEW the situation is different. In this case the build system looks for a PkgConfig file `glew.pc`, which should be in `glew_prefix/lib64/pkgconfig`. In order for CMake to find this file we have to add this directory to the corresponding system PATH variable, by exporting it as follows 
`export PKG_CONFIG_PATH=glew_prefix/lib64/pkgconfig:$PKG_CONFIG_PATH` before calling the cmake command in the build script.

At this point the build system should be able to automatically find the libraries it needs, thus we can try to compile the code using the script.

### Known issues
A problem may arise during compilation, due to some GLFW headers not being found. In this case it may be useful to explicitly set the include directories for the dependencies as follows: `-DCMAKE_CXX_FLAGS=-Iglfw_prefix/include`. For good measure, also explicitly set the include directories for GLM and GLEW.

Another issue may arise during the linking of the executable, due to some referenced symbols not found in `libOpenGL.so`. This is probably due to some difference in the libraries with the version used by the autorhs of the code. A quick solution is to eplicitly tell CMake to link to `libGLdispatch.so` as follows
`-DCMAKE_CXX_STANDARD_LIBRARIES=-lGLdispatch`, which should contain the missing symbols.


## Compiling with DPCPP/CLANG
In order to translate the code do dpc++, recompile it using the dpcpp/clang compiler, and run it on CUDA devices, we have to follow a very specific procedure. In particular, in order for the dpc++ compiler to support CUDA devices, we have to build it from [source](https://github.com/intel/llvm), with the support enabled.

### Building DPC++ compiler with CUDA support
First of all, we have clone the source repo with `git clone https://github.com/intel/llvm -b sycl` (use `module load proxy` to enable access to GitHub via internet on the cluster if needed). 

In order to build we need to load a few modules, specifically: `gcc`, `cmake`, `python3` and the CUDA toolkit (either `cuda11.1` or `cuda11.4`, but there may be issues with the visualization nodes if the toolkit version is more recent than the one on the node, thus i used `cuda11.1` for good measure). Also load `proxy` if it is not loaded yet, since configuration requires access to GitHub to download some extra packages.

After this we may prepare a PBS script to perform the compilation. This can be done using the following template

	#!/bin/bash

	#PBS -N build_clang
	#PBS -q gpu
	#PBS -l nodes=1:ppn=4
	#PBS -o build_clang.out
	#PBS -j oe

	cd $PBS_O_WORKDIR
	export DPCPP_HOME=/path/to/source/directory

	module load gcc python3 cuda11.1 cmake proxy

	python $DPCPP_HOME/llvm//buildbot/configure.py --cuda --cmake-gen 	"Unix Makefiles" --cmake-opt="-DCMAKE_LIBRARY_PATH=/cm/shared/apps/	cuda11.1/toolkit/11.1.1/lib64/stubs"

	python $DPCPP_HOME/llvm/buildbot/compile.py -j 4

The only things to set are the `DPCPP_HOME` dir, which has to be set to the directory containing the `llvm` directory cloned from GitHub, and the version of the CUDA toolkit (this is for 11.1, for 11.4 just change the numbers accordingly, and change 11.1.1 to 11.4.2 in the ` -DCMAKE_LIBRARY_PATH` definition). One can also change the number of processors used to build, but if it set too high the build may fail. Once the build is completed, the compiler can be found it `$DPCPP_HOME/llvm/build/bin/clang++`.

### Converting source files to SYCL and compiling
The next step is to convert the source file from CUDA to sycl/dpc++, in order to compile them with the clang we just built.
This is simply done by running `./scripts/cu2dpcpp.sh` from the root directory of the nbody folder (the script is not there by default, it is provided here and should be put in the correct directory).

Before running the script it may be useful to create a copy of the `src_sycl` directory, in order to avoid losing the original files.

Finally, we can compile the converted code using the dpc++ compiler we built before.
This can be done by modifying `scripts/build_dpcpp.sh` in the same way as the `scripts/build_cuda.sh` script.

### Known issues
For compilation, the same considerations hold as for the CUDA case. Furthermore, a problem may arise concerning the CUDA toolkit library not being found. If this is the case, a possible solution is simply to unload the cuda module before compilation, and manually add `--cuda-path=/path/to/cuda/toolkit` to the `-DCMAKE_CXX_FLAGS = ... ` option in the cmake command.

### Useful resources

- [DPC++ build guide](https://github.com/intel/llvm/blob/sycl/sycl/doc/GetStartedGuide.md#test-dpc-toolchain)
- [Codeplay oneAPI for CUDA](https://github.com/codeplaysoftware/cuda-to-sycl-nbody)
- [CUDA\_CUDA\_LIBRARY NOTFOUND fix](https://github.com/floydhub/dl-docker/issues/50) 

## Running the code
The code can only be run using the visualization nodes, since it requires a graphics card with rendering capabilities. It is also advised to compile the code on the visualization nodes themselves, due to some inconsistencies between the versions of the CUDA toolkits across the nodes, which could lead to the code not starting.

In order to run, simply use `./nbody_cuda` or `./nbody_dpcpp` (in the root nbody folder). For the dpcpp version one also needs to add the openGL libraries associated to the compiler to `LD_LIBRARY_PATH`, otherwise the code will not run. These should be in `$DPCPP_HOME/llvm/build/lib`.