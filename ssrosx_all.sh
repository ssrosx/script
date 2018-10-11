#!/bin/bash
[ $(id -u) != "0" ] && { echo "错误: 您必须以root用户运行此脚本"; exit 1; }
function check_system(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
	if [[ ${release} = "centos" ]] && [[ ${bit} == "x86_64" ]]; then
	echo -e "你的系统为[${release} ${bit}],检测\033[32m 可以 \033[0m搭建。"
	else 
	echo -e "你的系统为[${release} ${bit}],检测\033[31m 不可以 \033[0m搭建。"
	echo -e "\033[31m 正在退出脚本... \033[0m"
	exit 0;
	fi
}

function install_ssrosx_nosql(){
	yum -y remove httpd
	yum install -y unzip zip git
	#自动选择下载节点
	GIT='raw.githubusercontent.com'
	MY='gitee.com'
	GIT_PING=`ping -c 1 -w 1 $GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	MY_PING=`ping -c 1 -w 1 $MY|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$GIT_PING $GIT" > ping.pl
	echo "$MY_PING $MY" >> ping.pl
	fileinfo=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$fileinfo" == "$GIT" ];then
		fileinfo='https://raw.githubusercontent.com/ssrosx/script/master/fileinfo.zip'
	else
		fileinfo='https://raw.githubusercontent.com/ssrosx/script/master/fileinfo.zip'
	fi
	rm -f ping.pl	
	 wget -c --no-check-certificate https://raw.githubusercontent.com/ssrosx/script/master/lnmp1.4.zip && unzip lnmp1.4.zip && rm -rf lnmp1.4.zip && cd lnmp1.4 && chmod +x install_web.sh && ./install_web.sh
	clear
	#安装fileinfo必须组件
	cd /root && wget --no-check-certificate $fileinfo
	File="/root/fileinfo.zip"
    if [ ! -f "$File" ]; then  
    echo "fileinfo组件下载失败，请检查/root/fileinfo.zip"
	exit 0;
	else
    unzip fileinfo.zip
    fi
	cd /root/fileinfo && /usr/local/php/bin/phpize && ./configure --with-php-config=/usr/local/php/bin/php-config --with-fileinfo && make && make install
	cd /home/wwwroot/
	cp -r default/phpmyadmin/ .  #复制数据库
	cd default
	rm -rf index.html
	#获取git最新master版文件 带有风险
	#git clone https://github.com/ssrpanel/SSRPanel.git
	#cd SSRPanel
	#git submodule update --init --recursive
	#mv * .[^.]* ..&& cd /home/wwwroot/default && rm -rf SSRPanel

	git clone https://github.com/ssrosx/ssrosx.git
	cd ssrosx
	git submodule update --init --recursive
	mv * .[^.]* ..&& cd /home/wwwroot/default && rm -rf ssrosx
	
	#获取git最新released版文件 适用于生产环境
	#ssrpanel_new_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/ssrpanel/SSRPanel/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g;s/v//g' | sed 's/tag_name: //g')
	#wget -c --no-check-certificate "https://github.com/ssrpanel/SSRPanel/archive/${ssrpanel_new_ver}.tar.gz"
	#tar zxvf "${ssrpanel_new_ver}.tar.gz" && cd SSRPanel-* && mv * .[^.]* ..&& cd /home/wwwroot/default && rm -rf "${ssrpanel_new_ver}.tar.gz"
	#替换数据库配置
	#read -p "请输入您的对接数据库IP(默认：本地IP地址):" Userip
	#read -p "请输入数据库名称(默认：ssrosx):" Dbname
	#read -p "请输入数据库端口(默认：3306):" Dbport
	#read -p "请输入数据库帐户(默认：root):" Dbuser
	#read -p "请输入数据库密码(默认：root):" Dbpassword
	#Userip=${Userip:-"127.0.0.1"}
	#Dbname=${Dbname:-"ssrosx"}
	#Dbport=${Dbport:-"3306"}
	#Dbuser=${Dbuser:-"root"}
	#Dbpassword=${Dbpassword:-"root"}
	#wget -N -P /home/wwwroot/default/config/ https://raw.githubusercontent.com/ssrosx/script/master/app.php
	#wget -N -P /home/wwwroot/default/config/ https://raw.githubusercontent.com/ssrosx/script/master/database.php
	wget -N -P /usr/local/php/etc/ https://raw.githubusercontent.com/ssrosx/script/master/php.ini
	wget -N -P /usr/local/nginx/conf/ https://raw.githubusercontent.com/ssrosx/script/master/nginx.conf
	#sed -i "s#Userip#${Userip}#" /home/wwwroot/default/config/database.php
	#sed -i "s#Dbname#${Dbname}#" /home/wwwroot/default/config/database.php
	#sed -i "s#Dbport#${Dbport}#" /home/wwwroot/default/config/database.php
	#sed -i "s#Dbuser#${Dbuser}#" /home/wwwroot/default/config/database.php
	#sed -i "s#Dbpassword#${Dbpassword}#" /home/wwwroot/default/config/database.php
	read -p "是否需要安装 ‘redis’(默认：y):" InstallRedis
	InstallRedis=${InstallRedis:-"y"}
	if [ "$InstallRedis" == "y" ];then
		mkdir /usr/local/redis
		#install redis
		cd /root && wget https://raw.githubusercontent.com/ssrosx/script/master/redis-4.0.8.tar.gz
		tar zxvf redis-4.0.8.tar.gz
		cd redis-4.0.8
		make && make install
		#配置redis
		wget -N -P /etc/ https://raw.githubusercontent.com/ssrosx/script/master/redis.conf
		chmod +x /etc/rc.d/rc.local
		echo "/usr/local/bin/redis-server /etc/redis.conf" >> /etc/rc.d/rc.local 
		redis-server /etc/redis.conf
	fi
	service nginx restart

	#安装依赖
	cd /home/wwwroot/default/
	php composer.phar install
	php artisan key:generate
    chown -R www:www storage/
    chmod -R 777 storage/
	chattr -i .user.ini
	mv .user.ini public
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	chattr +i public/.user.ini
	service nginx restart
    service php-fpm restart
	#开启日志监控
	yum -y install vixie-cron crontabs
	#rm -rf /var/spool/cron/root
	#echo '* * * * * php /home/wwwroot/default/artisan schedule:run >> /dev/null 2>&1' >> /var/spool/cron/root
	rm -rf /var/spool/cron/www
	echo '* * * * * php /home/wwwroot/default/artisan schedule:run >> /dev/null 2>&1' >> /var/spool/cron/www
	#或者执行 crontab -e -u www 在文件中加入 '* * * * * php /home/wwwroot/default/artisan schedule:run >> /dev/null 2>&1'
	service crond restart
	#修复数据库
	# mv /home/wwwroot/default/phpmyadmin/ /home/wwwroot/default/public/
	# cd /home/wwwroot/default/public/phpmyadmin
	# chmod -R 755 *
	lnmp restart
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "#    一键搭建前端面板完成，请访问http://${IPAddress}~ 查看         #"
	echo "#    需配置config/database.php中connections-mysql-host         #"
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
}

function install_ssrosx_sql(){
	yum -y remove httpd
	yum install -y unzip zip git
	#自动选择下载节点
	GIT='raw.githubusercontent.com'
	MY='gitee.com'
	GIT_PING=`ping -c 1 -w 1 $GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	MY_PING=`ping -c 1 -w 1 $MY|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$GIT_PING $GIT" > ping.pl
	echo "$MY_PING $MY" >> ping.pl
	fileinfo=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$fileinfo" == "$GIT" ];then
		fileinfo='https://raw.githubusercontent.com/ssrosx/script/master/fileinfo.zip'
	else
		fileinfo='https://raw.githubusercontent.com/ssrosx/script/master/fileinfo.zip'
	fi
	rm -f ping.pl	
	 wget -c --no-check-certificate https://raw.githubusercontent.com/ssrosx/script/master/lnmp1.4.zip && unzip lnmp1.4.zip && rm -rf lnmp1.4.zip && cd lnmp1.4 && chmod +x install_all.sh && ./install_all.sh
	clear
	#安装fileinfo必须组件
	cd /root && wget --no-check-certificate $fileinfo
	File="/root/fileinfo.zip"
    if [ ! -f "$File" ]; then  
    echo "fileinfo组件下载失败，请检查/root/fileinfo.zip"
	exit 0;
	else
    unzip fileinfo.zip
    fi
	cd /root/fileinfo && /usr/local/php/bin/phpize && ./configure --with-php-config=/usr/local/php/bin/php-config --with-fileinfo && make && make install
	cd /home/wwwroot/
	cp -r default/phpmyadmin/ .  #复制数据库
	cd default
	rm -rf index.html
	#获取git最新master版文件 带有风险
	#git clone https://github.com/ssrpanel/SSRPanel.git
	#cd SSRPanel
	#git submodule update --init --recursive
	#mv * .[^.]* ..&& cd /home/wwwroot/default && rm -rf SSRPanel

	git clone https://github.com/ssrosx/ssrosx.git
	cd ssrosx
	git submodule update --init --recursive
	mv * .[^.]* ..&& cd /home/wwwroot/default && rm -rf ssrosx
	
	#获取git最新released版文件 适用于生产环境
	#ssrpanel_new_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/ssrpanel/SSRPanel/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g;s/v//g' | sed 's/tag_name: //g')
	#wget -c --no-check-certificate "https://github.com/ssrpanel/SSRPanel/archive/${ssrpanel_new_ver}.tar.gz"
	#tar zxvf "${ssrpanel_new_ver}.tar.gz" && cd SSRPanel-* && mv * .[^.]* ..&& cd /home/wwwroot/default && rm -rf "${ssrpanel_new_ver}.tar.gz"
	#替换数据库配置
	#read -p "请输入您的对接数据库IP(默认：127.0.0.1):" Userip
	#read -p "请输入数据库名称(默认：ssrosx):" Dbname
	#read -p "请输入数据库端口(默认：3306):" Dbport
	#read -p "请输入数据库帐户(默认：root):" Dbuser
	#read -p "请输入数据库密码(默认：root):" Dbpassword
	#Userip=${Userip:-"127.0.0.1"}
	#Dbname=${Dbname:-"ssrosx"}
	#Dbport=${Dbport:-"3306"}
	#Dbuser=${Dbuser:-"root"}
	#Dbpassword=${Dbpassword:-"root"}
	#wget -N -P /home/wwwroot/default/config/ https://raw.githubusercontent.com/ssrosx/script/master/app.php
	#wget -N -P /home/wwwroot/default/config/ https://raw.githubusercontent.com/ssrosx/script/master/database.php
	wget -N -P /usr/local/php/etc/ https://raw.githubusercontent.com/ssrosx/script/master/php.ini
	wget -N -P /usr/local/nginx/conf/ https://raw.githubusercontent.com/ssrosx/script/master/nginx.conf
	#sed -i "s#Userip#${Userip}#" /home/wwwroot/default/config/database.php
	#sed -i "s#Dbname#${Dbname}#" /home/wwwroot/default/config/database.php
	#sed -i "s#Dbport#${Dbport}#" /home/wwwroot/default/config/database.php
	#sed -i "s#Dbuser#${Dbuser}#" /home/wwwroot/default/config/database.php
	#sed -i "s#Dbpassword#${Dbpassword}#" /home/wwwroot/default/config/database.php
	read -p "是否需要安装 ‘redis’(默认：y):" InstallRedis
	InstallRedis=${InstallRedis:-"y"}
	if [ "$InstallRedis" == "y" ];then
		mkdir /usr/local/redis
		#install redis
		cd /root && wget https://raw.githubusercontent.com/ssrosx/script/master/redis-4.0.8.tar.gz
		tar zxvf redis-4.0.8.tar.gz
		cd redis-4.0.8
		make && make install
		#配置redis
		wget -N -P /etc/ https://raw.githubusercontent.com/ssrosx/script/master/redis.conf
		chmod +x /etc/rc.d/rc.local
		echo "/usr/local/bin/redis-server /etc/redis.conf" >> /etc/rc.d/rc.local 
		redis-server /etc/redis.conf
	fi
	service nginx restart
	#设置数据库
	#mysql -uroot -proot -e"create database ssrosx;" 
	#mysql -uroot -proot -e"use ssrosx;" 
	#mysql -uroot -proot ssrosx < /home/wwwroot/default/sql/db.sql
	#开启数据库远程访问，以便对接节点
	#mysql -uroot -proot -e"use mysql;"
	#mysql -uroot -proot -e"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;"
	#mysql -uroot -proot -e"flush privileges;"
read -p "数据库名字 sqlname(默认：ssrosx):" SqlName
read -p "数据库密码 sqlpasswd(默认：root):" SqlPassword
SqlName=${SqlName:-"ssrosx"}
SqlPassword=${SqlPassword:-"root"}
mysql -hlocalhost -uroot -p$SqlPassword --default-character-set=utf8mb4<<EOF
create database $SqlName;
use $SqlName;
source /home/wwwroot/default/sql/db.sql;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$SqlPassword' WITH GRANT OPTION;
flush privileges;
EOF
	#安装依赖
	cd /home/wwwroot/default/
	php composer.phar install
	php artisan key:generate
    chown -R www:www storage/
    chmod -R 777 storage/
	chattr -i .user.ini
	mv .user.ini public
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	chattr +i public/.user.ini
	service nginx restart
    service php-fpm restart
	#开启日志监控
	yum -y install vixie-cron crontabs
	#rm -rf /var/spool/cron/root
	#echo '* * * * * php /home/wwwroot/default/artisan schedule:run >> /dev/null 2>&1' >> /var/spool/cron/root
	rm -rf /var/spool/cron/www
	echo '* * * * * php /home/wwwroot/default/artisan schedule:run >> /dev/null 2>&1' >> /var/spool/cron/www
	#或者执行 crontab -e -u www 在文件中加入 '* * * * * php /home/wwwroot/default/artisan schedule:run >> /dev/null 2>&1'
	service crond restart
	#修复数据库
	# mv /home/wwwroot/default/phpmyadmin/ /home/wwwroot/default/public/
	# cd /home/wwwroot/default/public/phpmyadmin
	# chmod -R 755 *
	lnmp restart
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "#    一键搭建前端面板完成，请访问http://${IPAddress}~ 查看         #"
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
}

function install_log(){
    myFile="/root/shadowsocksr/ssserver.log"  
	if [ ! -f "$myFile" ]; then  
    echo "您的shadowsocksr环境未安装"
	echo "请检查/root/shadowsocksr/ssserver.log是否存在"
	else
	cd /home/wwwroot/default/storage/app
	ln -S ssserver.log /root/shadowsocksr/ssserver.log
	chown www:www ssserver.log
	chmod 0777 /home/wwwroot/default/storage/app/ssserver.log
	chmod 777 -R /home/wwwroot/default/storage/logs/
	echo "日志分析（仅支持单机单节点） - 安装成功"
    fi
}

function change_password(){
	echo -e "\033[31m注意:必须正确填写数据库密码，否则只能手动修改。\033[0m"
	read -p "请输入数据库密码(初始密码为root):" Default_password
	Default_password=${Default_password:-"root"}
	read -p "请输入要设置的数据库密码:" Change_password
	Change_password=${Change_password:-"root"}
	echo -e "\033[31m您设置的密码是:${Change_password}\033[0m"
mysql -hlocalhost -uroot -p$Default_password --default-character-set=utf8<<EOF
use mysql;
update user set password=passworD("${Change_password}") where user='root';
flush privileges;
EOF
}

function install_ssr(){
	yum -y update
	yum -y install git 
	yum -y install python-setuptools && easy_install pip 
	yum -y groupinstall "Development Tools" 
	#512M chicks add 1 g of Swap
	dd if=/dev/zero of=/var/swap bs=1024 count=1048576
	mkswap /var/swap
	chmod 0644 /var/swap
	swapon /var/swap
	echo '/var/swap   swap   swap   default 0 0' >> /etc/fstab
	#自动选择下载节点
	GIT='raw.githubusercontent.com'
	LIB='download.libsodium.org'
	GIT_PING=`ping -c 1 -w 1 $GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	LIB_PING=`ping -c 1 -w 1 $LIB|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$GIT_PING $GIT" > ping.pl
	echo "$LIB_PING $LIB" >> ping.pl
	libAddr=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$libAddr" == "$GIT" ];then
		libAddr='https://raw.githubusercontent.com/ssrosx/script/master/libsodium-1.0.13.tar.gz'
	else
		libAddr='https://download.libsodium.org/libsodium/releases/libsodium-1.0.13.tar.gz'
	fi
	rm -f ping.pl
	wget --no-check-certificate $libAddr
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	yum -y install python-setuptools
	easy_install supervisor
    cd /root
	wget https://raw.githubusercontent.com/ssrosx/script/master/shadowsocksr.zip
	unzip shadowsocksr.zip
	cd shadowsocksr
	./initcfg.sh
	chmod 777 *
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/user-config.json
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/userapiconfig.py
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/usermysql.json
	sed -i "s#Userip#${Userip}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbuser#${Dbuser}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbport#${Dbport}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbpassword#${Dbpassword}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbname#${Dbname}#" /root/shadowsocksr/usermysql.json
	sed -i "s#UserNODE_ID#${UserNODE_ID}#" /root/shadowsocksr/usermysql.json
	sed -i "s#ServerPort#${ServerPort}#" /root/shadowsocksr/user-config.json
	sed -i "s#PasswordValue#${PasswordValue}#" /root/shadowsocksr/user-config.json
	sed -i "s#WebPort#${WebPort}#" /root/shadowsocksr/user-config.json
	sed -i "s#WebPort#${WebPort}#" /root/shadowsocksr/user-config.json
	yum -y install lsof lrzsz python-devel libffi-devel openssl-devel iptables
	systemctl stop firewalld.service
	systemctl disable firewalld.service
}

function install_ssr_compatible(){
	yum -y update
	yum -y install git 
	yum -y install python-setuptools && easy_install pip 
	yum -y groupinstall "Development Tools" 
	#512M chicks add 1 g of Swap
	dd if=/dev/zero of=/var/swap bs=1024 count=1048576
	mkswap /var/swap
	chmod 0644 /var/swap
	swapon /var/swap
	echo '/var/swap   swap   swap   default 0 0' >> /etc/fstab
	#自动选择下载节点
	GIT='raw.githubusercontent.com'
	LIB='download.libsodium.org'
	GIT_PING=`ping -c 1 -w 1 $GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	LIB_PING=`ping -c 1 -w 1 $LIB|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$GIT_PING $GIT" > ping.pl
	echo "$LIB_PING $LIB" >> ping.pl
	libAddr=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$libAddr" == "$GIT" ];then
		libAddr='https://raw.githubusercontent.com/ssrosx/script/master/libsodium-1.0.13.tar.gz'
	else
		libAddr='https://download.libsodium.org/libsodium/releases/libsodium-1.0.13.tar.gz'
	fi
	rm -f ping.pl
	wget --no-check-certificate $libAddr
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	yum -y install python-setuptools
	easy_install supervisor
    cd /root
	wget https://raw.githubusercontent.com/ssrosx/script/master/shadowsocksr.zip
	unzip shadowsocksr.zip
	cd shadowsocksr
	./initcfg.sh
	chmod 777 *
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/user-config_compatible.json
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/userapiconfig.py
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/usermysql.json
	sed -i "s#Userip#${Userip}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbuser#${Dbuser}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbport#${Dbport}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbpassword#${Dbpassword}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbname#${Dbname}#" /root/shadowsocksr/usermysql.json
	sed -i "s#UserNODE_ID#${UserNODE_ID}#" /root/shadowsocksr/usermysql.json
	sed -i "s#ServerPort#${ServerPort}#" /root/shadowsocksr/user-config_compatible.json
	sed -i "s#PasswordValue#${PasswordValue}#" /root/shadowsocksr/user-config_compatible.json
	sed -i "s#WebPort#${WebPort}#" /root/shadowsocksr/user-config_compatible.json
	sed -i "s#WebPort#${WebPort}#" /root/shadowsocksr/user-config_compatible.json
	rm -rf /root/shadowsocksr/user-config_compatible.json
	mv /root/shadowsocksr/user-config_compatible.json /root/shadowsocksr/user-config.json
	yum -y install lsof lrzsz python-devel libffi-devel openssl-devel iptables
	systemctl stop firewalld.service
	systemctl disable firewalld.service
}

function install_ssr_only(){
	yum -y update
	yum -y install git 
	yum -y install python-setuptools && easy_install pip 
	yum -y groupinstall "Development Tools" 
	#512M chicks add 1 g of Swap
	dd if=/dev/zero of=/var/swap bs=1024 count=1048576
	mkswap /var/swap
	chmod 0644 /var/swap
	swapon /var/swap
	echo '/var/swap   swap   swap   default 0 0' >> /etc/fstab
	#自动选择下载节点
	GIT='raw.githubusercontent.com'
	LIB='download.libsodium.org'
	GIT_PING=`ping -c 1 -w 1 $GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	LIB_PING=`ping -c 1 -w 1 $LIB|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$GIT_PING $GIT" > ping.pl
	echo "$LIB_PING $LIB" >> ping.pl
	libAddr=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$libAddr" == "$GIT" ];then
		libAddr='https://raw.githubusercontent.com/ssrosx/script/master/libsodium-1.0.13.tar.gz'
	else
		libAddr='https://download.libsodium.org/libsodium/releases/libsodium-1.0.13.tar.gz'
	fi
	rm -f ping.pl
	wget --no-check-certificate $libAddr
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	yum -y install python-setuptools
	easy_install supervisor
    cd /root
	wget https://raw.githubusercontent.com/ssrosx/script/master/shadowsocksr.zip
	unzip shadowsocksr.zip
	cd shadowsocksr
	./initcfg.sh
	chmod 777 *
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/user-config-only.json
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/userapiconfig.py
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/usermysql.json
	sed -i "s#Userip#${Userip}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbuser#${Dbuser}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbport#${Dbport}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbpassword#${Dbpassword}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbname#${Dbname}#" /root/shadowsocksr/usermysql.json
	sed -i "s#UserNODE_ID#${UserNODE_ID}#" /root/shadowsocksr/usermysql.json
	#sed -i "s#ServerPort#${ServerPort}#" /root/shadowsocksr/user-config-only.json
	sed -i "s#PasswordValue#${PasswordValue}#" /root/shadowsocksr/user-config-only.json
	sed -i "s#WebPort#${WebPort}#" /root/shadowsocksr/user-config-only.json
	sed -i "s#WebPort#${WebPort}#" /root/shadowsocksr/user-config-only.json
	rm -rf /root/shadowsocksr/user-config.json
	mv /root/shadowsocksr/user-config-only.json /root/shadowsocksr/user-config.json
	yum -y install lsof lrzsz python-devel libffi-devel openssl-devel iptables
	systemctl stop firewalld.service
	systemctl disable firewalld.service
}

function install_ssr_only_compatible(){
	yum -y update
	yum -y install git 
	yum -y install python-setuptools && easy_install pip 
	yum -y groupinstall "Development Tools" 
	#512M chicks add 1 g of Swap
	dd if=/dev/zero of=/var/swap bs=1024 count=1048576
	mkswap /var/swap
	chmod 0644 /var/swap
	swapon /var/swap
	echo '/var/swap   swap   swap   default 0 0' >> /etc/fstab
	#自动选择下载节点
	GIT='raw.githubusercontent.com'
	LIB='download.libsodium.org'
	GIT_PING=`ping -c 1 -w 1 $GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	LIB_PING=`ping -c 1 -w 1 $LIB|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$GIT_PING $GIT" > ping.pl
	echo "$LIB_PING $LIB" >> ping.pl
	libAddr=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$libAddr" == "$GIT" ];then
		libAddr='https://raw.githubusercontent.com/ssrosx/script/master/libsodium-1.0.13.tar.gz'
	else
		libAddr='https://download.libsodium.org/libsodium/releases/libsodium-1.0.13.tar.gz'
	fi
	rm -f ping.pl
	wget --no-check-certificate $libAddr
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	yum -y install python-setuptools
	easy_install supervisor
    cd /root
	wget https://raw.githubusercontent.com/ssrosx/script/master/shadowsocksr.zip
	unzip shadowsocksr.zip
	cd shadowsocksr
	./initcfg.sh
	chmod 777 *
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/user-config-only_compatible.json
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/userapiconfig.py
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/ssrosx/script/master/usermysql.json
	sed -i "s#Userip#${Userip}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbuser#${Dbuser}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbport#${Dbport}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbpassword#${Dbpassword}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbname#${Dbname}#" /root/shadowsocksr/usermysql.json
	sed -i "s#UserNODE_ID#${UserNODE_ID}#" /root/shadowsocksr/usermysql.json
	#sed -i "s#ServerPort#${ServerPort}#" /root/shadowsocksr/user-config-only_compatible.json
	sed -i "s#PasswordValue#${PasswordValue}#" /root/shadowsocksr/user-config-only_compatible.json
	sed -i "s#WebPort#${WebPort}#" /root/shadowsocksr/user-config-only_compatible.json
	sed -i "s#WebPort#${WebPort}#" /root/shadowsocksr/user-config-only_compatible.json
	rm -rf /root/shadowsocksr/user-config.json
	mv /root/shadowsocksr/user-config-only_compatible.json /root/shadowsocksr/user-config.json
	yum -y install lsof lrzsz python-devel libffi-devel openssl-devel iptables
	systemctl stop firewalld.service
	systemctl disable firewalld.service
}

function install_node(){
	clear
	echo
    echo -e "\033[31m Add a node...\033[0m"
	echo
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	[ $(id -u) != "0" ] && { echo "错误: 您必须以root用户运行此脚本"; exit 1; }
	echo -e "如果你不知道，你可以直接回车。"
	echo -e "如果连接失败，请检查数据库远程访问是否打开。"
	read -p "请输入您的对接数据库IP(默认：本地IP地址):" Userip
	read -p "请输入数据库名称(默认：ssrosx):" Dbname
	read -p "请输入数据库端口(默认：3306):" Dbport
	read -p "请输入数据库帐户(默认：root):" Dbuser
	read -p "请输入数据库密码(默认：root):" Dbpassword
	read -p "请输入您的节点编号(默认：1):  " UserNODE_ID
	read -p "请输入SSR监听端口(默认：443):" ServerPort
	read -p "请输入SSR密码(默认：m):" PasswordValue
	read -p "请输入Web上返回的端口(默认：2333):" WebPort
	read -p "选择443/80端口监听单端口[需要兼容SS选：n，SSR下AppStore中APP下载失败](默认：y):" SSROnly
	read -p "是否兼容SS(默认：n):" Compatible
	ServerPort=${ServerPort:-"443"}
	PasswordValue=${PasswordValue:-"m"}
	WebPort=${WebPort:-"2333"}
	SSROnly=${SSROnly:-"y"}
	Compatible=${Compatible:-"n"}
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	Userip=${Userip:-"${IPAddress}"}
	Dbname=${Dbname:-"ssrosx"}
	Dbport=${Dbport:-"3306"}
	Dbuser=${Dbuser:-"root"}
	Dbpassword=${Dbpassword:-"root"}
	UserNODE_ID=${UserNODE_ID:-"1"}
	if [ "$SSROnly" == "y" ];then
		if [ "$Compatible" == "y" ];then
			install_ssr_only_compatible
		else
			install_ssr_only
		fi
	else
		if [ "$Compatible" == "y" ];then
			install_ssr_compatible
		else
			install_ssr
		fi
	fi
    # 启用supervisord
	echo_supervisord_conf > /etc/supervisord.conf
	sed -i '$a [program:ssr]\ncommand = python /root/shadowsocksr/server.py\nuser = root\nautostart = true\nautorestart = true' /etc/supervisord.conf
	supervisord
	#iptables
	iptables -F
	iptables -X  
	iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
	iptables-save >/etc/sysconfig/iptables
	iptables-save >/etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
	echo "/usr/bin/supervisord -c /etc/supervisord.conf" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
	touch /root/shadowsocksr/ssserver.log
	chmod 0777 /root/shadowsocksr/ssserver.log
	cd /home/wwwroot/default/storage/app/public/
	ln -S ssserver.log /root/shadowsocksr/ssserver.log
    chown www:www ssserver.log
	chmod 777 -R /home/wwwroot/default/storage/logs/
	clear
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "#                    成功添加节点请登录到前端站点查看               #"
	echo "#                     正在重新启动系统使节点生效……                 #"
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	reboot
}

function install_BBR(){
     wget --no-check-certificate https://raw.githubusercontent.com/ssrosx/script/master/bbr.sh&&chmod +x bbr.sh&&./bbr.sh
}

function install_RS(){
     wget -N --no-check-certificate https://raw.githubusercontent.com/ssrosx/script/master/serverspeeder.sh && bash serverspeeder.sh
}

function install_caddy_system(){
	clear
	yum install sudo -y
	read -p "请输入要添加的用户命(默认：ssrosx):" UserName
	UserName=${UserName:-"ssrosx"}
	adduser $UserName
	usermod -aG wheel $UserName
	chmod u+w /etc/sudoers
	echo "# Allow members of group sudo to execute any command" >> /etc/sudoers
	echo "%sudo   ALL=(ALL:ALL) ALL" >> /etc/sudoers
	chmod u-w /etc/sudoers
	systemctl restart sshd.service
	passwd  $UserName
	sleep 2
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	echo "#                    使用sudo：{$UserName}重新登录                   #"
	echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
	reboot
}

function install_sql_only(){
	yum install -y unzip zip git
	wget -c --no-check-certificate https://raw.githubusercontent.com/ssrosx/script/master/lnmp1.4.zip && unzip lnmp1.4.zip && rm -rf lnmp1.4.zip && cd lnmp1.4 && chmod +x install_db.sh && ./install_db.sh
	clear
	cd /root && wget https://raw.githubusercontent.com/ssrosx/ssrosx/master/sql/db.sql
read -p "数据库名字 sqlname(默认：ssrosx):" SqlName
read -p "数据库密码 sqlpasswd(默认：root):" SqlPassword
SqlName=${SqlName:-"ssrosx"}
SqlPassword=${SqlPassword:-"root"}
mysql -hlocalhost -uroot -p$SqlPassword --default-character-set=utf8mb4<<EOF
create database $SqlName;
use $SqlName;
source /root/db.sql;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$SqlPassword' WITH GRANT OPTION;
flush privileges;
EOF
}

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
ulimit -c 0
rm -rf ssrosx*
clear
check_system
sleep 2
echo "#############################################################################"
echo "#                      欢迎使用一键安装ssrosx和节点脚本。                 #"
echo "#                                                                     #"
echo "#     请选择您想要搭建的脚本:                                            #"
echo "#                                                                     #"
echo "# 1.  安装ssrosx前端面板(无节点-带mysql-需选mysql版本)                    #"
echo "# 2.  安装ssrosx独立前端面板(无节点-无mysql-mysql选：0)                   #"                                                                   #"
echo "# 3.  安装独立数据库(只需选mysql版本，其余都选：0)                         #" 
echo "# 4.  搭建Caddy Web Server环境                                         #"
echo "# 5.  安装ssrosx节点(可单独搭建)                                        #"
echo "# 6.  搭建BBR加速                                                      #"
echo "# 7.  搭建锐速加速                                                      #"
echo "# 8.  ssrosx升级脚本                                                   #"
echo "# 9.  日志分析（仅支持单机单节点）                                        #"
echo "# 10. 更改数据库密码                                                    #" 
echo "#                                                                     #"
echo "#    PS:建议请先搭建加速再搭建ssrosx相关。                                #"
echo "#    此脚本仅适用于Centos 7. X 64位 系统                                 #"
echo "#############################################################################"
echo
read num
if [[ $num == "1" ]]
then
install_ssrosx_sql
elif [[ $num == "2" ]]
then
install_ssrosx_nosql
elif [[ $num == "3" ]]
then
install_sql_only
elif [[ $num == "4" ]]
then
install_caddy_system
elif [[ $num == "5" ]]
then
install_node
elif [[ $num == "6" ]]
then
install_BBR
elif [[ $num == "7" ]]
then
install_RS
elif [[ $num == "8" ]]
then
cd /home/wwwroot/default/
chmod a+x update.sh && sh update.sh
elif [[ $num == "9" ]]
then
install_log
elif [[ $num == "10" ]]
then
change_password
else 
echo '输入错误';
exit 0;
fi;
