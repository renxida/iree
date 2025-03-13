#!/bin/bash
# Script to build Tracy Python bindings for IREE
# This script is designed to work with an existing IREE build

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

# Check if an existing build directory was specified
if [ -n "$1" ]; then
  BUILD_DIR="$1"
  if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Specified build directory '$BUILD_DIR' does not exist"
    echo "Usage: $0 [existing-build-directory]"
    exit 1
  fi
  echo "Using existing build directory: $BUILD_DIR"
else
  # Default to standard build directory
  BUILD_DIR="$IREE_ROOT/build"
  if [ ! -d "$BUILD_DIR" ]; then
    echo "Warning: Default build directory not found. Creating it."
    mkdir -p "$BUILD_DIR"
  fi
  
  echo "Using build directory: $BUILD_DIR"
  cd "$BUILD_DIR"
  
  # Configure if CMakeCache.txt doesn't exist
  if [ ! -f "CMakeCache.txt" ]; then
    echo "Configuring new IREE build with Tracy Python bindings..."
    cmake "$IREE_ROOT" \
      -DIREE_ENABLE_RUNTIME_TRACING=ON \
      -DIREE_TRACY_ENABLE_PYTHON=ON \
      -DIREE_TRACING_PROVIDER=tracy
  else
    # Update existing configuration to enable Tracy Python
    echo "Updating existing build configuration to enable Tracy Python..."
    cmake "$BUILD_DIR" \
      -DIREE_ENABLE_RUNTIME_TRACING=ON \
      -DIREE_TRACY_ENABLE_PYTHON=ON \
      -DIREE_TRACING_PROVIDER=tracy
  fi
fi

# Build Tracy Python targets
echo "Building Tracy Python bindings..."
cd "$BUILD_DIR"
cmake --build . --target tracy-python-wheel

# Build Python wheel if the target didn't already build it
if [ ! -d "$IREE_ROOT/third_party/tracy/python/dist" ] || [ -z "$(ls -A "$IREE_ROOT/third_party/tracy/python/dist")" ]; then
  echo "Building Tracy Python wheel..."
  cd "$IREE_ROOT/third_party/tracy/python"
  python setup.py bdist_wheel
fi

# Setup environment
cd "$IREE_ROOT"
export PYTHONPATH="$IREE_ROOT/third_party/tracy/python:$PYTHONPATH"

# Run the example script to verify everything works
echo "Running demo script to verify Tracy Python bindings..."
python "$IREE_ROOT/experimental/tracy_python/demo.py"

echo "Build completed successfully!"
echo ""
echo "To use Tracy Python bindings in your applications, run:"
echo "export PYTHONPATH=\"$IREE_ROOT/third_party/tracy/python:\$PYTHONPATH\""
echo ""
echo "Or install the wheel directly:"
echo "python -m pip install $IREE_ROOT/third_party/tracy/python/dist/tracy_client-*.whl"
echo ""
echo "To run the demo again:"
echo "python $IREE_ROOT/experimental/tracy_python/demo.py"