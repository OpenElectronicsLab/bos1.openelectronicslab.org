#!/bin/bash
# Decrypt the given vault key using the user's gpg key.
SECRETSDIR=`dirname $0`
VAULTNAME=$1
VAULTDIR=$SECRETSDIR/vault-keys/$VAULTNAME

# make sure a vault name was given on the command line
if [[ $# -ne 1 ]]; then
    echo Usage:
    echo "   $0 'VAULT NAME'"
    exit 1
fi

# make sure the given vault exists
if [[ ! -d "$VAULTDIR" ]]; then
    echo No vault found with the name \"$VAULTNAME\"
    exit 1
fi

# if a vault user was not specified in the environment, default to the
# current username
if [[ -z "$VAULTUSER" ]]; then
    VAULTUSER=$USER
fi

# decrypt the key and write it to STDOUT
gpg --batch --quiet --use-agent --decrypt $VAULTDIR/$VAULTUSER.gpg
