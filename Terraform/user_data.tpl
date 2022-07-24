#!/bin/bash
touch py-requirements.txt
cat >./py-requirements.txt <<EOF
pandas==1.3.5
tqdm==4.64.0
mysql-connector==2.2.9
argparse==1.4.0
sqlalchemy==1.4.37
pymysql==1.0.2
EOF
sudo pip3 install -r py-requirements.txt
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 && 
wget http://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm &&
sudo yum localinstall mysql57-community-release-el7-8.noarch.rpm -y &&
sudo yum install mysql-community-server -y &&
sudo service mysqld start &&
sleep 60s && 
pswd="$(sudo grep 'temporary password' /var/log/mysqld.log | cut -d ':' -f4)" &&
mysql -uroot -p"$(echo$pswd)" --connect-expired-password -e"ALTER USER 'root'@'localhost' IDENTIFIED BY 'root123@PSWD';"
mysql -uroot -proot123@PSWD -e"CREATE USER 'ravi'@'%' IDENTIFIED BY 'ravi123@PSWD';"
mysql -uroot -proot123@PSWD -e"GRANT ALL PRIVILEGES ON *.* to ravi@'%' IDENTIFIED BY 'ravi123@PSWD' WITH GRANT OPTION;"
mysql -uroot -proot123@PSWD -e"create database onpremise;"
sudo echo "bind-address=0.0.0.0" >> /etc/my.cnf &&
echo 'updated'
sudo service mysqld restart 
echo 'done!!!'

