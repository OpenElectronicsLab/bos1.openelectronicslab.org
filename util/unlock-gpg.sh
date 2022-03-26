#!/bin/bash
{ gpg --use-agent --decrypt secrets/vault-keys/vault0/${USER}.gpg; } > /dev/null
