#!/bin/bash
# generate a random 45 character secret and encrypt it using ansible vault
# 45 characters of A-Za-z is 256 bits of entropy
# math.log(52**45)/math.log(2)
# 256.51978731634915
cat /dev/random \
    | tr --delete --complement 'a-zA-Z' \
    | head --bytes=45 \
    | ansible-vault encrypt_string --stdin-name 'my_variable'
