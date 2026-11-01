# SPDX-License-Identifier: __license__
# Copyright (c) __year__ __author__

cmake_minimum_required(VERSION 3.29)

# Command-line -D arguments win; otherwise the environment supplies a default.
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
__extra-modules__
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(__project__)

zephyr_swift_application()
