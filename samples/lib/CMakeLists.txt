# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

# Add the Hello library only when CONFIG_HELLO is enabled, for example with
# CONFIG_HELLO=y in the application's prj.conf. CONFIG_HELLO is defined in
# hello/Kconfig.
add_subdirectory_ifdef(CONFIG_HELLO hello)
