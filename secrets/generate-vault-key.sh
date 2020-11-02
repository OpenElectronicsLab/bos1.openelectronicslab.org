#!/bin/bash
# Generates a new vault key and encrypts it with each of the gpg keys in
# secrets/gpg-keys.
PASSWORD=`tr -dc A-Za-z < /dev/random | head -c 45`
SECRETSDIR=`dirname $0`
VAULTNAME=$1
VAULTDIR=$SECRETSDIR/vault-keys/$VAULTNAME

# make sure a vault name was specified on the command line
if [[ $# -ne 1 ]]; then
    echo Usage:
    echo "   $0 'VAULT NAME'"
    exit 1
fi

# make sure the vault keys doesn't already exist
if [[ -d "$VAULTDIR" ]]; then
    echo A password already exists with that vault name - please choose \
        a different name.
    exit 1
fi

# create the directory for the vault keys
mkdir $VAULTDIR

# create an argument-free decryption script for ansible to use
cat > $VAULTDIR/decrypt.sh <<EOF
#!/bin/bash
\`dirname \$0\`/../../decrypt-vault-key.sh $VAULTNAME
EOF
chmod a+x $VAULTDIR/decrypt.sh

# generate a vault key for each key in the vault keys
for keyfile in $SECRETSDIR/gpg-keys/*.asc; do
    echo $PASSWORD | gpg --encrypt --recipient-file $keyfile \
        -o $VAULTDIR/`basename ${keyfile%.*}`.gpg
done
