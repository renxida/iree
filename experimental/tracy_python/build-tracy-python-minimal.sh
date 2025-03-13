#!/bin/bash
# Script to build a minimal Tracy Python test

# Initialize pyenv
eval "$(pyenv init -)" 
eval "$(pyenv virtualenv-init -)"

# Set environment name
PYENV_NAME="iree-tracy-test"
pyenv activate "$PYENV_NAME"

# Create build directory
BUILD_DIR="build-tracy-python-minimal"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure Tracy with Python bindings
echo "Configuring minimal Tracy Python build..."
cmake .. \
    -DIREE_BUILD_COMPILER=OFF \
    -DIREE_ENABLE_RUNTIME_TRACING=ON \
    -DIREE_TRACY_ENABLE_PYTHON=ON \
    -DIREE_TRACING_PROVIDER=tracy

# Build Tracy
echo "Building Tracy and Python bindings..."
cmake --build . --target TracyClient

# Test Tracy Python bindings
cd ..
export PYTHONPATH="$PWD/third_party/tracy/python:$PYTHONPATH"
echo "Running test script..."
python test_tracy_python.py