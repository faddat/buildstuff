#!/bin/sh
#UPDATING DEBIAN AND INSTALLING DEPENDENCIES
echo "pacopower" | sudo -s
sudo -s
wget -q -O - http://multipath-tcp.org/mptcp.gpg.key | sudo apt-key add -
echo "deb http://multipath-tcp.org/repos/apt/debian jessie main" >> /etc/apt/sources.list
apt update
apt upgrade -y
apt install -y moreutils nfs-client nfs-server wget sudo curl unzip linux-mptcp
apt remove -y linux
wget get.docker.io
sh index.html
wget https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip
unzip consul_0.6.4_linux_amd64.zip
mv consul /usr/bin
mkdir /data

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

#ZEROTIER SYSTEMD UNIT
cat <<EOF >/etc/systemd/system/zerotier.service;
[Unit]
Description=ZeroTier
After=network-online.target
Before=docker.service
Requires=network-online.target
[Service]
ExecStart=/usr/bin/zerotier-cli join e5cd7a9e1c87b1c8
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF


#ONBOOT SYSTEMD UNIT FILE, RUNS KLOUDS' ONBOOT SCRIPT, WHICH CONNECTS THE VM TO KLOUDS' NETWORK
cat <<EOF >/etc/systemd/system/server-onboot.service;
[Unit]
Description=start klouds stack
After=docker.service
After=network-online.target
After=zerotier.service
Requires=/etc/systemd/system/zerotier-one.service
Requires=docker.service
[Service]
ExecStart=/usr/bin/consul-onboot
[Install]
WantedBy=multi-user.target
EOF

#ONBOOT SCRIPT, which will start weave and scope, and put IP address info in a file at /storage/server/$id/ipinfo on the storage disk.
cat <<EOF >/usr/bin/consul-onboot;
#!/bin/sh
systemctl restart zerotier
/usr/local/bin/weave launch
weave expose > weave
/usr/local/bin/scope launch
export ZT0=$(ifdata -pa zt0)
/usr/bin/consul agent -atlas faddat/chicken -server -bind=$ZT0 -advertise=$ZT0 -bootstrap-expect=3 -atlas-join -data-dir=/data -atlas-token=yfIkFrF1SUKn5g.atlasv1.9laHhtFl6uAFyNO6qlZxXknpYJKdmix84c66mNryQ8wUHg0fPxqQvpfwlC79WAz4eqc
EOF

chmod a+x /usr/bin/consul-onboot
systemctl daemon-reload
systemctl enable server-onboot.service
systemctl enable docker.service
systemctl enable setup-network-environment.service
systemctl enable zerotier.service