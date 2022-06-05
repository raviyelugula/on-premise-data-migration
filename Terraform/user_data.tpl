#!/bin/bash
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 && 
wget http://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm &&
sudo yum localinstall mysql57-community-release-el7-8.noarch.rpm -y &&
sudo yum install mysql-community-server -y &&
sudo service mysqld start &&
sleep 60s && 
pswd="$(sudo grep 'temporary password' /var/log/mysqld.log | cut -d ':' -f4)" &&
mysql -uroot -p"$(echo$pswd)" --connect-expired-password -e"ALTER USER 'root'@'localhost' IDENTIFIED BY 'root123@PSWD';"
echo 'done!!!'
