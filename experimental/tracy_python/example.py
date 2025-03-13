#!/usr/bin/env python3
# Copyright 2025 The IREE Authors
#
# Licensed under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

"""Example script demonstrating Tracy Python bindings with IREE."""

import os
import sys
import time
import numpy as np

# Import the Tracy Python bindings
try:
    # Try to import from tracy_client (the package name may vary depending on how it was built)
    import sys
    from tracy_client import scoped
    tracy_module = "tracy_client"
    print(f"Successfully imported {tracy_module} Python bindings")
except ImportError as e:
    try:
        # Try alternate import if the first one fails
        import tracy
        tracy_module = "tracy"
        print(f"Successfully imported {tracy_module} Python bindings")
    except ImportError:
        print("Tracy Python bindings not found. Make sure they are installed or in your PYTHONPATH.")
        print("PYTHONPATH:", sys.path)
        print("Python version:", sys.version)
        print("\nTroubleshooting tips:")
        print("1. Source the environment: source experimental/tracy_python/source_env.sh")
        print("2. Make sure the Python version matches the one used to build the bindings")
        print("3. Check if the bindings were built with TRACY_CLIENT_PYTHON=ON")
        print("\nYou can continue without tracing support.")
        tracy_module = None

# Try to import IREE's Python bindings
try:
    from iree.runtime import load_vm_module, create_hal_module, create_hal_device, SystemContext, Config
    print("Successfully imported IREE runtime")
    iree_available = True
except ImportError:
    print("IREE runtime Python bindings not found. Some examples will be skipped.")
    print("Install with: python -m pip install iree-base-runtime")
    iree_available = False

def create_simple_module():
    """Create a simple MLIR module and compile it to a bytecode module."""
    if not iree_available:
        print("IREE runtime not available. Skipping module creation.")
        return None
    
    try:
        from iree.compiler import tools as compiler_tools
        print("Successfully imported IREE compiler")
    except ImportError:
        print("IREE compiler Python bindings not found. Skipping module creation.")
        print("Install with: python -m pip install iree-base-compiler")
        return None

    # Create a scoped zone for module compilation
    if tracy_module == "tracy_client":
        zone = scoped.ScopedZone("Compile Module", 0xAAAA00)  # Amber color
    elif tracy_module == "tracy":
        zone = tracy.Zone("Compile Module", color=0xAAAA00)  # Amber color
    else:
        zone = None
        
    # Simple addition module
    module_str = """
    module {
        func.func @add(%arg0: tensor<4xf32>, %arg1: tensor<4xf32>) -> tensor<4xf32> {
            %0 = arith.addf %arg0, %arg1 : tensor<4xf32>
            return %0 : tensor<4xf32>
        }
    }
    """
    
    print("Compiling simple MLIR module...")
    compiled_module = compiler_tools.compile_str(
        module_str,
        target_backends=["vmvx"],
        input_type="stablehlo"
    )
    
    if zone:
        del zone  # End the zone
    
    return compiled_module

def run_example():
    """Example function demonstrating Tracy Python profiling with IREE."""
    # Create a Tracy profiling zone for the entire function
    if tracy_module == "tracy_client":
        main_zone = scoped.ScopedZone("IREE Tracy Example", 0xFF0000)  # Red color
    elif tracy_module == "tracy":
        main_zone = tracy.Zone("IREE Tracy Example", color=0xFF0000)  # Red color
    else:
        main_zone = None  # No tracing

    # Simulate some setup work
    time.sleep(0.1)
    
    if not iree_available:
        print("IREE runtime not available. Running simple timing example instead.")
        
        # Create a device simulation
        if tracy_module == "tracy_client":
            zone = scoped.ScopedZone("Simulated Work", 0x00FF00)  # Green color
        elif tracy_module == "tracy":
            zone = tracy.Zone("Simulated Work", color=0x00FF00)
        else:
            zone = None
        
        # Simulate some computation
        time.sleep(0.3)
        
        if zone:
            del zone  # End the zone
            
        return
    
    # Create a device
    if tracy_module == "tracy_client":
        zone = scoped.ScopedZone("Create IREE Device", 0x00FF00)  # Green color
    elif tracy_module == "tracy":
        zone = tracy.Zone("Create IREE Device", color=0x00FF00)  
    else:
        zone = None
    
    # Create an IREE device (CPU in this case)
    config = Config("local-task")
    context = SystemContext(config=config)
    device = context.create_device()
    
    if zone:
        del zone  # End the zone
    
    # Compile or load a module
    if tracy_module == "tracy_client":
        zone = scoped.ScopedZone("Prepare Module", 0x0000FF)  # Blue color
    elif tracy_module == "tracy":
        zone = tracy.Zone("Prepare Module", color=0x0000FF)
    else:
        zone = None
    
    compiled_module = create_simple_module()
    if compiled_module is None:
        # Create a very simple bytecode module as a fallback
        print("Creating fallback module...")
        
    if zone:
        del zone  # End the zone
    
    # Only proceed with execution if we have a module
    if compiled_module is not None:
        # Execute the function
        if tracy_module == "tracy_client":
            zone = scoped.ScopedZone("Run Inference", 0xFFFF00)  # Yellow color
        elif tracy_module == "tracy":
            zone = tracy.Zone("Run Inference", color=0xFFFF00)
        else:
            zone = None
        
        # Register the module
        vm_module = load_vm_module(context.instance, compiled_module)
        context.add_vm_module(vm_module)
        
        # Create inputs
        a = np.array([1.0, 2.0, 3.0, 4.0], dtype=np.float32)
        b = np.array([5.0, 6.0, 7.0, 8.0], dtype=np.float32)
        
        # Call the function
        fn = context.modules.module["add"]
        result = fn(a, b)
        
        # Flush profiling data
        device.flush_profiling()
        
        print("Input A:", a)
        print("Input B:", b)
        print("Result:", result.to_host())
        
        if zone:
            del zone  # End the zone
    
    # Clean up
    if tracy_module == "tracy_client":
        zone = scoped.ScopedZone("Cleanup", 0xAA00AA)  # Purple color
    elif tracy_module == "tracy":
        zone = tracy.Zone("Cleanup", color=0xAA00AA)
    else:
        zone = None
    
    # In a real example we would clean up IREE resources here
    time.sleep(0.1)
    
    if zone:
        del zone  # End the zone
    
    # Main zone will be automatically closed at the end of the function

if __name__ == "__main__":
    print("Starting IREE Tracy Python example")
    print("Connect the Tracy profiler to see the timeline")
    print("Press Ctrl+C to exit (after letting the example complete)")
    
    # We set TRACY_NO_EXIT=1 to keep the process running after the trace completes
    # This gives the Tracy profiler time to connect
    os.environ["TRACY_NO_EXIT"] = "1"
    
    run_example()
    
    print("Example completed successfully!")
    print("Waiting for Tracy profiler to connect (press Ctrl+C to exit)...")
    
    # Keep the process running to allow the Tracy profiler to connect
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Exiting...")