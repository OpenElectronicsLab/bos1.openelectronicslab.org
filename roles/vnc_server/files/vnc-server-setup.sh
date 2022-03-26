#!/bin/bash
# https://www.digitalocean.com/community/tutorials/how-to-set-up-vnc-server-on-debian-8

set -e

apt update
apt -y upgrade
apt install -y \
	autocutsel \
	build-essential \
	dbus-x11 \
	diffutils \
	firefox-esr \
	git \
	gnome-icon-theme \
	htop \
	net-tools \
	tightvncserver \
	vim-nox \
	xfce4 \
	xfce4-goodies \
	#

if [ ! -e /home/oeldev ]; then
	adduser --gecos "" --disabled-password oeldev
	# usermod -a -G admin oeldev
fi

cat > /lib/systemd/system/vnc-server@.service <<EOF
[Unit]
Description=VNC Server
After=syslog.target network.target

[Service]
Type=forking
ExecStartPre=-/usr/bin/vncserver -kill :%i >/dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x960 :%i
ExecStop=/usr/bin/vncserver -kill :%i
#ExecReload=
PIDFile=/home/oeldev/.vnc/%H:%i.pid
User=oeldev
Group=oeldev
WorkingDirectory=/home/oeldev

[Install]
WantedBy=multi-user.target
EOF

touch /home/oeldev/.Xresources

# passwordless
mkdir -pv /home/oeldev/.vnc
touch /home/oeldev/.vnc/passwd
chmod -v 600 /home/oeldev/.vnc/passwd

chown -Rv oeldev:oeldev /home/oeldev

if [ -e /etc/tightvncserver.conf ]; then
	if [ ! -e /etc/tightvncserver.conf.orig ]; then
		cp -v /etc/tightvncserver.conf{,.orig}
	fi
	sed -i -e 's/^#\s*\$authType\s*=.*/$authType = ""/' \
		/etc/tightvncserver.conf
	diff -u /etc/tightvncserver.conf.orig /etc/tightvncserver.conf
fi

systemctl daemon-reload
systemctl enable vnc-server@1.service
systemctl start vnc-server@1.service