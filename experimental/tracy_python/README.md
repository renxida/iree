# Tracy Python Bindings for IREE

This experimental feature enables Python applications using IREE to emit Tracy profiling events alongside IREE's native events, providing an integrated view of execution timelines across Python application and IREE runtime.

## Overview

[Tracy](https://github.com/wolfpld/tracy) is a real-time, frame-based profiling tool that IREE uses for performance analysis. IREE supports Tracy for both runtime and compiler tracing. With Tracy Python bindings, you can:

- Emit Tracy profiling events from your Python application
- See a unified timeline view spanning both your Python code and IREE's internal execution
- Better understand performance bottlenecks across the entire application stack

## Building IREE with Tracy Python Bindings

First, apply the necessary patches to the Tracy submodule:
```bash
# Apply the required patches to Tracy
cd /path/to/iree/third_party
./apply_tracy_patches.sh
```

Then build with CMake:
```bash
cmake -G Ninja -B ../iree-build/ -S . \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DIREE_ENABLE_RUNTIME_TRACING=ON \
    -DIREE_TRACING_MODE=4 \
    -DIREE_TRACY_ENABLE_PYTHON=ON && \
cmake --build ../iree-build/
```

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

Here's a simple example of how to use Tracy Python bindings (see [tracy's official documentations](https://github.com/wolfpld/tracy) for more info):

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

- `-DIREE_ENABLE_RUNTIME_TRACING=ON`: Enable runtime tracing
- `-DIREE_TRACING_PROVIDER=tracy`: Use Tracy as the tracing provider
- `-DIREE_TRACY_ENABLE_PYTHON=ON`: Enable Tracy Python bindings (automatically enables the other options)

Note: Enabling `-DIREE_TRACY_ENABLE_PYTHON=ON` will cause `TRACY_STATIC` to be set to `OFF`, which may cause problems.