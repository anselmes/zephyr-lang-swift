# ==== Conditional Module Compilation ====
# Only build this Swift module when it's explicitly enabled through Kconfig.
# CONFIG_HELLO is defined in this module's Kconfig file and can be enabled in
# the application's prj.conf with: CONFIG_HELLO=y
add_subdirectory_ifdef(CONFIG_HELLO hello)
