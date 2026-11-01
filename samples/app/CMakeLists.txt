# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

# Swift application sample.
#
# Builds the Swift code in src/ into a Zephyr application. The board and
# toolchain come from environment variables: copy .env.example to .env and
# `source .env` before running west.
#
# Environment variables read here (all set by .env.example):
#   ZEPHYR_BOARD              Board to build for unless `west build -b` gives
#                             one, for example qemu_riscv32/qemu_virt_riscv32/smp
#   ZEPHYR_TOOLCHAIN_VARIANT  zephyr/llvm for the Zephyr SDK's LLVM toolchain
#   ZEPHYR_BASE               Zephyr tree, set by zephyr-env.sh
# Optional: ZEPHYR_BOARD_OVERLAY (devicetree overlay), CROSS_COMPILE and
# SYSROOT_DIR (a custom cross toolchain and its C headers).

cmake_minimum_required(VERSION 3.29)

# Command-line -D arguments (`west build -b <board>`, `-- -DDTC_OVERLAY_FILE=...`)
# win; otherwise the environment supplies a default.
if(NOT DEFINED BOARD AND DEFINED ENV{ZEPHYR_BOARD})
  set(BOARD $ENV{ZEPHYR_BOARD})
endif()
if(NOT DEFINED CROSS_COMPILE AND DEFINED ENV{CROSS_COMPILE})
  set(CROSS_COMPILE $ENV{CROSS_COMPILE})
endif()
if(NOT DEFINED DTC_OVERLAY_FILE AND DEFINED ENV{ZEPHYR_BOARD_OVERLAY})
  set(DTC_OVERLAY_FILE $ENV{ZEPHYR_BOARD_OVERLAY})
endif()
if(NOT DEFINED SYSROOT_DIR AND DEFINED ENV{SYSROOT_DIR})
  set(SYSROOT_DIR $ENV{SYSROOT_DIR})
endif()
if(NOT DEFINED ZEPHYR_TOOLCHAIN_VARIANT AND DEFINED ENV{ZEPHYR_TOOLCHAIN_VARIANT})
  set(ZEPHYR_TOOLCHAIN_VARIANT $ENV{ZEPHYR_TOOLCHAIN_VARIANT})
endif()

# Must come before project().
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(app)

# Compile the Swift sources in src/ into the `app` target (see the root
# CMakeLists.txt of this module).
zephyr_swift_application()
