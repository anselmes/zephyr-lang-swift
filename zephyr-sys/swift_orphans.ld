/* SPDX-License-Identifier: GPL-3.0 */
/* Copyright (c) 2026 Schubert Anselme <schubert@anselm.es> */

/* swiftc emits a module hash and autolink entries that no image needs; drop
 * them instead of letting ld.lld warn that they are orphan sections. */
/DISCARD/ : { *(.swift_modhash) *(.swift1_autolink_entries) }
