#!/bin/bash
function rand(){  
    min=$1  
    max=$(($2-$min+1))  
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')  
    echo $(($num%$max+$min))  
}

function install_caddy(){
	echo -e "是否需要更新系统"
	read -p "需要更新请输入‘y’(回车默认不更新):" UpdateSystem
	if [[ $UpdateSystem == "y" ]]
	then
		sudo yum install epel-release -y
		sudo yum update -y && sudo shutdown -r now
	else
		sudo yum install unzip zip -y
		curl https://getcaddy.com | bash -s personal
		sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy
		sudo useradd -r -d /var/www -M -s /sbin/nologin caddy
		read -p "请输入域名(如ssrosx.com):" DomainName
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
		rndport=$(rand 10000 50000)
		echo -e "1 ： 使用IP安装"
		echo -e "2 ： 使用域名安装"
		read -p "请选择安装类型（默认IP安装）:" InstallType
		InstallType=${InstallType:-"ip"}
		if [[ $InstallType == "ip" ]]
		then
			yum install curl -y
			ip=`curl ip.3322.net`
cat <<EOF | sudo tee -a /etc/caddy/Caddyfile
http://${ip}:$rndport {
root /var/www/$DomainName
timeouts none
gzip
}
EOF
		else
			read -p "请输入邮箱(如xxx@xxx.xxx):" TlsEmail
cat <<EOF | sudo tee -a /etc/caddy/Caddyfile
$DomainName:$rndport www.$DomainName:$rndport {
root /var/www/$DomainName
timeouts none
gzip
tls $TlsEmail
}
EOF
			sudo wget https://raw.githubusercontent.com/ssrosx/caddy/master/caddy.service
			sudo mv caddy.service /etc/systemd/system
			sudo systemctl daemon-reload
			sudo systemctl start caddy.service
			sudo systemctl enable caddy.service
			sudo firewall-cmd --permanent --zone=public --add-service=http 
			sudo firewall-cmd --permanent --zone=public --add-service=https
			sudo firewall-cmd --reload

			cd /var/www/$DomainName
			sudo wget https://raw.githubusercontent.com/ssrosx/caddy/master/web_demo.zip
			sudo unzip web_demo.zip
			sudo rm -rf web_demo.zip
			sudo systemctl restart caddy.service
			echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
			echo "#         打开http://$DomainName or https://$DomainName            #"
			echo "#         打开http://www.$DomainName or https://www.$DomainName    #"
			echo "#         在配置的时候请输入端口：$rndport                            #"
			echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
			sudo shutdown -r now
		fi
	fi
}

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
ulimit -c 0
rm -rf caddy*
clear
install_caddy