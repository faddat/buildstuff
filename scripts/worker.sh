#!/bin/bash
#UPDATING UBUNTU AND INSTALLING DEPENDENCIES.  Note that moving the loaders for consul-onboot.service and the consul-onboot script towards the end of this file will result in its abject failure.  I cannot for the life of me figure out why this is.  

sudo -s
sudo apt update
sudo apt upgrade -y
cd /root
sudo cp /tmp/workerfiles/consul-onboot /usr/bin/consul-onboot
sudo cp /tmp/workerfiles/consul-onboot.service /etc/systemd/system/consul-onboot.service
sudo cp /tmp/workerfiles/nomad-onboot /usr/bin/nomad-onboot
sudo cp /tmp/workerfiles/nomad.service /etc/systemd/system/nomad.service
sudo apt install -y unzip moreutils build-essential
wget -qO- https://get.docker.com/ | sh
wget https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip
unzip consul_0.6.4_linux_amd64.zip
sudo mv consul /usr/bin/consul
sudo gsutil cp gs://nomad/nomad /usr/bin/nomad
sudo chmod a+x /usr/bin/nomad
sudo chmod a+x /usr/bin/nomad-onboot
sudo chmod a+x /usr/bin/consul-onboot
sudo mkdir /data

#DOWNLOADING NETWORK COMPONENTS
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo wget -O /usr/local/bin/scope https://git.io/scope
sudo chmod a+x /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/scope

#Setting systemd Units as active
sudo systemctl daemon-reload
sudo systemctl enable consul-onboot
sudo systemctl enable nomad
