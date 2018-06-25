#!/bin/bash
function install_caddy(){
	#yum install -y unzip zip
	#wget https://raw.githubusercontent.com/ssrosx/caddy/master/caddy.sh -O - -o /dev/null|bash
	#caddy install
	echo -e "是否需要更新系统"
	read -p "需要更新请输入‘y’(回车默认不更新):" UpdateSystem
	if [[ $UpdateSystem == "y" ]]
	then
		sudo yum install epel-release -y
		sudo yum update -y && sudo shutdown -r now
	else
		curl https://getcaddy.com | bash -s personal
		sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy
		sudo useradd -r -d /var/www -M -s /sbin/nologin caddy
		read -p "请输入域名(如ssrosx.com):" DomainName
		read -p "请输入邮箱(如xxx@xxx.xxx):" TlsEmail
		sudo mkdir -p /var/www/$DomainName
		sudo chown -R caddy:caddy /var/www
		sudo mkdir /etc/ssl/caddy
		sudo chown -R caddy:root /etc/ssl/caddy
		sudo chmod 0770 /etc/ssl/caddy
		sudo mkdir /etc/caddy
		sudo chown -R root:caddy /etc/caddy
		sudo touch /etc/caddy/Caddyfile
		sudo chown caddy:caddy /etc/caddy/Caddyfile
		sudo chmod 444 /etc/caddy/Caddyfile
cat <<EOF | sudo tee -a /etc/caddy/Caddyfile
$DomainName www.$DomainName {
root /var/www/$DomainName
gzip
tls $TlsEmail
}
EOF
		wget -N -P /etc/systemd/system https://raw.githubusercontent.com/ssrosx/caddy/master/caddy.service
		sudo systemctl daemon-reload
		sudo systemctl start caddy.service
		sudo systemctl enable caddy.service
		sudo firewall-cmd --permanent --zone=public --add-service=http 
		sudo firewall-cmd --permanent --zone=public --add-service=https
		sudo firewall-cmd --reload

		cd /var/www/$DomainName
		wget https://raw.githubusercontent.com/ssrosx/caddy/master/web_demo.zip
		unzip web_demo.zip
		sudo systemctl restart caddy.service
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "#         打开http://$DomainName or https://$DomainName             #"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		reboot
	fi
}

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
ulimit -c 0
rm -rf caddy*
clear
install_caddy