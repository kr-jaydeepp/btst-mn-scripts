# dxg-mn-scripts
Scripts that facilitate an easy setup of dexergi masternodes  

## Prerequisite
* 1000 DXR
* A main Linux computer(Your everyday computer)
* Masternode Server(The computer that will be on 24/7)
* A unique Public IP address for EACH masternode

## controller-setup.sh
Following script runs on controlling wallet node and it helps in automating the process of creating and activating masternode.  

### running the script
```bash
./controller-setup.sh [arguments]
```

controller-setup.sh script can take input of masternode ip address as arguement in one of the following ways.

1. Passing each masternode ip as separate arguements.   
Example: 
```bash
controller-setup.sh ip1 ip2 ip3 
```

2. Passing a filename which contains list of masternode ip address(one ip address per line)   
Example: 
```bash
controller-setup.sh <filename>
```

**Note**
If wallet is encrypted then declare an environment variable named as DXG_WALLET_PASSPHRASE="abcd" where "abcd" is your passphrase.  

Example of such command is here.
```bash
unset HISTFILE
DXG_WALLET_PASSPHRASE="abcd" ./controller-setup.sh [arguments]
```

In case your remote system's username is not root then change ssh_username variable in the script as per actual system username.

After the script successfully executes following files are added to users home directory     
* .dxg-masternode-list which keeps a record of all masternode ip address and respective public keys.
* .dxg-pending-activation-list which keeps a record of all masternode ip address which could not be activated post 15 minite of running of script due to hotnode activation errors. These nodes should be activated by user manually. 
