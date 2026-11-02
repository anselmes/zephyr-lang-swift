# SPDX-License-Identifier: GPL-3.0 Copyright (c) 2025 Schubert Anselme
# <schubert@anselm.es>

# Hello: a sample Swift library.
#
# The `Hello` target of the package's Package.swift, which applications import
# with `import Hello`. SwiftPM compiles it as part of each application that
# depends on it; this file only registers it with the Zephyr build. It is only
# added to the build when CONFIG_HELLO=y (see ../CMakeLists.txt), and it is
# found through ZEPHYR_EXTRA_MODULES and the module's zephyr/module.yml.

zephyr_swift_library(MODULE_NAME Hello)
