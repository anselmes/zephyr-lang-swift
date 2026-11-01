/* SPDX-License-Identifier: GPL-3.0 */
/* Copyright (c) 2026 Schubert Anselme <schubert@anselm.es> */

/* swiftc emits a module hash that no image needs; drop it instead of letting
 * ld.lld warn that it is an orphan section. */
/DISCARD/ : { *(.swift_modhash) }
