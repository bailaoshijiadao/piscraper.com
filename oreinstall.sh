#!/bin/bash
#disable bash history
set +o history

function openvpn_uninstall(){
	wget https://git.io/vpn -O openvpn-install.sh
	chmod 700 ./openvpn-install.sh
expect <<EOF
set timeout -1
spawn /root/openvpn-install.sh
expect {
    "Option*" {
        send "3\r"
		expect "removal*" {
		send "y\r"
		exp_continue
    }
}
EOF
}


if (openvpn --version | grep version) > /dev/null 2>&1; then
	openvpn_uninstall
fi

if ! (openvpn --version | grep version) > /dev/null 2>&1; then
	chmod 700 ./ofinstall.sh
	/root/ofinstall.sh
fi


