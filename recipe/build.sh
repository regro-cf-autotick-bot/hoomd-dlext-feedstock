#!/bin/bash

set -euxo pipefail

rm -rf build || true

CMAKE_FLAGS="  -DCMAKE_INSTALL_PREFIX=${PREFIX}"
CMAKE_FLAGS+=" -DCMAKE_BUILD_TYPE=Release"

if [ -z "${PYTHON+x}" ]; then
    PYTHON="${PREFIX}/bin/python"
fi

PYTHON_SITELIB=$( $PYTHON -c 'import sysconfig; print(sysconfig.get_path("purelib"), end="")' )
if [[ $HOOMD_TAG != v2 ]]; then
    CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}:${PYTHON_SITELIB}"
fi

if (( CUDA_MAJOR > 0 )); then
    CMAKE_FLAGS+=" -DCMAKE_CUDA_HOST_COMPILER=${CXX}"
    if (( CUDA_MAJOR < 12 )); then
        CMAKE_FLAGS+=" -DCMAKE_CUDA_COMPILER=${CUDA_HOME}/bin/nvcc "
    else
        [[ ${target_platform} == "linux-64" ]] && targetsDir="targets/x86_64-linux"
        [[ ${target_platform} == "linux-ppc64le" ]] && targetsDir="targets/ppc64le-linux"
        [[ ${target_platform} == "linux-aarch64" ]] && targetsDir="targets/sbsa-linux"

        # The conda-forge build system does not provide libcuda from an NVIDIA driver, so we link to the stub.
        CMAKE_FLAGS+=" -DCUDA_cuda_LIBRARY=${PREFIX}/${targetsDir}/lib/stubs/libcuda.so"
    fi
fi

if [[ "$target_platform" == osx* ]]; then
    CMAKE_FLAGS+=" -DPython_ROOT_DIR=${PREFIX}"
    # work around 'operator delete is unavailable' on macOS
    # https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

# Build and install
BUILD_PATH=build/hoomd-dlext
cmake ${CMAKE_ARGS} -S . -B $BUILD_PATH $CMAKE_FLAGS -Wno-dev
cmake --build $BUILD_PATH --target install
