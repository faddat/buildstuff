#!/usr/bin/env bash


packer-io build klouds-image-server.json > packerlog
gcloud compute --project "resonant-truth-120806" instances create "instance-1" --zone "asia-east1-c" --machine-type "n1-standard-1" --network "default" --maintenance-policy "MIGRATE" --scopes default="https://www.googleapis.com/auth/cloud-platform" --tags "http-server","https-server" --disk "name=dockerstorage" "device-name=dockerstorage" "mode=rw" "boot=no" --image "projects/resonant-truth-120806/global/images/server-1457470104" --boot-disk-size "25" --boot-disk-type "pd-ssd" --boot-disk-device-name "instance-1"