#!/bin/bash
PASS=$(pwgen -s 40 1)
DBNUSR=$(pwgen -s 12 1)

mysql -uroot <<MYSQL_SCRIPT
CREATE DATABASE $DBNUSR;
CREATE USER '$DBNUSR'@'localhost' IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON $DBNUSR.* TO '$DBNUSR'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "Databse connection info"
echo "Username:   $DBNUSR"
echo "Password:   $PASS"
echo "Database:   $DBNUSR"
