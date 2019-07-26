#!/bin/bash

###################################################################################
## This script should be run on the VPS that will actually run as the masternode ##
###################################################################################

set -eo pipefail

dxg_bin_url="https://github.com/knackroot-technolabs-llp/dexergi/releases/download/v1.0.2/dexergi-1.0.2-x86_64-linux-gnu.tar.gz"
install_dir="/usr/local"

main() {
    # check if binaries already exist
    if  ! [[ -x $(command -v dexergi-cli) && -x $(command -v dexergid) ]]; then
        # at least one of the binaries is not available, so we'll install all of them
        if [[ -z "$dxg_bin_url" ]]; then
            echo "URL to dexergi binaries is empty!" >&2
            return 1
        fi

        # fetch the and extract the dexergi binaries
        curl -fL "$dxg_bin_url" | tar -xzC "$install_dir" --strip-components=1
    fi

    dexergid -daemon >/dev/null 2>&1
}

main "$@"
