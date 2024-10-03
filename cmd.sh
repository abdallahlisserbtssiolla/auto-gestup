#!/bin/bash

# Message de télémétrie
echo "En installant cette application, vous acceptez l'activation de la télémétrie par défaut."

# Installation via script
apt install curl -y && curl -s https://gestsup.fr/install.deb12.sh | bash

# Installation manuelle
echo "Installation manuelle de Gestsup"

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y && apt dist-upgrade -y

# Installation des prérequis
echo "Installation des prérequis..."
apt install apache2 mariadb-server unzip curl ntp cron -y

# Installation de PHP
echo "Installation de PHP..."
apt install php libapache2-mod-php -y
apt install php-{common,curl,gd,imap,intl,ldap,mbstring,mysql,xml,zip} -y

# Création de l'utilisateur base de données
echo "Création de l'utilisateur de la base de données..."
mariadb -u root <<EOF
CREATE USER 'gestsup'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'gestsup'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Sécurisation MariaDB
echo "Sécurisation de MariaDB..."
mysql_secure_installation

# Modification des paramètres PHP
echo "Modification des paramètres PHP..."
sed -i "s/max_execution_time = .*/max_execution_time = 480/" /etc/php/8.2/apache2/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.2/apache2/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 8M/" /etc/php/8.2/apache2/php.ini
sed -i "s/;date.timezone =.*/date.timezone = Europe\/Paris/" /etc/php/8.2/apache2/php.ini

# Modification des paramètres MariaDB
echo "Modification des paramètres MariaDB..."
sed -i "/\[mysqld\]/a innodb_buffer_pool_size = 1G" /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i "/\[mysqld\]/a skip-name-resolve" /etc/mysql/mariadb.conf.d/50-server.cnf



# Extraire les fichiers
echo "Extraction des fichiers..."
unzip /var/www/html/gestsup_3.2.50.zip -d /var/www/html

# Suppression des fichiers inutiles
echo "Suppression des fichiers inutiles..."
rm /var/www/html/gestsup_3.2.50.zip
rm /var/www/html/index.html

# Modification des droits
echo "Modification des droits pour l'installation..."
adduser gestsup --ingroup www-data --disabled-password
chown -R gestsup:www-data /var/www/html/
find /var/www/html/ -type d -exec chmod 750 {} \;
find /var/www/html/ -type f -exec chmod 640 {} \;
chmod 770 -R /var/www/html/upload
chmod 770 -R /var/www/html/images/model
chmod 770 -R /var/www/html/backup
chmod 770 -R /var/www/html/_SQL
chmod 660 /var/www/html/connect.php

# Redémarrage du serveur
echo "Redémarrage du serveur..."
reboot
