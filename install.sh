#!/usr/bin/env bash

# This script is intended for automatic installation in the provided virtual machine.

# Read database configuration parameters
echo "Please provide the database configuration parameters..."
read -p "DB host [localhost]: " dbHost
dbHost=${dbHost:-localhost}
read -p "DB port [3306]: " dbPort
dbPort=${dbHost:-3306}
read -p "DB root password [Gibz1234]: " dbRootPassword
dbRootPassword=${dbHost:-Gibz1234}
read -p "DB database name [quiz]: " dbDatabaseName
dbDatabaseName=${dbHost:-quiz}
read -p "DB username [quizmaster]: " dbUsername
dbUsername=${dbHost:-quizmaster}
read -p "DB password [qu!z_m150]: " dbPassword
dbPassword=${dbHost:-qu!z_m150}

declare -A dbConfiguration
dbConfiguration=(
    ['__DB_HOST__']=${dbHost}
    ['__DB_PORT__']=${dbPort}
    ['__DB_DATABASE_NAME__']=${dbDatabaseName}
    ['__DB_USERNAME__']=${dbUsername}
    ['__DB_PASSWORD__']=${dbPassword}
)

# Change to quiz directory
cd /var/www/html/m150/quiz

# Use composer to install dependencies
sudo composer install

# Build frontend using npm
sudo npm install

# Setup the database
mysql -user=root -password=${dbRootPassword} < /var/www/html/m150/initDb.sql
mysql -user=quizmaster -password=${dbPassword} quiz < /var/www/html/m150/seedDb.sql

# Prepare the laravel framework
sudo cp .env.example .env

for i in "${!dbConfiguration[@]}"
do
    search=${i}
    replace=${dbConfiguration[$i]}
    sed -i "s/${search}/${replace}/g" .env
done

# Generate application keys
sudo php artisan key:generate
sudo php artisan passport:keys

# Fix file permissions
# Assign 'apache' as user and user group recursively to the web root directory
sudo chown -R apache:apache /var/www/html
# Adjust permissions for some directories (recursively)
sudo chmod -R 0775 /var/www/html/m150/quiz/storage/ /var/www/html/m150/quiz/bootstrap/cache/

# Restart apache webserver
sudo systemctl restart httpd

