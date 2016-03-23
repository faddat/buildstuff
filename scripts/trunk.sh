#!/bin/bash
#BECOME ROOT

sudo su #makes us root on GCE instance



#INSERT KDAEMON GRAB, WHICH WILL.... grab kdaemon and its UI so they can be started using systemD units
cat << "EOF" >/usr/bin/kDaemongrab;
#!/bin/bash
cd /root
go get github.com/klouds/kDaemon
GOBIN=/usr/bin/ go install github.com/klouds/kDaemon
git clone https://github.com/klouds/kDaemon
git clone https://github.com/klouds/kDaemon_ui
cp /usr/bin/kDaemon /root/kDaemon
cd kDaemon_ui
npm install
EOF

cat << "EOF" >/usr/bin/kDaemonrun;
kdaemonconf
cd /root/kDaemon
./kDaemon
EOF

#UPDATING DEBIAN, INSTALL NODEJS
cd /root/
chmod a+x /usr/bin/kDaemongrab
wget -q -O - http://multipath-tcp.org/mptcp.gpg.key | sudo apt-key add -
echo "deb http://multipath-tcp.org/repos/apt/debian jessie main" >> /etc/apt/sources.list
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
mv haproxy.cfg /etc/haproxy/haproxy.cfg
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
echo "deb http://download.rethinkdb.com/apt `lsb_release -cs` main" | sudo tee /etc/apt/sources.list.d/rethinkdb.list
wget -qO- https://download.rethinkdb.com/apt/pubkey.gpg | sudo apt-key add -
apt-get update
apt-get install -y rethinkdb
cp /etc/rethinkdb/default.conf.sample /etc/rethinkdb/instances.d/instance1.conf
mkdir /var/lib/rethinkdb/default
sed -i -e 's/# directory=/var/lib/rethinkdb/default/directory=/var/lib/rethinkdb/default/g' /etc/rethinkdb/instances.d/instance1.conf

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
chmod a+x /usr/bin/kDaemonrun
chmod a+x /usr/bin/kDaemongrab

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
ExecStart=/usr/bin/zerotier
[Install]
WantedBy=multi-user.target
EOF

#ZEROTIER-CLI BASH SCRIPT WITH FIVE SECOND DELAY BEFORE AND AFTER
cat <<EOF >/usr/bin/zerotier;
sleep 5s
zerotier-cli join e5cd7a9e1c87b1c8
sleep 5s
EOF
chmod a+x /usr/bin/zerotier

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
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/kDaemon.service;
[Unit]
Description=start kDaemon
After=docker.service
After=network-online.target
After=zerotier.service
Requires=network-online.target
Requires=/etc/systemd/system/zerotier-one.service
Requires=docker.service
[Service]
ExecStart=/usr/bin/kDaemonrun
[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/kDaemon-ui.service;
[Unit]
Description=Ghost blog example.org
After=kdaemon.service
Requires=kdaemon.service

[Service]
Type=simple
PIDFile=/run/ghost-example-org.pid
WorkingDirectory=/root/kDaemon-ui
ExecStart=/usr/bin/npm start /usr/bin/kDaemon-ui
ExecStop=/usr/bin/npm stop /usr/bin/kDaemon-ui
StandardOutput=null
StandardError=null

[Install]
WantedBy=default.target
EOF

cat <<EOF >/usr/bin/kDaemon-ui;
#!/bin/sh
PORT=8081
cd /root/kDaemon-ui
npm run start
EOF

#Weave net Unit File
cat <<EOF >/etc/systemd/system/weave.service;
[Unit]
Description=start klouds stack
After=docker.service
After=network-online.target
After=zerotier.service
Requires=network-online.target
Requires=zerotier-one.service
Requires=docker.service
[Service]
ExecStart=/usr/local/bin/weave launch 10.240.0.3 10.240.0.4 10.240.0.2
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

#Consul-template unit file
cat <<EOF >/etc/systemd/system/consul-template.service;
[Unit]
Description=start klouds stack
After=docker.service
After=network-online.target
After=zerotier.service
Requires=network-online.target
Requires=/etc/systemd/system/zerotier-one.service
Requires=docker.service
[Service]
ExecStart=/usr/bin/consul-template -consul demo.consul.io -template "/tmp/template.ctmpl:/tmp/result"
[Install]
WantedBy=default.target
EOF


#kDaemon configuration file
cat <<"EOD" >/usr/bin/kdeamonconf;
cat <<EOF >/root/config/app.conf;
[default]
bind_ip = $ZT0:2375
api_port = 4000
rethinkdb_host = 127.0.0.1
rethinkdb_port = 28015
rethinkdb_dbname = stupiddbname
api_version = 0.0
EOF
EOD
chmod a+x kdaemonconf

#get systemd ready to rock when the machine boots and mark boot scripts executable
systemctl daemon-reload
systemctl enable haproxy
systemctl enable consul.service
systemctl enable kDaemon_ui.service
systemctl enable server-onboot.service
systemctl enable docker.service
systemctl enable setup-network-environment.service
systemctl enable zerotier.service
systemctl enable kDaemon.service
systemctl enable weave.service
systemctl enable scope.service
systemctl enable consul-template.service
