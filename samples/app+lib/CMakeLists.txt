# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

# Not a build entry point. Zephyr does not run this file: zephyr/module.yml sets
# `cmake: lib`, so lib/CMakeLists.txt is the module's actual entry point. It
# cannot be configured as a standalone CMake project either, because lib/ calls
# Zephyr's add_subdirectory_ifdef, which only exists once Zephyr is loaded. Build
# the application in app/ instead.
add_subdirectory(lib)
