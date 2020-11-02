#!/bin/bash
# generate a random 45 character secret and encrypt it using ansible vault
tr -dc A-Za-z < /dev/random | head -c 45 | \
    ansible-vault encrypt_string --stdin-name 'my_variable'
