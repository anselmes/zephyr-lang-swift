#!/bin/bash

# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2025 Schubert Anselme <schubert@anselm.es>

set -exo pipefail

PARENT_DIR="$(dirname "${0}")"
REAL_PARENT_DIR="$(realpath "${PARENT_DIR}")"
DIR="$(dirname "${REAL_PARENT_DIR}")"

# configure environment
if [[ ! -d "/home/ubuntu/.oh-my-zsh" ]]; then
	curl -fsSLo /tmp/ohmyzsh-install.sh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
	bash /tmp/ohmyzsh-install.sh --unattended || true
	rm -f /tmp/ohmyzsh-install.sh
fi

sudo ln -sf "${DIR}/scripts/aliases.sh" /etc/profile.d/aliases.sh
sudo ln -sf "${DIR}/scripts/environment.sh" /etc/profile.d/environment.sh
