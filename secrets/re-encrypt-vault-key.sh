#!/bin/bash
# Re-encrypts the given vault key using the keys in the secrets/gpg-keys
# directory.  (This should be used when a gpg key is added or changed)
SECRETSDIR=`dirname $0`
VAULTNAME=$1
VAULTDIR=$SECRETSDIR/vault-keys/$VAULTNAME

# make sure a vault name was specified on the command line
if [[ $# -ne 1 ]]; then
    echo Usage:
    echo "   $0 'VAULT NAME'"
    exit 1
fi

# make sure the vault key already exists
if [[ ! -d "$VAULTDIR" ]]; then
    echo Vault "$VAULTNAME" not found - use generate-vault-key.sh to create \
        a new vault.
    exit 1
fi

# decrypt the current password
PASSWORD=`$VAULTDIR/decrypt.sh`

# remove any existing keys
rm -rf $VAULTDIR/*.gpg

# generate a vault key for each key in the vault keys
for keyfile in $SECRETSDIR/gpg-keys/*.asc; do
    echo $keyfile
    echo $PASSWORD | gpg --encrypt --recipient-file $keyfile \
        -o $VAULTDIR/`basename ${keyfile%.*}`.gpg
done
