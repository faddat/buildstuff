#!/usr/bin/env bash
packer build -except virtualbox-ovf consul.json > build.log
export IMAGENAME=$(awk 'END {print $NF}' build.log)
sleep 30
gcloud compute --project "ancient-torch-134323" instance-templates 
create "consultest" --machine-type "n1-highcpu-4" --network "default" 
--maintenance-policy "MIGRATE" --scopes 
default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management" 
--tags "http-server","https-server" --image 
"/ancient-torch-134323/$IMAGENAME" --boot-disk-size "20" 
--boot-disk-type "pd-standard" --boot-disk-device-name "consultest"

