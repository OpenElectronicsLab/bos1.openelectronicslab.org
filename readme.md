# bos1.openelectronicslab.org

This is a repository for configuration files for the servers in the
bos1.openelectronicslab.org subdomain.

## Directory structure

  - `host-vars`: Ansible variable definitions for specific machines.
  - `initial-boot`: files for installing a basic OS on first boot
      - `morchella`: usb setup drive for the firewall server
  - `roles`: Ansible roles
  - `secrets`: files involved in secrets management
      - `ssh-keys`: ssh public keys for users and administrators
      - `gpg-keys`: gpg public keys for users and administrators
      - `vault-keys`: master keys for ansible-vault secrets. Each vault has
        a subdirectory containing a gpg-encrypted key for each user.

## Setup notes

### Secrets management

All shared secrets are stored in the git repository along with the other setup
files.  The secrets are encrypted as individual variables using
`ansible-vault`.  The vault keys are then encrypted using the GPG public keys
of the Open Electronics Labs administrators and stored in the
`secrets/vault-keys/'VAULT NAME'` directory.

#### GPG setup

Each user will need to generate a GPG key as follows (if they don't already
have one):

    gpg --full-gen-key

Choose RSA/RSA keys with a 4096 bit key length, give it a good password, and
choose an email address to associate the key with.

You will then need to export your public key to a file:

    gpg -a --output $USER.asc --export [your email address]

If you have multiple keys with the same email address the fingerprint can be
used instead.

Place this file in the `secrets/gpg-keys` directory:

    cp -iv $USER.asc secrets/gpg-keys
    git add secrets/gpg-keys/$USER.asc
    # git commit && git push

After pushing the key, have someone with access to the repository re-encrypt
each of the vault keys using the new set of GPG keys, e.g.

    secrets/re-encrypt-vault-key.sh vault0

The easiest way to share your gpg keys with another machine is just by copying
the contents of the `~/.gnupg` directory:

    scp -r ~/.gnupg [remote host]:

You can also copy individual keys using the `--export-secret-key` and
`--import` flags for GPG - see the documentation for more details.

#### Creating new secrets

A new password (e.g. for an SQL admin account) can be generated with the
command

    secrets/generate-ansible-secret.sh

This will print out an Ansible variable declaration with an encrypted value
that can be cut and pasted into Ansible code.  The value itself will be a
45 character (upper and lower case letter) password, containing about 256
bits of entropy.  Note that adding numbers, underscores, and dashes would
only add about 0.3 bits of entropy per character, and thus the resulting
passwords would only be about 2 characters shorter and would likely be more
cumbersome and error-prone to type.

If random passwords of another form are needed, (e.g. of a
different length) they can often easily be generated just by modifying the code
that `generate-ansible-secret.sh` uses:

    tr -dc A-Za-z < /dev/random | head -c 45 | \
        ansible-vault encrypt_string --stdin-name 'my_variable'

A similar approach can also be used for encrypting other secrets, e.g. TLS
certificates:

    cat my-ssl.key | \
        ansible-vault encrypt_string --stdin-name 'my_ssl_key_variable'

#### Secret rotation strategy

Automated rotation of secrets would be ideal, but requires service-specific
code for each type of secret (e.g. LUKS passwords, SQL admin keys, etc) and
thus probably too labor intensive for the first version.  Instead, keys will
have to be manually rotated.

To rotate the secrets, first a new vault, e.g. `vault1`, should be created with
a new encryption key:

    secrets/generate-vault-key.sh vault1

The `ansible.cfg` file should then be changed to include the new vault and use
it as the default for encryption keys.  For example, if the `ansible.cfg` file
previously contained the two lines

    vault_identity_list=vault0@secrets/vault-keys/vault0/decrypt.sh
    vault_encrypt_identity=vault0

these could be changed to

    vault_identity_list=vault0@secrets/vault-keys/vault0/decrypt.sh,vault1@secrets/vault-keys/vault1/decrypt.sh
    vault_encrypt_identity=vault1

At this point the code will be able to use a mixture of secrets encrypted
with the old and new vault keys, and new secrets will use the new vault
keys by default.  One can then gradually replace all of the secrets
encrypted with the old vault key with new secrets encrypted with the new
vault key.  It should be easy to identify all of the old secrets by using
tools like `git grep` and searching for the old vault name (`vault0` in
this example), but replacing them will probably require additional steps
(e.g. replacing LUKS keys on an encrypted partition or updating passwords
in config files and SQL databases).

### Bootstrapping the servers

First, you'll need to create a bootable USB drive for morchella0:

    cd initial-boot/morchella
    make
    sudo dd if=morchella0.iso of=[usb device] bs=16M

Next, you'll need to boot the firewall from this drive, which will install a
minimal Debian setup with an encrypted root partition and Dropbear client for
remotely unlocking the drive during boot.
