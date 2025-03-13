# Copyright 2025 The IREE Authors
#
# Licensed under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Set the package root for this experimental project
set(IREE_PACKAGE_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR}/../..)
cmake_path(ABSOLUTE_PATH IREE_PACKAGE_ROOT_DIR
  BASE_DIRECTORY ${IREE_PACKAGE_ROOT_DIR}
  NORMALIZE
  OUTPUT_VARIABLE IREE_PACKAGE_ROOT_DIR)
set(IREE_PACKAGE_ROOT_PREFIX iree)

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
# Helper functions
#-------------------------------------------------------------------------------

# Gets the Tracy Python path for environment variables
function(iree_get_tracy_python_path TRACY_PYTHON_PATH)
  if((IREE_ENABLE_RUNTIME_TRACING OR IREE_ENABLE_COMPILER_TRACING) AND
     IREE_TRACING_PROVIDER STREQUAL "tracy" AND
     IREE_TRACY_ENABLE_PYTHON)
    # Use the python directory as the primary path for developers
    set(${TRACY_PYTHON_PATH} "${IREE_PACKAGE_ROOT_DIR}/third_party/tracy/python" PARENT_SCOPE)
  else()
    set(${TRACY_PYTHON_PATH} "" PARENT_SCOPE)
  endif()
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

# Create an installation target for Tracy Python
iree_add_install_target(
  NAME iree-install-tracy-python-experimental
  COMPONENT IREEExperimentalTracyPython
)

# Install Tracy Python examples and scripts
install(
  FILES
    README.md
    demo.py
    build-tracy-python.sh
  DESTINATION ${CMAKE_INSTALL_PREFIX}/share/iree/experimental/tracy_python
  COMPONENT IREEExperimentalTracyPython
)

# Add a target for building the Python wheel
add_custom_target(tracy-python-wheel
  COMMAND ${Python3_EXECUTABLE} setup.py bdist_wheel
  WORKING_DIRECTORY ${IREE_PACKAGE_ROOT_DIR}/third_party/tracy/python
  COMMENT "Building Tracy Python wheel"
  VERBATIM
)

# Install Python bindings
install(
  DIRECTORY ${IREE_PACKAGE_ROOT_DIR}/third_party/tracy/python/
  DESTINATION ${CMAKE_INSTALL_PREFIX}/share/tracy/python
  COMPONENT IREEExperimentalTracyPython
  PATTERN "build" EXCLUDE
  PATTERN "dist" EXCLUDE
  PATTERN "__pycache__" EXCLUDE
  PATTERN "*.pyc" EXCLUDE
)

# Install built wheel if available
install(
  DIRECTORY ${IREE_PACKAGE_ROOT_DIR}/third_party/tracy/python/dist/
  DESTINATION ${CMAKE_INSTALL_PREFIX}/share/tracy/python/dist
  COMPONENT IREEExperimentalTracyPython
  OPTIONAL
)

# Add testing target
add_test(
  NAME tracy_python_bindings_test
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/demo.py
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
set_tests_properties(tracy_python_bindings_test PROPERTIES
  ENVIRONMENT "PYTHONPATH=${IREE_PACKAGE_ROOT_DIR}/third_party/tracy/python:$ENV{PYTHONPATH}"
)