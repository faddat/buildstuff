#!/usr/bin/env bash
packer build -except virtualbox-ovf consul.json
packer build -except qemu leaf.sh
packer build -except virtualbox-ovf trunk.json
