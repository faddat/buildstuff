#!/bin/bash
#BECOME ROOT

sudo su #makes us root on GCE instance

#INSERT KDAEMON GRAB, WHICH WILL.... grab kdaemon and its UI so they can be started using systemD units
cat << "EOF" >/usr/bin/kDaemongrab;
#!/bin/bash
cd /root
go get github.com/klouds/kDaemon
git clone https://github.com/klouds/kDaemon
git clone https://github.com/klouds/kDaemon_ui
cp $GOPATH/bin/kDaemon /root/kDaemon
cd kDaemon_ui
npm install
EOF

#UPDATING DEBIAN, INSTALL NODEJS
cd /root/
chmod a+x /usr/bin/kDaemongrab
curl -sL https://deb.nodesource.com/setup_5.x | bash -
apt update
apt install -y moreutils nfs-client nfs-server wget sudo curl unzip nodejs haproxy binutils bison build-essential
apt upgrade -y
mkfs.btrfs /dev/sdb -q                                                                          #formats /dev/sdb only if it is't currently formatted.
echo "/dev/sdb  /storage   btrfs    auto  0  0" >> /etc/fstab
echo "/storage       192.168.0.0/16(rw,fsid=0,insecure,no_subtree_check,async)" >> /etc/exports
wget get.docker.io
sh index.html

#Downloading and installing HAPROXY configuration files
git clone https://github.com/Klouds/consul-template/
cd consul-template
wget https://releases.hashicorp.com/consul-template/0.14.0/consul-template_0.14.0_linux_amd64.zip
unzip consul-template_0.14.0_linux_amd64.zip
mv consul-template /usr/bin


#Make folders we will be needing
mkdir /go
mkdir -p /opt/bin
mkdir /ips
mkdir /root/config
mkdir /root/go
mkdir /storage

#INSTALL RETHINKDB
sudo echo "deb http://download.rethinkdb.com/apt `lsb_release -cs` main" | sudo tee /etc/apt/sources.list.d/rethinkdb.list
sudo wget -qO- https://download.rethinkdb.com/apt/pubkey.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y rethinkdb

#DOWNLOAD AND INSTALL GOLANG
curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash
source /root/.gvm/scripts/gvm
gvm install go1.6 -B
gvm use go1.6 --default

#DOWNLOAD AND INSTALL CONSUL
wget https://releases.hashicorp.com/consul/0.6.3/consul_0.6.3_linux_amd64.zip
unzip consul_0.6.3_linux_amd64.zip
mv consul /usr/bin

#DOWNLOADING NETWORK COMPONENTS
curl -L git.io/weave -o /usr/local/bin/weave
wget -O /usr/local/bin/scope https://git.io/scope
wget https://download.zerotier.com/dist/zerotier-one_1.1.4_amd64.deb
wget -N -P /opt/bin https://github.com/kelseyhightower/setup-network-environment/releases/download/v1.0.0/setup-network-environment

#MARKING NETWORK COMPONENTS RUNNABLE
chmod a+x /usr/local/bin/weave
chmod a+x /usr/local/bin/scope
chmod a+x /opt/bin/setup-network-environment

#INSTALLING ZEROTIER
dpkg -i zerotier-one_1.1.4_amd64.deb

#INSTALLING KDAEMON AND KDAEMON-UI
kDaemongrab

#I have attempted to list the systemd units in chronological-ish order.  I'm only certain that it's not quite right (the system will execute them in the correct order regardleess).

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
Type=OneShot
[Install]
WantedBy=multi-user.target
EOF


#CONSUL SYSTEMD UNIT
cat <<"EOF" >/etc/systemd/system/consul.service;
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
ExecStart=/usr/bin/consul agent -server -data-dir=/data -ui-dir=/ui -bind=$ZT0_IPV4 -advertise=$ZT0_IPV4 -join=192.168.194.229 -join=192.168.194.141 -join=192.168.194.216 -join=192.168.194.187
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
Type=oneshot
[Install]
WantedBy=multi-user.target
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
ExecStart=/root/.gvm/
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

#Weave net Unit File
cat <<EOF >/etc/systemd/system/weave.service;
[Unit]
Description=start klouds stack
After=docker.service
After=network-online.target
After=zerotier.service
Requires=network-online.target
Requires=/etc/systemd/system/zerotier-one.service
Requires=docker.service
[Service]
ExecStart=/usr/local/bin/weave launch
[Install]
WantedBy=default.target
EOF

#Weave Scope Unit File
cat <<EOF >/etc/systemd/system/scope.service;
[Unit]
Description=start klouds stack
After=docker.service
After=network-online.target
After=zerotier.service
Requires=network-online.target
Requires=/etc/systemd/system/zerotier-one.service
Requires=docker.service
[Service]
ExecStart=/usr/local/bin/scope launch
[Install]
WantedBy=default.target
EOF


#kDaemon configuration file
cat <<"EOF" >/root/config/app.conf;
[default]
bind_ip = $ZT0:2375
api_port = 4000
rethinkdb_host = 127.0.0.1
rethinkdb_port = 28015
rethinkdb_dbname = stupiddbname
api_version = 0.0
EOF

#get systemd ready to rock when the machine boots and mark boot scripts executable
systemctl daemon-reload
systemctl enable haproxy
systemctl enable consul.service
systemctl enable kdaemon_ui.service
systemctl enable server-onboot.service
systemctl enable docker.service
systemctl enable setup-network-environment.service
systemctl enable zerotier.service
systemctl enable kdaemon.service
systemctl enable waeave.service
systemctl enable scope.service
