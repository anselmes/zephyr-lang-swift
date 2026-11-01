# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

# Convenience wrapper that adds lib/ when this directory is built as a regular
# CMake project. Zephyr does not run it: zephyr/module.yml sets `cmake: lib`, so
# lib/CMakeLists.txt is the module's actual entry point. The application that
# uses the library is in app/.
add_subdirectory(lib)
