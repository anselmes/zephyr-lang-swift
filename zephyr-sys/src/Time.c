// SPDX-Licence-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

#include <zephyr/kernel.h>

/**
 * @brief Implementation of k_msleep as a real linkable symbol
 *
 * Since k_msleep is defined as static inline in kernel.h,
 * it's not available as a linkable symbol for Swift's @_silgen_name.
 * This function provides the same functionality as a real symbol.
 */
int32_t msleep(int32_t ms) { return k_msleep(ms); }
