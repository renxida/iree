#!/bin/bash
# Script to build Tracy Python bindings for IREE

# Initialize pyenv
eval "$(pyenv init -)" 
eval "$(pyenv virtualenv-init -)"

# Set environment name
PYENV_NAME="iree-tracy-test"

# Activate or create the environment
if pyenv virtualenvs | grep -q "$PYENV_NAME"; then
    echo "Activating existing environment $PYENV_NAME"
    pyenv activate "$PYENV_NAME"
else
    echo "Creating new environment $PYENV_NAME"
    pyenv virtualenv 3.12.8 "$PYENV_NAME"
    pyenv activate "$PYENV_NAME"
fi

# Install required dependencies
echo "Installing build dependencies..."
python -m pip install --upgrade pip
python -m pip install pybind11 wheel setuptools

# Get the Python executable paths
PYTHON_PATH=$(which python)
PYTHON3_PATH=$(which python3)
echo "Using Python: $PYTHON_PATH"
echo "Using Python3: $PYTHON3_PATH"

# Change to IREE directory
cd "$(dirname "$0")"  # Assuming script is in IREE root

# Create build directory
BUILD_DIR="build-tracy-python"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure Tracy with Python bindings
echo "Configuring Tracy build with Python bindings..."
cmake ../third_party/tracy \
    -DTRACY_CLIENT_PYTHON=ON \
    -DPython_EXECUTABLE="$PYTHON_PATH" \
    -DPython3_EXECUTABLE="$PYTHON3_PATH"

# Build Tracy
echo "Building Tracy and Python bindings..."
cmake --build .

# Directory for Python wheel
cd ..

# Build Python wheel directly
echo "Building Tracy Python wheel..."
cd third_party/tracy/python
python setup.py bdist_wheel
cd ../../..

# Install Tracy Python bindings (commented out)
# Uncomment the next line to install the wheel into your Python environment
# python -m pip install third_party/tracy/python/dist/tracy_client-*.whl

echo "Testing Tracy Python bindings..."
# Set PYTHONPATH to include Tracy Python bindings location without installing
export PYTHONPATH="$PWD/third_party/tracy/python:$PYTHONPATH"

# Run the test script to verify it works
echo "Running test script..."
python test_tracy_python.py

echo "Build completed successfully!"
echo ""
echo "To use Tracy Python bindings without installing, add this to your PYTHONPATH:"
echo "export PYTHONPATH=$PWD/third_party/tracy/python:\$PYTHONPATH"
echo ""
echo "To install the wheel, run:"
echo "python -m pip install $PWD/third_party/tracy/python/dist/tracy_client-*.whl"