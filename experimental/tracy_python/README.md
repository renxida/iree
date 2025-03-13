# Tracy Python Bindings for IREE

This experimental feature enables Python applications using IREE to emit Tracy profiling events alongside IREE's native events, providing an integrated view of execution timelines across Python application and IREE runtime.

## Overview

[Tracy](https://github.com/wolfpld/tracy) is a real-time, frame-based profiling tool that IREE uses for performance analysis. IREE supports Tracy for both runtime and compiler tracing. With Tracy Python bindings, you can:

- Emit Tracy profiling events from your Python application
- See a unified timeline view spanning both your Python code and IREE's internal execution
- Better understand performance bottlenecks across the entire application stack

## Building Tracy Python Bindings

There are multiple ways to build Tracy Python bindings for use with IREE:

### 1. Using build scripts

For convenience, we provide scripts to build Tracy Python bindings:

```bash
# Build minimal configuration (runtime only)
./build-tracy-python-minimal.sh

# Build full configuration (runtime + compiler)
./build-tracy-python-full.sh

# Build standalone Tracy Python bindings
./build-tracy-python.sh
```

### 2. Using CMake directly

You can also build IREE with Tracy Python bindings enabled:

```bash
mkdir build && cd build
cmake .. \
    -DIREE_ENABLE_RUNTIME_TRACING=ON \
    -DIREE_TRACING_PROVIDER=tracy \
    -DIREE_TRACY_ENABLE_PYTHON=ON

# Optionally enable compiler tracing
# -DIREE_ENABLE_COMPILER_TRACING=ON

cmake --build . --target TracyClient
```

## Using Tracy Python Bindings

### Setting up the environment

After building, you have several options to use the Tracy Python bindings:

#### Option 1: Use the source environment script (recommended for development)

```bash
# Source the environment setup script
source experimental/tracy_python/source_env.sh

# Now you can run the example
python experimental/tracy_python/example.py
```

#### Option 2: Set PYTHONPATH manually

```bash
# For development (without installing)
export PYTHONPATH=/path/to/iree/third_party/tracy/python:$PYTHONPATH

# Then run your Python script
python your_script.py
```

#### Option 3: Install the wheel

```bash
# Install the wheel system-wide or in your virtual environment
python -m pip install /path/to/iree/third_party/tracy/python/dist/tracy_client-*.whl
```

> **Note**: Make sure the Python version you use matches the one used to build the bindings. The build scripts use pyenv to ensure version compatibility.

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

When using Tracy Python bindings with IREE, you can create a unified timeline view. Here's an example that shows how to profile both your Python code and IREE operations:

```python
import time
import numpy as np

# Import Tracy Python bindings
try:
    from tracy_client import scoped
    tracy_available = True
except ImportError:
    tracy_available = False

# Import IREE runtime
from iree.runtime import load_vm_module, create_hal_device, VmModule

def run_inference(compiled_module, inputs):
    # Create a Tracy profiling zone for the entire function
    zone = scoped.ScopedZone("IREE Inference", 0xFF0000) if tracy_available else None
    
    # Create device
    device_zone = scoped.ScopedZone("Create Device", 0x00FF00) if tracy_available else None
    device = create_hal_device("local-task")
    if device_zone:
        del device_zone
    
    # Load module
    load_zone = scoped.ScopedZone("Load Module", 0x0000FF) if tracy_available else None
    ctx = create_context(device)
    vm_module = VmModule.from_flatbuffer(ctx.instance, compiled_module)
    ctx.add_vm_module(vm_module)
    if load_zone:
        del load_zone
    
    # Execute function
    execute_zone = scoped.ScopedZone("Execute Function", 0xFFFF00) if tracy_available else None
    function = ctx.modules.module["main"]
    results = function(*inputs)
    
    # Flush profiling data (important for long-running applications)
    device.flush_profiling()
    
    if execute_zone:
        del execute_zone
    
    return results
```

Remember to flush the profiling data periodically for long-running applications:

```python
device = create_hal_device("local-task")
# ... do some work ...
device.flush_profiling()
```

### Complete example

See `example.py` in this directory for a complete example of using Tracy Python bindings with IREE.

## Viewing Traces

1. Build and run the Tracy profiler (available from https://github.com/wolfpld/tracy)
2. Run your Python application with Tracy Python bindings
3. The Tracy profiler will automatically connect and display the timeline

## Troubleshooting

- If you see "Failed to import Tracy Python bindings" errors:
  - Check your PYTHONPATH environment variable includes the tracy/python directory
  - Verify that the Python version used for running matches the version used for building
  - Try using the source_env.sh script to set up your environment
- If the bindings fail to build:
  - Make sure TracyClient is built with TRACY_CLIENT_PYTHON=ON
  - Ensure you have pybind11 installed (`pip install pybind11`)
  - Check CMake output for any errors related to Python detection
- If you don't see any profiling data:
  - Check that the Tracy profiler is running when your application executes
  - Make sure TRACY_NO_EXIT=1 is set if your application is short-lived
  - Call device.flush_profiling() to ensure data is sent to the profiler
- Python version mismatches:
  - The wheel is built for a specific Python version (e.g., 3.12)
  - Use the same Python version for running as for building
  - Use pyenv to maintain consistent Python environments

## Configuration Options

When building IREE with Tracy Python support, the following CMake options are relevant:

- `DIREE_ENABLE_RUNTIME_TRACING=ON`: Enable runtime tracing
- `DIREE_ENABLE_COMPILER_TRACING=ON`: Enable compiler tracing
- `DIREE_TRACING_PROVIDER=tracy`: Use Tracy as the tracing provider
- `DIREE_TRACY_ENABLE_PYTHON=ON`: Enable Tracy Python bindings
- `DIREE_TRACING_MODE`: Set tracing verbosity (default: 2)