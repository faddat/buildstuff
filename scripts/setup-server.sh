#!/bin/sh
#BECOME ROOT
sudo -s

#INSERT KDAEMON GRAB, WHICH WILL.... grab kdaemon and its UI so they can be started using systemD units
cat <<EOF >/usr/bin/kDaemongrab;
#!/bin/bash
cd /root
export GOPATH=/root/go
export PATH=$PATH:/root/go/bin
sudo go get github.com/klouds/kDaemon
sudo cp /root/go/bin/kDaemon /root/kDaemon
sudo git clone https://github.com/klouds/kDaemon-ui
sudo cd kDaemon-ui
sudo npm install
sudo npm start
EOF

#Make folders we will be needing
sudo mkdir -p /opt/bin
sudo mkdir /ips
sudo mkdir /root/config
sudo mkdir /root/go
sudo mkdir /storage

#UPDATING DEBIAN, INSTALL NODEJS
sudo cd /root/
sudo chmod a+x /usr/bin/kDaemongrab
sudo curl -sL https://deb.nodesource.com/setup_5.x | bash -
sudo apt update
sudo apt upgrade -y
sudo apt install -y moreutils nfs-client nfs-server wget sudo curl unzip nodejs haproxy
sudo mkfs.btrfs /dev/sdb -q                                                                          #formats /dev/sdb only if it is't currently formatted.
sudo echo "/dev/sdb  /storage   btrfs    auto  0  0" >> /etc/fstab
sudo echo "/storage       192.168.0.0/16(rw,fsid=0,insecure,no_subtree_check,async)" >> /etc/exports
sudo wget get.docker.io
sudo sh index.html

#INSTALL RETHINKDB
sudo echo "deb http://download.rethinkdb.com/apt `lsb_release -cs` main" | sudo tee /etc/apt/sources.list.d/rethinkdb.list
sudo wget -qO- https://download.rethinkdb.com/apt/pubkey.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y rethinkdb

#DOWNLOAD AND INSTALL GOLANG
sudo wget https://storage.googleapis.com/golang/go1.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.6.linux-amd64.tar.gz

#DOWNLOAD AND INSTALL CONSUL
sudo wget https://releases.hashicorp.com/consul/0.6.3/consul_0.6.3_linux_amd64.zip
sudo unzip consul_0.6.3_linux_amd64.zip
sudo mv consul /usr/bin

#DOWNLOADING NETWORK COMPONENTS
sudo curl -L git.io/weave -o /usr/local/bin/weave
sudo wget -O /usr/local/bin/scope https://git.io/scope
sudo wget https://download.zerotier.com/dist/zerotier-one_1.1.4_amd64.deb
sudo wget -N -P /opt/bin https://github.com/kelseyhightower/setup-network-environment/releases/download/v1.0.0/setup-network-environment

#MARKING NETWORK COMPONENTS RUNNABLE
sudo chmod a+x /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/scope
sudo chmod a+x /opt/bin/setup-network-environment

#INSTALLING ZEROTIER
sudo dpkg -i zerotier-one_1.1.4_amd64.deb

#INSTALLING KDAEMON AND KDAEMON-UI
sudo sh /usr/bin/kDaemongrab

#I have attempted to list the systemd units in chronological-ish order.  I'm only certain that it's not quite right.

#ZEROTIER-CLI SYSTEMD UNIT
cat <<EOF >/etc/systemd/system/zerotier.service;
[Unit]
Description=ZeroTier
After=network-online.target
Before=docker.service
Before=setup-network-environment.service
Requires=network-online.target
Requires=zerotier-one.service
[Service]
ExecStart=/usr/bin/zerotier-cli join e5cd7a9e1c87b1c8
Type=notify
[Install]
WantedBy=multi-user.target
EOF


#CONSUL SYSTEMD UNIT
cat <<EOF >"/etc/systemd/system/consul.service";
[Unit]
Description=consul
After=network-online.target
After=zerotier.service
After=setup-network-environment.service
Requires=setup-network-environment.service
Requires=network-online.target
Requires=zerotier.service
[Service]
EnvironmentFile=/etc/network-environment
ExecStart=/usr/bin/consul agent -server -data-dir=/data -ui-dir=/ui -bind=${ZT0_IPV4} -advertise=${ZT0_IPV4} -join=192.168.194.229 -join=192.168.194.141 -join=192.168.194.216 -join=192.168.194.187
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

#SYSTEMD UNIT FOR kelseyhightower'S NETWORK-ENVIORNMENT-SERVICE WHICH ENSURES THAT IP ADDRESSES ARE ACCESSIBLE AT /etc/network-environment
cat <<EOF >/etc/systemd/system/setup-network-environment.service;
[Unit]
Description=Setup Network Environment
Documentation=https://github.com/kelseyhightower/setup-network-environment
Requires=network-online.target
Requires=zerotier-one.service
Requires=zerotier.zervice
Before=docker.socket
Before=docker.service
After=network-online.target
After=zerotier.service
[Service]
ExecStart=/opt/bin/setup-network-environment
RemainAfterExit=yes
Type=oneshot
[Install]
WantedBy=multi-user.target
EOF

#DOCKER SYSTEMD UNIT FILE, LAUNCHES DOCKER WITH PORT OPEN ON ZEROTIER ADDRESS REPORTED BY network-environment-service
cat <<EOF >"/lib/systemd/system/docker.service";
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target docker.socket
After=setup-network-environment.service
After=network-online.target
After=zerotier.service
Requires=docker.socket
Requires=network.target docker.socket
Requires=setup-network-environment.service
Requires=network-online.target
Requires=zerotier.service
[Service]
Type=notify
EnvironmentFile=/etc/network-environment
ExecStart=/usr/bin/docker daemon -H ${ZT0_IPV4}:2375
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
[Install]
WantedBy=default.target
EOF


cat <<EOF >/etc/systemd/system/kdaemon.service;
[Unit]
Description=start klouds stack
After=docker.service
After=network-online.target
After=zerotier.service
Requires=network-online.target
Requires=/etc/systemd/system/zerotier-one.service
Requires=docker.service
[Service]
ExecStart=/root/kDaemon
[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/kdaemon-ui.service;
[Unit]
Description=Ghost blog example.org
After=kdaemon.service
Requires=kdaemon.service

[Service]
Type=simple
PIDFile=/run/ghost-example-org.pid
WorkingDirectory=/root/kDaemon-ui
ExecStart=/usr/bin/npm start /root/kDaemon-ui
ExecStop=/usr/bin/npm stop /root/kDaemon-ui
StandardOutput=null
StandardError=null

[Install]
WantedBy=default.target
EOF

cat <<EOF >/etc/systemd/system/server-onboot.service;
[Unit]
Description=start klouds stack
After=docker.service
After=network-online.target
After=zerotier.service
Requires=network-online.target
Requires=/etc/systemd/system/zerotier-one.service
Requires=docker.service
[Service]
ExecStart=/usr/local/bin/scope
[Install]
WantedBy=default.target
EOF


#kDaemon configuration file
cat <<EOF >/root/config/app.conf;
[default]
bind_ip = ${ZT0IPV4}:2375
api_port = 4000
rethinkdb_host = 127.0.0.1
rethinkdb_port = 28015
rethinkdb_dbname = stupiddbname
api_version = 0.0
EOF

#get systemd ready to rock when the machine boots and mark boot scripts executable
chmod a+x /usr/bin/server-shutdown
chmod a+x /usr/bin/server-onboot
chmod a+x /usr/bin/startconsul
chmod a+x /usr/bin/startdocker
chmod a+x /usr/bin/kDaemongrab
systemctl daemon-reload
systemctl enable consul.service
systemctl enable server-onboot.service
systemctl enable docker.service
systemctl enable setup-network-environment.service
systemctl enable zerotier.service