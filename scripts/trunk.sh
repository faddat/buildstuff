#!/bin/bash
#BECOME ROOT

sudo -s
export EXTERNAL=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/‌​0/external-ip)
export INTERNAL=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/‌​0/internal-ip)

#UPDATING DEBIAN, INSTALL NODEJS
cd /root/
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
Type=oneshot
[Install]
WantedBy=multi-user.target
EOF

#ZEROTIER-CLI BASH SCRIPT WITH FIVE SECOND DELAY BEFORE AND AFTER
cat <<EOF >/usr/bin/zerotier;
sleep 5s
zerotier-cli join 565799d8f6d1ae56 > /result
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
ExecStart=/usr/bin/consul-template -consul 192.168.194.45 -template "/root/consul-template/haproxy.tmpl:/etc/haproxy/"
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
ExecStart=/usr/bin/consul-template -consul 192.168.194.45 -template "/root/consul-template/haproxy.tmpl:/etc/haproxy/"
[Install]
WantedBy=default.target
EOF

#kDaemon configuration file
cat <<"EOD" >/usr/bin/kdeamonconf;
curl -H 'PddToken: FCDJY2JOFHG2SA3SXWBQT7PUAA3PI6JST62EM5JVPIQ64DQDI7SQ' -d 'domain=domain.com&type=A&subdomain=www&ttl=14400&content=127.0.0.1' 'https://pddimp.yandex.ru/api2/admin/dns/add'soa
EOD
chmod a+x kdaemonconf

#get systemd ready to rock when the machine boots and mark boot scripts executable
systemctl daemon-reload
systemctl enable haproxy
systemctl enable kDaemon_ui.service
systemctl enable server-onboot.service
systemctl enable docker.service
systemctl enable setup-network-environment.service
systemctl enable zerotier.service
systemctl enable kDaemon.service
systemctl enable weave.service
systemctl enable scope.service
systemctl enable consul-template.service
systemctl enable domainreg.service
