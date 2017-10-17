#!/bin/bash
#DVWA-insta Generate multiple installation of DVWA
#Need root to execute

#number start instan to deploy
START=1

#Total instan to deploy
TOTAL=30

#name insta
UNAMEBASE="insta"

#Directory Web
DIRECTORYWEB="/var/www/html/"

#php.ini file
PHPINI="/etc/php/7.0/apache2/php.ini"

BTICK='`'
SQL=''

INSTALL="dvwa"

usage="Program to install multiple DVWA

where:
    -h show this help text
    -s number start instan to deploy
    -t total instances to deploy
    -b name base of instances
    -d web directory to install DVWA
    -p php.ini file to enabled url include
    -i to install apache use all"


#Check if root
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi


while getopts s:t:b:d:p:i:h option
do
 case "${option}"
 in
 s) START=${OPTARG};;
 t) TOTAL=${OPTARG};;
 b) UNAMEBASE=${OPTARG};;
 d) DIRECTORYWEB=${OPTARG};;
 p) PHPINI=${OPTARG};;
 i) INSTALL=$OPTARG;;
 h) echo "$usage"
    exit
    ;;
 esac
done


if [ "$INSTALL" == "all" ]
	then
	echo "Install glamp..."
	#Update an upgrade system
	sudo apt-get update
	sudo apt-get upgrade

	#Install apache, php, mysql, unzip
	sudo apt-get install apache2 libapache2-mod-php7.0 php7.0 mysql-server php7.0-mysql phpmyadmin unzip

fi

echo "Download DVWA..."
#Download DVWA
wget https://github.com/ethicalhack3r/DVWA/archive/master.zip

#Unzip DVWA
unzip master.zip

echo "Generating instances..."
for ((i=$START;i<$TOTAL;i++))
do
        UNAME="$UNAMEBASE$i"
	#Generate N Instances of DVWA
	cp -R DVWA-master/ "$UNAME"

	#change user database
	sed -i "s/root/$UNAME/g"  "$UNAME/config/config.inc.php.dist"

	#Change name database
	sed -i "s/dvwa/$UNAME/g"  "$UNAME/config/config.inc.php.dist"
	
	#change password database
	sed -i "s/p@ssw0rd/$UNAME/g"  "$UNAME/config/config.inc.php.dist"

	#change name config
	mv "$UNAME/config/config.inc.php.dist" "$UNAME/config/config.inc.php"	

	#move instan to website
	mv $UNAME $DIRECTORYWEB

	#change permisions
	chmod 775 "$DIRECTORYWEB$UNAME/hackable/uploads/"

	#change user execute DVWA
	chown -R www-data:www-data "$DIRECTORYWEB$UNAME"


        Q1="CREATE DATABASE IF NOT EXISTS $UNAME;"
        Q2="GRANT ALL ON ${BTICK}$UNAME${BTICK}.* TO '$UNAME'@'localhost' IDENTIFIED BY '$UNAME';"
	SQL="$SQL${Q1}${Q2}"
done

SQL="$SQL FLUSH PRIVILEGES;"

echo "Generating database..."

mysql -u root -p -e "$SQL"

echo "Delete default index.html"

rm "$DIRECTORYWEBindex.html"

echo "Enabled url include"

sed -i "s/allow_url_include = Off/allow_url_include = On/g"  "$PHPINI"

echo "Reload apache"

service apache2 reload

echo "Now can use DVWA Happy Hacking" 
