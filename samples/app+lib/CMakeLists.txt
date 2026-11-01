# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

# Entry point of the app+lib module (zephyr/module.yml, `cmake: lib`): the
# library lives in lib/. The application that uses it is in app/.
add_subdirectory(lib)
