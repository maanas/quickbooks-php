#!/usr/bin/env bash

# Vagrant Apache-php Development Box provision

cat << EOF | sudo tee -a /etc/motd.tail
***************************************

Welcome to Apache PHP Development Box provision

***************************************
EOF

### Fix for mac issue on UTF-8
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

### Common Package Install
echo "Updating Repo"
sudo apt-get update
echo "Installing Essential Packages"
sudo apt-get install -y python-software-properties build-essential > /dev/null
echo "Installing curl vim zip unzip python pip"
sudo apt-get install -y curl vim zip unzip python-pip git tree htop > /dev/null

### Apache Install
echo "Installing Apache"
sudo apt-get install -y apache2 > /dev/null
echo "Restart Apache"
sudo service apache2 restart


### PHP Install
echo "Installing PHP"
sudo apt-get install -y php5 php5-common php5-sqlite php5-gd libapache2-mod-php5 php5-cli php5-curl php-soap php5-imagick php5-gd php5-mcrypt php5-mysql php5-xmlrpc php5-xsl php5-xdebug > /dev/null
echo "Restart Apache"
sudo service apache2 restart


### Install Mysql
echo "Installing Mysql"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password vagrant"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password vagrant"
sudo apt-get install -y mysql-server-5.5
echo "Allowing mysql access from any IP"
sudo sed -i "s/^bind-address/#bind-address/" /etc/mysql/my.cnf
echo "Restart Mysql"
sudo service mysql restart

# Remap the apache web directory to vagrant folder
echo "Remapping apache directories"
sudo sed -i 's|/var/www|/vagrant|g' /etc/apache2/apache2.conf
sudo sed -i 's|/var/www/html|/vagrant/www|g' /etc/apache2/sites-available/000-default.conf
sudo sed -i 's|/var/www/html|/vagrant/www|g' /etc/apache2/sites-available/default-ssl.conf

# Change user and group for apache
echo "Changing user and group for apache"
sudo sed -i '/APACHE_RUN_USER/d' /etc/apache2/envvars
sudo sed -i '/APACHE_RUN_GROUP/d' /etc/apache2/envvars

sudo cat >> /etc/apache2/envvars <<'EOF'

# Apache user and group
export APACHE_RUN_USER=vagrant
export APACHE_RUN_GROUP=vagrant
EOF

# Fix permissions
if [ -d /var/lock/apache2 ]
	then
		sudo chown -R vagrant:vagrant /var/lock/apache2
fi

# Enable rewrites
sudo a2enmod rewrite

# Some changes to php.ini
echo "Changing php.ini to enable debug logs"
sudo sed -i 's/display_errors = Off/display_errors = On/g' /etc/php5/apache2/php.ini
sudo sed -i 's/display_startup_errors = Off/display_startup_errors = On/g' /etc/php5/apache2/php.ini
sudo sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED/error_reporting = E_ALL/g' /etc/php5/apache2/php.ini
sudo sed -i 's/track_errors = Off/track_errors = On/g' /etc/php5/apache2/php.ini
sudo sed -i 's/html_errors = Off/html_errors = On/g' /etc/php5/apache2/php.ini

# Clean up
sudo apt-get clean

# Restart services
echo "Restarting Apache"
sudo service apache2 restart

# Install composer
echo "Installing composer"
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer


### echo success message
echo "You've been provisioned"