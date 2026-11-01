# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

# Swift application sample that uses a Swift library.
#
# Same as samples/app, plus the Hello library from the parent directory
# (samples/app+lib/lib), which prj.conf enables with CONFIG_HELLO=y. The
# application is the Swift code in src/, which is shared with the parent
# directory through the src symlink.
#
# Environment variables read here (all set by .env.example):
#   ZEPHYR_BOARD              Board to build for unless `west build -b` gives
#                             one, for example qemu_riscv32/qemu_virt_riscv32/smp
#   ZEPHYR_TOOLCHAIN_VARIANT  zephyr/llvm for the Zephyr SDK's LLVM toolchain
#   ZEPHYR_BASE               Zephyr tree, set by zephyr-env.sh
# Optional: ZEPHYR_BOARD_OVERLAY (devicetree overlay), CROSS_COMPILE and
# SYSROOT_DIR (a custom cross toolchain and its C headers).

cmake_minimum_required(VERSION 3.29)

# `west build -b <board>` wins; otherwise use ZEPHYR_BOARD.
if(NOT DEFINED BOARD AND DEFINED ENV{ZEPHYR_BOARD})
  set(BOARD $ENV{ZEPHYR_BOARD})
endif()
set(CROSS_COMPILE $ENV{CROSS_COMPILE})
set(DTC_OVERLAY_FILE $ENV{ZEPHYR_BOARD_OVERLAY})
set(SYSROOT_DIR $ENV{SYSROOT_DIR})
set(ZEPHYR_TOOLCHAIN_VARIANT $ENV{ZEPHYR_TOOLCHAIN_VARIANT})

# The parent directory is a Zephyr module (zephyr/module.yml) that provides the
# Hello library. Listing it here lets the build find the library and its Kconfig.
set(ZEPHYR_EXTRA_MODULES ${CMAKE_CURRENT_LIST_DIR}/..)

# Must come before project().
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(app)

# Compile the Swift sources in src/ into the `app` target (see the root
# CMakeLists.txt of this module).
zephyr_swift_application()
