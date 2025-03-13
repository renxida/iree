#!/bin/bash
# Script to build Tracy Python bindings with full IREE configuration

# Initialize pyenv
eval "$(pyenv init -)" 
eval "$(pyenv virtualenv-init -)"

# Set environment name
PYENV_NAME="iree-tracy-test"
pyenv activate "$PYENV_NAME"

# Create build directory
BUILD_DIR="build-tracy-python-full"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure Tracy with Python bindings
echo "Configuring full Tracy Python build..."
cmake .. \
    -DIREE_BUILD_COMPILER=ON \
    -DIREE_ENABLE_RUNTIME_TRACING=ON \
    -DIREE_ENABLE_COMPILER_TRACING=ON \
    -DIREE_TRACY_ENABLE_PYTHON=ON \
    -DIREE_TRACING_PROVIDER=tracy

# Build Tracy and the runtime
echo "Building Tracy and Python bindings..."
cmake --build . --target TracyClient

# Build the Tracy Python wheel
echo "Building Tracy Python wheel..."
cd ../third_party/tracy/python
python setup.py bdist_wheel
cd ../../../"$BUILD_DIR"

# Test Tracy Python bindings
cd ..
export PYTHONPATH="$PWD/third_party/tracy/python:$PYTHONPATH"
echo "Running test script..."
python test_tracy_python.py

echo "Full build completed successfully!"
echo ""
echo "To use Tracy Python bindings without installing, add this to your PYTHONPATH:"
echo "export PYTHONPATH=$PWD/third_party/tracy/python:\$PYTHONPATH"
echo ""
echo "To install the wheel, run:"
echo "python -m pip install $PWD/third_party/tracy/python/dist/tracy_client-*.whl"