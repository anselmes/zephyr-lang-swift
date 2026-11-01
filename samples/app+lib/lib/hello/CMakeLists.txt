# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

# Hello: a sample Swift library.
#
# Compiles the Swift sources in this directory into the `Hello` module, a static
# library that applications import with `import Hello`. It is only added to the
# build when CONFIG_HELLO=y (see ../CMakeLists.txt), and it is found through
# ZEPHYR_EXTRA_MODULES and the module's zephyr/module.yml.

zephyr_swift_library(MODULE_NAME Hello)
