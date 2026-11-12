// SPDX-License-Identifier: GPL-3.0
// Copyright (c) 2026 Schubert Anselme <schubert@anselm.es>

import ZephyrSystem

// Atomic library calls for cores without the A extension (Nios V/m is rv32i).
//
// When the target ISA has no atomic instructions, swiftc and LLVM lower the
// atomic operations of the Embedded Swift runtime (reference counting, string
// breadcrumbs) to calls of `__atomic_*_4`, which libgcc and compiler-rt do not
// provide for bare metal. These functions fill the gap for one core by masking
// interrupts around each operation, like Zephyr's own `CONFIG_ATOMIC_OPERATIONS_C`.
// They are not atomic across cores: do not use them with CONFIG_SMP.
//
// Targets with the A extension never reference these symbols (the compiler emits
// the instructions inline), so the functions are only linked in where needed.
//
// The `order` arguments are ignored: masking interrupts on one core is
// sequentially consistent.

/// Runs `body` with interrupts masked.
@inline(__always)
private func withInterruptsMasked<Result>(_ body: () -> Result) -> Result {
  let key = zephyr_irq_lock()
  let result = body()
  zephyr_irq_unlock(key)
  return result
}

/// `__atomic_load_4`: reads the 32-bit value at `pointer`.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c(__atomic_load_4)
public func atomicLoad4(
  _ pointer: UnsafeMutablePointer<UInt32>,
  _ order: Int32,
) -> UInt32 {
  // SAFETY: the compiler passes the address of a live, aligned 32-bit value.
  withInterruptsMasked { unsafe pointer.pointee }
}

/// `__atomic_store_4`: writes `value` to `pointer`.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c(__atomic_store_4)
public func atomicStore4(
  _ pointer: UnsafeMutablePointer<UInt32>,
  _ value: UInt32,
  _ order: Int32,
) {
  // SAFETY: the compiler passes the address of a live, aligned 32-bit value.
  withInterruptsMasked { unsafe pointer.pointee = value }
}

/// `__atomic_exchange_4`: stores `value` and returns the previous value.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c(__atomic_exchange_4)
public func atomicExchange4(
  _ pointer: UnsafeMutablePointer<UInt32>,
  _ value: UInt32,
  _ order: Int32,
) -> UInt32 {
  // SAFETY: the compiler passes the address of a live, aligned 32-bit value.
  withInterruptsMasked {
    let previous = unsafe pointer.pointee
    unsafe pointer.pointee = value
    return previous
  }
}

/// `__atomic_compare_exchange_4`: stores `desired` if the value equals
/// `*expected`; otherwise copies the value to `*expected`. Returns whether the
/// store happened.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c(__atomic_compare_exchange_4)
public func atomicCompareExchange4(
  _ pointer: UnsafeMutablePointer<UInt32>,
  _ expected: UnsafeMutablePointer<UInt32>,
  _ desired: UInt32,
  _ success: Int32,
  _ failure: Int32,
) -> Bool {
  // SAFETY: the compiler passes the addresses of a live, aligned 32-bit value
  // and of the caller's expected-value slot.
  withInterruptsMasked {
    let current = unsafe pointer.pointee
    let wanted = unsafe expected.pointee
    if current == wanted {
      unsafe pointer.pointee = desired
      return true
    }
    unsafe expected.pointee = current
    return false
  }
}

/// `__atomic_fetch_add_4`: adds `value` and returns the previous value.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c(__atomic_fetch_add_4)
public func atomicFetchAdd4(
  _ pointer: UnsafeMutablePointer<UInt32>,
  _ value: UInt32,
  _ order: Int32,
) -> UInt32 {
  // SAFETY: the compiler passes the address of a live, aligned 32-bit value.
  withInterruptsMasked {
    let previous = unsafe pointer.pointee
    unsafe pointer.pointee = previous &+ value
    return previous
  }
}

/// `__atomic_fetch_sub_4`: subtracts `value` and returns the previous value.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c(__atomic_fetch_sub_4)
public func atomicFetchSub4(
  _ pointer: UnsafeMutablePointer<UInt32>,
  _ value: UInt32,
  _ order: Int32,
) -> UInt32 {
  // SAFETY: the compiler passes the address of a live, aligned 32-bit value.
  withInterruptsMasked {
    let previous = unsafe pointer.pointee
    unsafe pointer.pointee = previous &- value
    return previous
  }
}

/// `__atomic_fetch_and_4`: ANDs `value` and returns the previous value.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c(__atomic_fetch_and_4)
public func atomicFetchAnd4(
  _ pointer: UnsafeMutablePointer<UInt32>,
  _ value: UInt32,
  _ order: Int32,
) -> UInt32 {
  // SAFETY: the compiler passes the address of a live, aligned 32-bit value.
  withInterruptsMasked {
    let previous = unsafe pointer.pointee
    unsafe pointer.pointee = previous & value
    return previous
  }
}

/// `__atomic_fetch_or_4`: ORs `value` and returns the previous value.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c(__atomic_fetch_or_4)
public func atomicFetchOr4(
  _ pointer: UnsafeMutablePointer<UInt32>,
  _ value: UInt32,
  _ order: Int32,
) -> UInt32 {
  // SAFETY: the compiler passes the address of a live, aligned 32-bit value.
  withInterruptsMasked {
    let previous = unsafe pointer.pointee
    unsafe pointer.pointee = previous | value
    return previous
  }
}

/// `__atomic_fetch_xor_4`: XORs `value` and returns the previous value.
// swift-format-ignore: AlwaysUseLowerCamelCase
@c(__atomic_fetch_xor_4)
public func atomicFetchXor4(
  _ pointer: UnsafeMutablePointer<UInt32>,
  _ value: UInt32,
  _ order: Int32,
) -> UInt32 {
  // SAFETY: the compiler passes the address of a live, aligned 32-bit value.
  withInterruptsMasked {
    let previous = unsafe pointer.pointee
    unsafe pointer.pointee = previous ^ value
    return previous
  }
}
