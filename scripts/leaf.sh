#!/bin/sh
#UPDATING DEBIAN
sudo -s
mkdir /storage
mount 192.168.194.222:/storage /storage
wget get.docker.io
sh index.html
mkdir -p /opt/bin
mkdir /ips

#DOWNLOADING NETWORK COMPONENTS
curl -L git.io/weave -o /usr/local/bin/weave
wget -O /usr/local/bin/scope https://git.io/scope
wget https://download.zerotier.com/dist/zerotier-one_1.1.4_amd64.deb

#MARKING NETWORK COMPONENTS RUNNABLE
chmod a+x /usr/local/bin/weave
chmod a+x /usr/local/bin/scope

#INSTALLING ZEROTIER
dpkg -i zerotier-one_1.1.4_amd64.deb
systemctl restart zerotier-one
zerotier-cli join 565799d8f6d1ae56
systemctl stop docker
nohup docker daemon -H $(ifdata -pa zt0):2375 -H unix:///var/run/docker.sock &
export DOCKER_HOST=$(ifdata -pa zt0):2375
/usr/local/bin/weave launch 10.240.0.2
sudo weave expose > /ips/weave
export WEAVEIP=$(cat /ips/weave)
export ZT0_IPV4=$(ifdata -pa zt0)
/usr/local/bin/scope launch
export GOOGLEID=$(curl http://metadata.google.internal/computeMetadata/v1/instance/id -H "Metadata-Flavor: Google")
cat /etc/network-environment > /storage/ipinfo/$ID
curl -X POST -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Postman-Token: 1c5e1b3a-d123-1f55-f3a6-06c08f1ef25f" -d '    {
        "name":"one",
        "d_ipaddr":"192.168.194.54",
        "d_port": "2375"
    }' "http://192.168.194.222:4000/0.0/nodes/create"

