# bos1.openelectronicslab.org

This is a repository for configuration files for the servers in the
bos1.openelectronicslab.org subdomain.

## Directory structure

  - `ssh-keys`: ssh public keys for users and administrators
  - `gpg-keys`: gpg public keys for users and administrators
  - `initial-boot`: files for installing a basic OS on first boot
      - `morchella`: usb setup drive for the firewall server

## Setup notes

### GPG setup

Each user will need to generate a GPG key as follows (if they don't already
have one):

    gpg --full-gen-key

Choose RSA/RSA keys with a 4096 bit key length, give it a good password, and
choose an email address to associate the key with.

You will then need to export your public key to a file:

    gpg -a --output $USER.asc --export [your email address]

Place this file in the `gpg-keys` directory.

The easiest way to share the keys with another machine is just by copying the
contents of the `~/.gnupg` directory:

    scp -r ~/.gnupg [remote host]:

You can also copy individual keys using the `--export-secret-key` and
`--import` flags for GPG - see the documentation for more details.


### Bootstrapping the servers

First, you'll need to create a bootable USB drive for morchella0:

    cd initial-boot/morchella
    make
    sudo dd if=morchella0.iso of=[usb device] bs=16M

Next, you'll need to boot the firewall from this drive, which will install a
minimal Debian setup with an encrypted root partition and Dropbear client for
remotely unlocking the drive during boot.
