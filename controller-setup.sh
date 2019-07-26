#!/bin/bash

set -eo pipefail

data_dir="$HOME/.dexergi"
ssh_username="root"
vps_setup_url="https://github.com/knackroot-technolabs-llp/dxg-mn-scripts/raw/master/vps-setup.sh"
collateral_amount=1000
ip_pubkey_db="$HOME/.dxg-masternode-list"
mn_wait_threshold=3000

wallet_passphrase="" ## Set this if your wallet is encrypted

ips=()

main() {
    # get the list of IP addresses
    if [[ -f "$1" ]]; then
        # read from the $1
        while read -r line; do
            ips+=("$line")
        done < "$1"
    else
        # assume all the arguments are the list of ips
        while [[ "$1" ]]; do
            ips+=("$1")
        done
    fi

    index=0
    # fetch the last masternode's index
    line=$(tail -n1 $data_dir/masternode.conf | cut -d ' ' -f 1 || true)
    re='^mn[0-9]+$'
    if [[ "$line" =~ $re ]]; then
        index=$(echo $line | tail -c +3)
    fi

    for ip in "${ips[@]}"; do
        ((index++)) || true
        mn_name="mn$index"
        ssh -o StrictHostKeyChecking=no "${ssh_username}@${ip}" 'curl -fL '"$vps_setup_url"' | bash'
        if [[ ! -z "$wallet_passphrase" ]]; then
            dexergi-cli walletpassphrase "$wallet_passphrase" 0 false || true
        fi

        mn_priv_key=$(dexergi-cli createmasternodekey)
        pub_key=$(dexergi-cli getaccountaddress "$mn_name")
        mn_tx_hash=$(dexergi-cli sendtoaddress "$pub_key" $collateral_amount)

        # stop till the transaction has been included in a block
        echo "Waiting for the collateral transaction to be included in a block..."
        until dexergi-cli gettransaction "$mn_tx_hash" | grep -qs '"blockhash"'; do
            echo "Transaction not included in the blockchai."
            for (( i=15; i > 0; i-- )); do
                    echo -en "\rRechecking in $i seconds"
                    sleep 1
            done
            echo
        done

        # get the vout index (default to 1, check if it's 0)
        vout_index=1
        if dexergi-cli gettxout "$mn_tx_hash" 0 | grep -qs '"value": '"${collateral_amount}.0"; then
            vout_index=0
        fi

        # update the masternode.conf file and restart the daemon
        dexergi-cli stop
        echo "$mn_name ${ip}:5536 $mn_priv_key $mn_tx_hash $vout_index" >> $data_dir/masternode.conf
        dexergid -daemon
        echo "Waiting for the daemon to start up."
        for (( i=10; i > 0; i-- )); do
                echo -en "\rResuming in $i seconds"
                sleep 1
        done
        if [[ ! -z "$wallet_passphrase" ]]; then
            dexergi-cli walletpassphrase "$wallet_passphrase" 0 false || true
        fi


        # update dexergi.conf on the vps
        ssh -o StrictHostKeyChecking=no "${ssh_username}@${ip}" '
            dexergi-cli stop
            echo -e "masternode=1\nmasternodeaddr='"${ip}"':5536\nmasternodeprivkey='"${mn_priv_key}"'" >> .dexergi/dexergi.conf
            dexergid -daemon >/dev/null 2>&1
            echo "Waiting for the remote daemon to start up."
            for (( i=10; i > 0; i-- )); do
                    echo -en "\rResuming in $i seconds"
                    sleep 1
            done
        '
        # start masternode from the controller and from the vps
        dexergi-cli startmasternode alias false $mn_name
        ssh -o StrictHostKeyChecking=no "${ssh_username}@${ip}" '
            i=0
            until dexergi-cli startmasternode local false | grep -qs "Masternode successfully started"; do
                if [[ "$i" == '"$mn_wait_threshold"' ]]; then
                    echo "There seems to be some issue. Masternode failed to activate after '"$mn_wait_threshold"' seconds"
                    exit 100
                fi
                sleep 15
                ((i += 15))
            done
        '

        # write IP address, public key to the file
        echo "${ip},${pub_key}" >> "$ip_pubkey_db"
    done
}

main "$@"