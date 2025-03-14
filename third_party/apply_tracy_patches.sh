#!/bin/bash
set -e

# Apply patches to Tracy submodule
echo "Applying patches to Tracy submodule..."
cd $(dirname "$0")/tracy
git apply --ignore-whitespace ../patches/tracy/fix-scoped-zone.patch
echo "Tracy patches applied successfully."