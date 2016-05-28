#!/usr/bin/env bash
packer build consul.json
packer build leaf.sh
packer build trunk.json
