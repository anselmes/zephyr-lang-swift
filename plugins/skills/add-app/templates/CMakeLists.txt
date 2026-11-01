# SPDX-License-Identifier: __license__
# Copyright (c) __year__ __author__

cmake_minimum_required(VERSION 3.29)

set(BOARD $ENV{ZEPHYR_BOARD})
set(CROSS_COMPILE $ENV{CROSS_COMPILE})
set(DTC_OVERLAY_FILE $ENV{ZEPHYR_BOARD_OVERLAY})
set(SYSROOT_DIR $ENV{SYSROOT_DIR})
set(ZEPHYR_TOOLCHAIN_VARIANT $ENV{ZEPHYR_TOOLCHAIN_VARIANT})
__extra-modules__
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(__project__)

zephyr_swift_application()
