#!/bin/bash
# Simple script to build Tracy Python bindings for IREE

set -e  # Exit on error

# Get IREE root directory
IREE_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
echo "Using IREE root directory: $IREE_ROOT"

# Check Python availability
echo "Using Python: $(which python) ($(python --version))"

# Install required dependencies
echo "Installing build dependencies..."
python -m pip install --upgrade pip
python -m pip install pybind11 wheel setuptools

# Create build directory
BUILD_DIR="$IREE_ROOT/build-tracy-python"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with Tracy Python bindings
echo "Configuring Tracy build with Python bindings..."
cmake "$IREE_ROOT" \
    -DIREE_BUILD_COMPILER=OFF \
    -DIREE_ENABLE_RUNTIME_TRACING=ON \
    -DIREE_TRACY_ENABLE_PYTHON=ON \
    -DIREE_TRACING_PROVIDER=tracy

# Build Tracy
echo "Building Tracy and Python bindings..."
cmake --build . --target TracyClient

# Build Python wheel
echo "Building Tracy Python wheel..."
cd "$IREE_ROOT/third_party/tracy/python"
python setup.py bdist_wheel

# Setup environment
cd "$IREE_ROOT"
export PYTHONPATH="$IREE_ROOT/third_party/tracy/python:$PYTHONPATH"

# Run the example script to verify everything works
echo "Running demo script..."
python "$IREE_ROOT/experimental/tracy_python/demo.py"

echo "Build completed successfully!"
echo ""
echo "To use Tracy Python bindings in the future, run:"
echo "export PYTHONPATH=\"$IREE_ROOT/third_party/tracy/python:\$PYTHONPATH\""
echo ""
echo "To run the demo again:"
echo "python $IREE_ROOT/experimental/tracy_python/demo.py"