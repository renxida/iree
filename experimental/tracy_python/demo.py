#!/usr/bin/env python3
# Copyright 2025 The IREE Authors
#
# Licensed under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

"""Simple demo for Tracy Python bindings with IREE."""

import os
import sys
import time
import numpy as np

# Set TRACY_NO_EXIT to keep the process running for profiler connection
os.environ["TRACY_NO_EXIT"] = "1"

# Import Tracy Python bindings
try:
    from tracy_client import scoped
    print("Successfully imported tracy_client Python bindings")
    tracy_available = True
except ImportError:
    print("Tracy Python bindings not found in PYTHONPATH")
    print("PYTHONPATH:", os.environ.get("PYTHONPATH", ""))
    print("Run: export PYTHONPATH=/path/to/iree/third_party/tracy/python:$PYTHONPATH")
    tracy_available = False

# Try to import IREE's Python bindings (optional)
try:
    from iree.runtime import load_vm_module, create_hal_device, SystemContext, Config
    print("Successfully imported IREE runtime")
    iree_available = True
except ImportError:
    print("IREE runtime not available (optional)")
    iree_available = False

def demo_tracy():
    """Run simple Tracy profiling demo."""
    if not tracy_available:
        print("Tracy Python bindings not available. Demo cannot continue.")
        return False
    
    print("\n--- Running Tracy Python Demo ---")
    print("Connect Tracy profiler to see the timeline visualization")
    
    # Main zone
    with scoped.ScopedZone("Tracy Demo", 0xFF0000):  # Red color
        print("Main work zone started")
        
        # First task
        with scoped.ScopedZone("Task 1", 0x00FF00):  # Green color
            print("Performing task 1...")
            time.sleep(0.5)
            
            # Nested work
            with scoped.ScopedZone("Nested Work", 0x0000FF):  # Blue color
                print("Performing nested work...")
                time.sleep(0.3)
        
        # Second task with simulated compute work
        with scoped.ScopedZone("Task 2 (Compute)", 0xFFAA00):  # Orange color
            print("Performing compute task...")
            
            # Simulate compute work to show in the profiler
            start = time.time()
            result = 0
            for i in range(1000000):
                result += i
            end = time.time()
            
            print(f"Computation result: {result}, took {end-start:.4f} seconds")
    
    print("Demo completed successfully!")
    return True

def main():
    """Main function to run the Tracy Python demo."""
    success = demo_tracy()
    
    if success:
        print("\nDemo is complete. Waiting for Tracy profiler to connect...")
        print("Press Ctrl+C to exit when finished")
        
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("Exiting...")
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())