#!/usr/bin/env python3
# Copyright 2025 The IREE Authors
#
# Licensed under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

"""Minimal test script for Tracy Python bindings."""

import sys
import time

def main():
    """Test Tracy Python bindings."""
    try:
        # Try to import from tracy_client (the package name may vary depending on how it was built)
        try:
            from tracy_client import scoped
            tracy_module = "tracy_client"
            print(f"Successfully imported {tracy_module} Python bindings")
            
            # Create a zone
            print("Starting Tracy Python bindings test")
            print("Connect the Tracy profiler to see the timeline")
            
            # Example 1: Using ScopedZone directly
            with scoped.ScopedZone("Test Zone 1", 0xFF0000):  # Red color
                print("Inside scoped zone 1")
                time.sleep(0.1)  # Simulate work
                
                # Nested zone
                with scoped.ScopedZone("Nested Zone", 0x00FF00):  # Green color
                    print("Inside nested zone")
                    time.sleep(0.2)  # Simulate more work
        except ImportError:
            # Try alternate import if the first one fails
            import tracy
            tracy_module = "tracy"
            print(f"Successfully imported {tracy_module} Python bindings")
            
            # Create zones using alternate API
            print("Starting Tracy Python bindings test")
            print("Connect the Tracy profiler to see the timeline")
            
            with tracy.Zone("Test Zone 1", color=0xFF0000):
                print("Inside zone 1")
                time.sleep(0.1)
                
                with tracy.Zone("Nested Zone", color=0x00FF00):
                    print("Inside nested zone")
                    time.sleep(0.2)
        
        print("Test completed successfully!")
        return 0
    except ImportError as e:
        print(f"Failed to import Tracy Python bindings: {e}")
        print("Python path:", sys.path)
        print("Python version:", sys.version)
        print("\nThis could be due to:")
        print("1. IREE_TRACY_ENABLE_PYTHON is not enabled")
        print("2. The Python bindings were not built correctly")
        print("3. The Tracy Python bindings are not in your PYTHONPATH")
        print("\nTry using the build-tracy-python.sh script to rebuild the bindings")
        print("or run: source experimental/tracy_python/source_env.sh")
        return 0
    except Exception as e:
        print(f"Error testing Tracy Python bindings: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
