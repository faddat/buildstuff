#!/bin/bash
#UPDATING UBUNTU AND INSTALLING DEPENDENCIES.  Note that moving the loaders for consul-onboot.service and the consul-onboot script towards the end of this file will result in its abject failure.  I cannot for the life of me figure out why this is.  

sudo -s
cd /root
sudo wget -O /etc/systemd/system/consul-onboot.service https://gist.githubusercontent.com/faddat/d143c53cbebba481f9159623b4472d1a/raw/fab65c4166428055577a56a9d96d23271bb6b08b/consul-onboot.service
sudo wget -O /usr/bin/consul-onboot https://gist.githubusercontent.com/faddat/d143c53cbebba481f9159623b4472d1a/raw/fab65c4166428055577a56a9d96d23271bb6b08b/consul-onboot
sudo apt install -y unzip moreutils build-essential 
wget get.docker.io
sh index.html
wget https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip
unzip consul_0.6.4_linux_amd64.zip
sudo mv consul /usr/bin/consul
sudo gsutil cp gs://nomad/nomad /usr/bin/nomad
sudo chmod a+x /usr/bin/nomad
sudo mkdir /data

#DOWNLOADING NETWORK COMPONENTS
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo wget -O /usr/local/bin/scope https://git.io/scope

#MARKING NETWORK COMPONENTS RUNNABLE
sudo chmod a+x /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/scope

sudo chmod a+x /usr/bin/consul-onboot
sudo systemctl daemon-reload
sudo systemctl enable consul-onboot
