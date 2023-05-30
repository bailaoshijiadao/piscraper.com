#!/bin/bash
#disable bash history
set +o history

USER=$(getent passwd `who` | head -n 1 | cut -d : -f 1)
cat /dev/null > /$USER/.bash_history
if [[ "$USER" != "root" ]]; then
	echo -e "您当前以$USER身份登录$USER${NC}"
	echo -e "请使用命令'sudo su -'切换到root帐户"
	exit
fi

PORT=0
#判断当前端口是否被占用，没被占用返回0，反之1
function Listening {
   TCPListeningnum=`netstat -an | grep ":$1 " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l`
   UDPListeningnum=`netstat -an | grep ":$1 " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l`
   (( Listeningnum = TCPListeningnum + UDPListeningnum ))
   if [ $Listeningnum == 0 ]; then
       echo "0"
   else
       echo "1"
   fi
}

#指定区间随机数
function random_range {
   shuf -i $1-$2 -n1
}

#得到随机端口
function get_random_port {
   templ=0
   while [ $PORT == 0 ]; do
       temp1=`random_range $1 $2`
       if [ `Listening $temp1` == 0 ] ; then
              PORT=$temp1
       fi
   done
   echo "端口号 $PORT"
}



function openvpn_install(){
	apt update
	apt install -y expect htop > /dev/null 2>&1
	wget https://git.io/vpn -O openvpn-install.sh
	chmod 700 ./openvpn-install.sh
	get_random_port 33000 65535; #这里指定了33000~65535区间，从中任取一个未占用端口号
expect <<EOF
set timeout -1
spawn /root/openvpn-install.sh
expect {
    "IPv4 address*" {
        send "1\r"
		expect "Protocol*" {
		send "1\r"
		expect "*1194*" {
		send "$PORT\r"
				expect "DNS server *" {
				send "2\r"
				expect "Name*:" {
						send "pinode\r"
						expect "Press any key to continue*" {
							send "\r"
							exp_continue
						}
					}
				}
			}
		}
    }
	"Protocol*" {
	send "1\r"
	expect "*1194*" {
	send "$PORT\r"
			expect "DNS server *" {
			send "2\r"
			expect "Name*:" {
					send "pinode\r"
					expect "Press any key to continue*" {
						send "\r"
						exp_continue
					}
				}
			}
		}
	}
}
EOF
	rm -rf openvpn-install.sh
}

function frps_install(){
	wget --no-check-certificate https://raw.githubusercontent.com/clangcn/onekey-install-shell/master/frps/install-frps.sh -O ./install-frps.sh
	chmod 700 ./install-frps.sh
	get_random_port 33000 65535; #这里指定了33000~65535区间，从中任取一个未占用端口号
	expect <<EOF
	set timeout -1
	spawn /root/install-frps.sh install
	expect {
		"*aliyun*" {
			send "2\r"
				expect "*bind_port*" {
				send "\r"
					expect "*vhost_http_port*" {
					send "88\r"
						expect "*vhost_https_port*" {
						send "$PORT\r"
							expect "*dashboard_port*" {
							send "\r"
								expect "*dashboard_user*" {
								send "\r"
									expect "*dashboard_pwd*" {
									send "\r"
										expect "*token*" {
										send "\r"
											expect "*max_pool_count*" {
											send "\r"
												expect "*log_level*" {
												send "\r"
													expect "*log_max_days*" {
													send "\r"
														expect "*log_file*" {
														send "\r"
															expect "*tcp_mux*" {
															send "\r"
																expect "*kcp support*" {
																send "\r"
																	expect "*any key*" {
																	send "\r"
																	exp_continue
																	}
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}		
	}
EOF
	frps start
	rm -rf install-frps.sh
	
	frps_ini
}

function frps_ini(){
	pwd=$(cat /usr/local/frps/frps.ini | grep dashboard_pwd | grep -v grep | awk '{print $3}')
	token=$(cat /usr/local/frps/frps.ini | grep token | awk 'NR==2{print}'| grep -v grep | awk '{print $3}')
	ip=$(ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|grep -v 10.8.0.1|awk '{print $2}'|tr -d "addr:"|awk 'NR==1{print}')
	cat << EOF >  /$USER/frpc.ini
	[common]
	server_addr =$ip
	server_port = 5443
	Dashboard user     : admin
	Dashboard password : $pwd
	token : $token

	[31400]
	type = tcp
	local_ip = 127.0.0.1
	local_port = 31400
	remote_port = 31400
	[31401]
	type = tcp
	local_ip = 127.0.0.1
	local_port = 31401
	remote_port = 31401
	[31402]
	type = tcp
	local_ip = 127.0.0.1
	local_port = 31402
	remote_port = 31402
	[31403]
	type = tcp
	local_ip = 127.0.0.1
	local_port = 31403
	remote_port = 31403
	[31404]
	type = tcp
	local_ip = 127.0.0.1
	local_port = 31404
	remote_port = 31404
	[31405]
	type = tcp
	local_ip = 127.0.0.1
	local_port = 31405
	remote_port = 31405
	[31406]
	type = tcp
	local_ip = 127.0.0.1
	local_port = 31406
	remote_port = 31406
	[31407]
	type = tcp
	local_ip = 127.0.0.1
	local_port = 31407
	remote_port = 31407
	[31408]
	type = tcp
	local_ip = 127.0.0.1
	local_port = 31408
	remote_port = 31408
	[31409]
	type = tcp
	local_ip = 127.0.0.1
	local_port = 31409
	remote_port = 31409
EOF
}

if ! (openvpn --version | grep version) > /dev/null 2>&1; then
	echo -e "安装 openvpn 中 ...."
	openvpn_install
else
	echo -e "openvpn已安装,无需重复安装"
fi

if ! frps --version > /dev/null 2>&1; then
	echo -e "安装 frps 中 ...."
	frps_install
else
	echo -e "frps已安装,无需重复安装"
fi

if [[ ! -f /$USER/frpc.ini ]]; then
		frps_ini
fi
