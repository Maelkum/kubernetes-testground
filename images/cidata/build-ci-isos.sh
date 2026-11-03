#!/bin/bash
# Blow up on first error
set -e

for dirname in jumpbox node0 node1 server; do
    xorriso -as mkisofs -o "${dirname}-cidata.iso" -V cidata -J -r "$dirname"
done
