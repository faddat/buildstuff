#!/bin/sh
#UPDATING UBUNTU AND INSTALLING DEPENDENCIES
sudo -s
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

#MARKING NETWORK COMPONENTS RUNNABLE
sudo chmod a+x /usr/local/bin/weave
sudo chmod a+x /usr/local/bin/scope

#INSTALLING ZEROTIER
sudo dpkg -i zerotier-one_1.1.4_amd64.deb

#ZEROTIER-CLI BASH SCRIPT WITH FIVE SECOND DELAY BEFORE AND AFTER
cat <<EOF >/usr/bin/zerotier;
sleep 5s
nohup zerotier-cli join 565799d8f6d1ae56 &
sleep 5s
EOF
chmod a+x /usr/bin/zerotier

#ONBOOT SYSTEMD UNIT FILE, RUNS KLOUDS' ONBOOT SCRIPT, WHICH CONNECTS THE VM TO KLOUDS' NETWORK
cat <<EOF >/etc/systemd/system/consul-onboot.service;
[Unit]
Description=start klouds stack
After=docker.service
After=network-online.target
After=zerotier.service
Requires=zerotier-one.service
Requires=docker.service
[Service]
ExecStart=/usr/bin/consul-onboot
[Install]
WantedBy=multi-user.target
EOF

#ONBOOT SCRIPT, which will start weave, scope and consul
cat <<"EOF" >/usr/bin/consul-onboot;
#!/bin/sh
systemctl restart zerotier
nohup docker daemon -H $(ifdata -pa zt0):2375 --storage-driver=overlay &
/usr/local/bin/weave launch
weave expose > weave
/usr/local/bin/scope launch
export ZT0=$(ifdata -pa zt0)
/usr/bin/consul agent -atlas faddat/chicken -server -bind=$ZT0 -advertise=$ZT0 -bootstrap-expect=3 -atlas-join -data-dir=/data -atlas-token=yfIkFrF1SUKn5g.atlasv1.9laHhtFl6uAFyNO6qlZxXknpYJKdmix84c66mNryQ8wUHg0fPxqQvpfwlC79WAz4eqc
EOF
chmod a+x /usr/bin/consul-onboot


systemctl daemon-reload
systemctl enable consul-onboot
systemctl enable docker
systemctl enable zerotier
systemctl enable zerotier-one
systemctl enable ssh