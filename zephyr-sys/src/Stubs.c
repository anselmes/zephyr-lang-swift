// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

/**
 * @file Stubs.c
 * @brief Stub implementations for missing C library functions in Zephyr SDK.
 *
 * This file provides stub implementations for functions required by Embedded Swift
 * that are not available in the Zephyr SDK's C libraries. These stubs enable
 * Swift code to compile and run correctly on Zephyr RTOS by filling gaps in
 * the C runtime environment expected by Swift.
 *
 * Current implementations:
 * - posix_memalign: Memory allocation with alignment requirements
 * - getentropy: Random bytes generation (non-cryptographic implementation)
 */

#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * @brief Allocates memory with the specified alignment.
 *
 * This is a forward declaration for `aligned_alloc`, which allocates `size` bytes
 * of uninitialized storage whose alignment is specified by `alignment`.
 * This function is required for the stub implementation of `posix_memalign`.
 *
 * @param alignment The alignment value, which must be a power of two and a multiple of `sizeof(void *)`.
 * @param size      The size of the memory block to allocate.
 * @return          A pointer to the allocated memory, or `NULL` if the allocation fails.
 *
 * @note The actual implementation is provided by the Zephyr C library.
 */
void *aligned_alloc(size_t alignment, size_t size);

/**
 * @brief Generates a pseudo-random integer.
 *
 * This is a forward declaration for `rand`, which generates a pseudo-random integer.
 * It is used as a fallback for generating random bytes in the `getentropy` stub.
 *
 * @return A pseudo-random integer.
 */
int rand(void);

/**
 * @brief Allocates memory with the specified alignment using the `posix_memalign` interface.
 *
 * This function implements `posix_memalign` by forwarding the allocation request to `aligned_alloc`.
 * It is provided as a stub for environments where `posix_memalign` is not available, such as the Zephyr SDK.
 * Swift's memory allocator may call this function when it needs to allocate aligned memory blocks.
 *
 * @param[out] memptr    Pointer to the allocated memory block (output parameter).
 * @param[in]  alignment The alignment value, which must be a power of two and a multiple of `sizeof(void *)`.
 * @param[in]  size      The size of the memory block to allocate.
 *
 * @return 0 on successful allocation, or an error code (`errno`) on failure.
 */
int posix_memalign(void **memptr, const size_t alignment, const size_t size)
{
  // Attempt to allocate memory with the specified alignment and size
  void *p = aligned_alloc(alignment, size);

  if (p)
  {
    // Allocation succeeded, set the output pointer and return success
    *memptr = p;
    return 0;
  }

  // Allocation failed, return the error code stored in errno
  return errno;
}

/**
 * @brief Stub implementation of `getentropy`.
 *
 * This function fills a buffer with random bytes. Since Zephyr may not provide
 * a native `getentropy`, this stub uses `rand()` as a fallback.
 *
 * @warning This implementation is NOT cryptographically secure and should not be
 *          used for security-sensitive operations. It's provided only to satisfy
 *          Swift runtime dependencies in non-security-critical applications.
 *
 * @param buffer Pointer to the buffer to fill with random bytes.
 * @param length Number of bytes to generate (limited to 256 bytes per POSIX spec).
 *
 * @return 0 on success, -1 on failure with `errno` set to indicate the error.
 */
int getentropy(void *buffer, size_t length)
{
  // Validate input parameters:
  // - buffer must not be NULL
  // - length must not exceed 256 (POSIX specification limit)
  if (!buffer || length > 256) {
    errno = EINVAL;  // Set invalid argument error code
    return -1;
  }

  // Fill the buffer with pseudo-random bytes
  unsigned char *buf = (unsigned char *)buffer;
  for (size_t i = 0; i < length; i++) {
    // Generate a random byte (0-255) using rand()
    // Note: rand() is not suitable for cryptographic purposes
    buf[i] = rand() % 256;
  }

  return 0;  // Success
}
