#!/bin/bash

#DOWNLOADING NETWORK COMPONENTS
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo wget -O /usr/local/bin/scope https://git.io/scope
sudo chmod a+x /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/scope

#UPDATING UBUNTU AND INSTALLING DEPENDENCIES.  Note that moving the loaders for consul-onboot.service and the consul-onboot script towards the end of this file will result in its abject failure.  I cannot for the life of me figure out why this is.
sudo -s
sudo apt update
sudo apt upgrade -y
sudo apt install -y unzip moreutils build-essential
wget -qO- https://test.docker.com/ | sh
cd /root
sudo cp /tmp/serverfiles/scope.service /etc/systemd/system/scope.service
sudo cp /tmp/serverfiles/weave.service /etc/systemd/system/weave.service
sudo cp /tmp/serverfiles/consul.service /etc/systemd/system/consul.service
sudo cp /tmp/serverfiles/nomad.service /etc/systemd/system/nomad.service
wget https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip
wget https://releases.hashicorp.com/nomad/0.4.0/nomad_0.4.0_linux_amd64.zip
unzip nomad_0.4.0_linux_amd64.zip
unzip consul_0.6.4_linux_amd64.zip
sudo mv consul /usr/bin/consul
sudo mv nomad /usr/bin/nomad
sudo chmod a+x /usr/bin/nomad
sudo chmod a+x /usr/bin/consul
sudo mkdir /data


#Setting systemd Units as active
sudo systemctl daemon-reload
sudo systemctl enable consul
sudo systemctl enable nomad
sudo systemctl enable weave
sudo systemctl enable scope
