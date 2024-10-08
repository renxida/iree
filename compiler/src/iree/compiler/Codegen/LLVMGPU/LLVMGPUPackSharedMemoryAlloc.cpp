// Copyright 2023 The IREE Authors
//
// Licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "iree/compiler/Codegen/LLVMGPU/Passes.h"
#include "iree/compiler/Codegen/LLVMGPU/Utils/LLVMGPUUtils.h"
#include "mlir/Dialect/NVGPU/IR/NVGPUDialect.h"

namespace mlir::iree_compiler {

#define GEN_PASS_DEF_LLVMGPUPACKSHAREDMEMORYALLOCPASS
#include "iree/compiler/Codegen/LLVMGPU/Passes.h.inc"

namespace {

struct LLVMGPUPackSharedMemoryAllocPass final
    : impl::LLVMGPUPackSharedMemoryAllocPassBase<
          LLVMGPUPackSharedMemoryAllocPass> {
public:
  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<nvgpu::NVGPUDialect>();
  }

  void runOnOperation() override { packSharedMemoryAlloc(getOperation()); }
};
} // namespace

std::unique_ptr<InterfacePass<mlir::FunctionOpInterface>>
createLLVMGPUPackSharedMemoryAlloc() {
  return std::make_unique<LLVMGPUPackSharedMemoryAllocPass>();
}

} // namespace mlir::iree_compiler
