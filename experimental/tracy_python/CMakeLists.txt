# Copyright 2025 The IREE Authors
#
# Licensed under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Early exit if Tracy Python bindings are not enabled
if(NOT (IREE_ENABLE_RUNTIME_TRACING AND IREE_TRACING_PROVIDER STREQUAL "tracy" AND IREE_TRACY_ENABLE_PYTHON))
  return()
endif()

message(STATUS "Configuring experimental Tracy Python bindings")

# Add Python prerequisites
find_package(Python3 COMPONENTS Interpreter Development)
if(NOT Python3_FOUND)
  message(WARNING "Python3 not found, skipping Tracy Python bindings")
  return()
endif()

#-------------------------------------------------------------------------------
# Check Tracy build configuration
#-------------------------------------------------------------------------------

# Ensure Tracy library is configured to build with Python support
if(NOT DEFINED TRACY_CLIENT_PYTHON)
  set(TRACY_CLIENT_PYTHON ON CACHE BOOL "Build Tracy Python bindings" FORCE)
endif()

if(NOT DEFINED TRACY_STATIC)
  set(TRACY_STATIC OFF CACHE BOOL "Build Tracy as a static library" FORCE)
endif()

#-------------------------------------------------------------------------------
# Helper functions
#-------------------------------------------------------------------------------

# Gets the Tracy Python path for environment variables
function(iree_get_tracy_python_path TRACY_PYTHON_PATH)
  set(${TRACY_PYTHON_PATH} "${CMAKE_SOURCE_DIR}/third_party/tracy/python" PARENT_SCOPE)
endfunction()

# Adds Tracy Python path to PYTHONPATH if enabled
function(iree_append_tracy_python_path PYTHONPATH)
  iree_get_tracy_python_path(_TRACY_PYTHON_PATH)
  if(_TRACY_PYTHON_PATH)
    set(${PYTHONPATH} "${${PYTHONPATH}};${_TRACY_PYTHON_PATH}" PARENT_SCOPE)
  else()
    set(${PYTHONPATH} "${${PYTHONPATH}}" PARENT_SCOPE)
  endif()
endfunction()

#-------------------------------------------------------------------------------
# Installation and targets
#-------------------------------------------------------------------------------

# Make sure the TracyClient target exists
if(NOT TARGET TracyClient)
  message(WARNING "TracyClient target not found. Tracy Python bindings may not build correctly.")
endif()

# Create an installation target for Tracy Python
iree_add_install_target(
  NAME iree-install-tracy-python
  COMPONENT IREETracyPython
)

# Install Tracy Python examples and scripts
install(
  FILES
    README.md
    demo.py
    build-tracy-python.sh
  DESTINATION ${CMAKE_INSTALL_PREFIX}/share/iree/experimental/tracy_python
  COMPONENT IREETracyPython
)

# Add a target for building the Python wheel that depends on the TracyClient library
add_custom_target(tracy-python-wheel
  COMMAND ${Python3_EXECUTABLE} -m pip install --upgrade pip pybind11 wheel setuptools
  # Create build directories in the binary dir
  COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/experimental/tracy_python/dist
  # Copy Python module to build directory to maintain consistent structure
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/third_party/tracy/python/tracy_client ${CMAKE_BINARY_DIR}/experimental/tracy_python/tracy_client
  # Copy the native binding and library to build directory (required by Python module to load)
  COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:TracyClientBindings> ${CMAKE_BINARY_DIR}/experimental/tracy_python/tracy_client/
  COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:TracyClient> ${CMAKE_BINARY_DIR}/experimental/tracy_python/tracy_client/
  # Copy setup.py and other files needed for installation
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/third_party/tracy/python/setup.py ${CMAKE_BINARY_DIR}/experimental/tracy_python/setup.py
  COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/README.md ${CMAKE_BINARY_DIR}/experimental/tracy_python/README.md
  # Build wheel in the binary directory
  COMMAND ${Python3_EXECUTABLE} setup.py bdist_wheel --dist-dir=${CMAKE_BINARY_DIR}/experimental/tracy_python/dist
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/experimental/tracy_python
  COMMENT "Building Tracy Python wheel"
  DEPENDS TracyClient TracyClientBindings
  VERBATIM
)

# Add tracy-python-dev target for development that builds the wheel and exports PYTHONPATH
add_custom_target(tracy-python-dev
  COMMAND ${CMAKE_COMMAND} -E echo "Setting PYTHONPATH=${CMAKE_BINARY_DIR}/experimental/tracy_python"
  COMMAND ${CMAKE_COMMAND} -E echo "Run: export PYTHONPATH=${CMAKE_BINARY_DIR}/experimental/tracy_python:\$$PYTHONPATH"
  DEPENDS tracy-python-wheel
  COMMENT "Tracy Python development setup complete"
  VERBATIM
)

# Install Python bindings
install(
  DIRECTORY ${CMAKE_SOURCE_DIR}/third_party/tracy/python/
  DESTINATION ${CMAKE_INSTALL_PREFIX}/share/tracy/python
  COMPONENT IREETracyPython
  PATTERN "build" EXCLUDE
  PATTERN "dist" EXCLUDE
  PATTERN "__pycache__" EXCLUDE
  PATTERN "*.pyc" EXCLUDE
)

# Install built wheel if available
install(
  DIRECTORY ${CMAKE_BINARY_DIR}/experimental/tracy_python/dist/
  DESTINATION ${CMAKE_INSTALL_PREFIX}/share/tracy/python/dist
  COMPONENT IREETracyPython
  OPTIONAL
)

# Add testing target that only runs if tracy-python-wheel has been built
add_test(
  NAME tracy_python_bindings_test
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/demo.py
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
set_tests_properties(tracy_python_bindings_test PROPERTIES
  ENVIRONMENT "PYTHONPATH=${CMAKE_BINARY_DIR}/experimental/tracy_python:$ENV{PYTHONPATH}"
  DEPENDS tracy-python-wheel
)

# Create a convenience target that builds Tracy client with Python bindings
add_custom_target(iree-tracy-python ALL
  DEPENDS TracyClient tracy-python-wheel
  COMMENT "Building Tracy with Python bindings"
)