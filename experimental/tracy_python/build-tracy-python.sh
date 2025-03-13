#!/bin/bash
# Script to build Tracy Python bindings for IREE

# Get IREE root directory
IREE_ROOT=$(cd "$(dirname "$0")/../.." && pwd)

# Check for pyenv
USE_PYENV=1
if ! command -v pyenv &> /dev/null; then
    echo "pyenv not found, using system Python instead"
    USE_PYENV=0
else
    # Initialize pyenv
    eval "$(pyenv init -)" 
    if command -v pyenv-virtualenv &> /dev/null; then
        eval "$(pyenv virtualenv-init -)"
    fi

    # Set environment name
    PYENV_NAME="iree-tracy-test"

    # Activate or create the environment
    if pyenv virtualenvs | grep -q "$PYENV_NAME"; then
        echo "Activating existing environment $PYENV_NAME"
        pyenv activate "$PYENV_NAME"
    else
        echo "Creating new environment $PYENV_NAME"
        # List available Python versions in pyenv
        echo "Available Python versions:"
        pyenv versions
        
        # Try to use Python 3.12 if available, otherwise use latest available
        if pyenv versions | grep -q "3.12"; then
            PYTHON_VERSION=$(pyenv versions | grep "3.12" | tail -1 | tr -d ' ')
            echo "Using Python version: $PYTHON_VERSION"
            pyenv virtualenv "$PYTHON_VERSION" "$PYENV_NAME"
        else
            echo "Python 3.12 not found in pyenv. Using latest available version."
            # Get latest Python version from pyenv
            LATEST_PYTHON=$(pyenv versions | grep -v system | tail -1 | tr -d ' ')
            echo "Using Python version: $LATEST_PYTHON"
            pyenv virtualenv "$LATEST_PYTHON" "$PYENV_NAME"
        fi
        pyenv activate "$PYENV_NAME"
    fi
fi

# Install required dependencies
echo "Installing build dependencies..."
python -m pip install --upgrade pip
python -m pip install pybind11 wheel setuptools

# Get the Python executable paths
PYTHON_PATH=$(which python)
PYTHON3_PATH=$(which python3)
echo "Using Python: $PYTHON_PATH ($(python --version))"
echo "Using Python3: $PYTHON3_PATH ($(python3 --version))"

# Create build directory
BUILD_DIR="$IREE_ROOT/build-tracy-python"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || { echo "Failed to create build directory"; exit 1; }

# Configure Tracy with Python bindings
echo "Configuring Tracy build with Python bindings..."
cmake "$IREE_ROOT/third_party/tracy" \
    -DTRACY_CLIENT_PYTHON=ON \
    -DTRACY_STATIC=OFF \
    -DPython_EXECUTABLE="$PYTHON_PATH" \
    -DPython3_EXECUTABLE="$PYTHON3_PATH"

# Build Tracy
echo "Building Tracy and Python bindings..."
cmake --build .

# Build Python wheel directly
echo "Building Tracy Python wheel..."
cd "$IREE_ROOT/third_party/tracy/python" || { echo "Failed to change to tracy/python directory"; exit 1; }
python setup.py bdist_wheel
cd "$IREE_ROOT" || { echo "Failed to return to IREE root"; exit 1; }

# Create a source_env.sh file in the current directory
cat > "$IREE_ROOT/experimental/tracy_python/source_env.sh" << 'EOF'
#!/bin/bash
# Script to set up the environment for testing Tracy Python bindings

# Get the absolute path to IREE root directory
IREE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# Add Tracy Python path to PYTHONPATH
export PYTHONPATH="$IREE_ROOT/third_party/tracy/python:$PYTHONPATH"

# Print helpful information
echo "Environment set up for Tracy Python bindings"
echo "PYTHONPATH includes: $IREE_ROOT/third_party/tracy/python"
echo ""
echo "To test the bindings, you can run:"
echo "python $IREE_ROOT/experimental/tracy_python/example.py"
EOF

chmod +x "$IREE_ROOT/experimental/tracy_python/source_env.sh"

# Set PYTHONPATH to include Tracy Python bindings location without installing
export PYTHONPATH="$IREE_ROOT/third_party/tracy/python:$PYTHONPATH"

# Run the test script to verify it works
echo "Running test script..."
cd "$IREE_ROOT/experimental/tracy_python" || { echo "Failed to change to tracy_python directory"; exit 1; }
python test_tracy_python.py

echo "Build completed successfully!"
echo ""
echo "To use Tracy Python bindings without installing, source the environment file:"
echo "source $IREE_ROOT/experimental/tracy_python/source_env.sh"
echo ""
echo "To install the wheel, run:"
echo "python -m pip install $IREE_ROOT/third_party/tracy/python/dist/tracy_client-*.whl"
echo ""
echo "To run the example, after sourcing the environment:"
echo "python $IREE_ROOT/experimental/tracy_python/example.py"