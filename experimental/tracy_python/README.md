# Tracy Python Bindings for IREE

This experimental feature enables Python applications using IREE to emit Tracy profiling events alongside IREE's native events, providing an integrated view of execution timelines across Python application and IREE runtime.

## Overview

[Tracy](https://github.com/wolfpld/tracy) is a real-time, frame-based profiling tool that IREE uses for performance analysis. IREE supports Tracy for both runtime and compiler tracing. With Tracy Python bindings, you can:

- Emit Tracy profiling events from your Python application
- See a unified timeline view spanning both your Python code and IREE's internal execution
- Better understand performance bottlenecks across the entire application stack

## Building Tracy Python Bindings

### Option 1: Enable during standard IREE build

Add the Tracy Python flag when configuring your IREE build:

```bash
# Configure IREE with Tracy Python bindings
cmake -B build -DIREE_ENABLE_RUNTIME_TRACING=ON -DIREE_TRACING_PROVIDER=tracy -DIREE_TRACY_ENABLE_PYTHON=ON ..

# Build IREE (including Tracy Python bindings)
cmake --build build
```

Alternatively, you can just specify `-DIREE_TRACY_ENABLE_PYTHON=ON` and the other required flags will be enabled automatically.

### Option 2: Add to an existing IREE build

If you already have IREE built, you can use the build script to add Tracy Python bindings to your existing build:

```bash
# Build Tracy Python bindings with an existing IREE build
./experimental/tracy_python/build-tracy-python.sh [path-to-existing-build-dir]
```

If you don't specify a build directory, the script will use `build` in your IREE root directory.

The script will:
1. Install required dependencies (pybind11, wheel, setuptools)
2. Configure your IREE build with Tracy Python support (or create a new one if needed)
3. Build the Tracy Python wheel
4. Run the demo script to verify everything works

## Using Tracy Python Bindings

### Setting up the environment

After building, you need to set your PYTHONPATH to use the Tracy Python bindings:

```bash
# Set PYTHONPATH to include Tracy Python bindings
export PYTHONPATH=/path/to/iree/third_party/tracy/python:$PYTHONPATH
```

Alternatively, you can install the wheel:

```bash
# Install the wheel in your Python environment
python -m pip install /path/to/iree/third_party/tracy/python/dist/tracy_client-*.whl
```

### Using in Python applications

Here's a simple example of how to use Tracy Python bindings:

```python
import time

# Import Tracy Python bindings
try:
    from tracy_client import scoped
    
    # Create a profiling zone
    with scoped.ScopedZone("My Zone", 0xFF0000):  # Red color
        # Your code here
        time.sleep(1.0)
        
        # Nested zone
        with scoped.ScopedZone("Nested Zone", 0x00FF00):  # Green color
            time.sleep(0.5)
except ImportError:
    # Fallback if Tracy Python bindings are not available
    print("Tracy Python bindings not available")
```

### Integration with IREE

When using Tracy Python bindings with IREE, you can create a unified timeline view:

```python
# Import Tracy Python bindings
from tracy_client import scoped

# Import IREE runtime
from iree.runtime import create_hal_device

# Create a device with Tracy profiling
with scoped.ScopedZone("Create Device", 0x00FF00):
    device = create_hal_device("local-task")

# Execute IREE functions
with scoped.ScopedZone("Execute", 0xFF0000):
    # Run your IREE code here
    pass

# Flush profiling data (important for long-running applications)
device.flush_profiling()
```

### Demo

Run the included demo to test your setup:

```bash
python experimental/tracy_python/demo.py
```

## Viewing Traces

1. Build and run the Tracy profiler (available from https://github.com/wolfpld/tracy)
2. Run your Python application with Tracy Python bindings
3. The Tracy profiler will automatically connect and display the timeline

## CMake Build Targets

When building with Tracy Python bindings enabled, the following targets are available:

- `tracy-python-wheel`: Builds just the Tracy Python wheel
- `iree-tracy-python`: Builds both TracyClient and the Python wheel
- `tracy-python-dev`: Builds the wheel and prints setup instructions for development

## Troubleshooting

- If you see "Tracy Python bindings not found" errors:
  - Check your PYTHONPATH environment variable includes the tracy/python directory
  - Verify the build completed successfully
- If you don't see any profiling data:
  - Check that the Tracy profiler is running when your application executes
  - Make sure TRACY_NO_EXIT=1 is set if your application is short-lived
  - Call device.flush_profiling() to ensure data is sent to the profiler

## Configuration Options

When building IREE with Tracy Python support, the following CMake options are relevant:

- `DIREE_ENABLE_RUNTIME_TRACING=ON`: Enable runtime tracing
- `DIREE_TRACING_PROVIDER=tracy`: Use Tracy as the tracing provider
- `DIREE_TRACY_ENABLE_PYTHON=ON`: Enable Tracy Python bindings (automatically enables the other options)