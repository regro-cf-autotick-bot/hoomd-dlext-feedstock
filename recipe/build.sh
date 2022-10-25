#!/bin/bash

set -euxo pipefail

rm -rf build || true

CMAKE_FLAGS="  -DCMAKE_INSTALL_PREFIX=${PREFIX}"
CMAKE_FLAGS+=" -DCMAKE_BUILD_TYPE=Release"

HOOMDv2=$( $PYTHON -c 'import hoomd; print(getattr(hoomd, "__version__", "").startswith("2."), end="")' )
PYTHON_SITELIB=$( $PYTHON -c 'import sysconfig; print(sysconfig.get_path("purelib"), end="")' )
if [[ ${HOOMDv2} == False ]]; then
    CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}:${PYTHON_SITELIB}"
fi

# if CUDA_HOME is defined and not empty, we enable CUDA
if [[ -n ${CUDA_HOME-} ]]; then
    CMAKE_FLAGS+=" -DCMAKE_CUDA_COMPILER=${CUDA_HOME}/bin/nvcc "
    CMAKE_FLAGS+=" -DCMAKE_CUDA_HOST_COMPILER=${CXX}"
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
