# This file still has issues to be sorted.
#!/bin/bash

# This script will download mysql version as specified in `MYSQL_RELEASE`
# Aim to install latest image of mysql release on machine of amazon linux AMI.
# Guidance: https://dev.mysql.com/doc/refman/5.7/en/linux-installation-yum-repo.html

MYSQL_RELEASE=mysql57-community-release-el6-11.noarch.rpm
MYSQL_RELEASE_URL="https://dev.mysql.com/get/${MYSQL_RELEASE}"
MYSQL_SERVICE=mysqld
MYSQL_LOG_FILE=/var/log/${MYSQL_SERVICE}.log

exitError() {
    echo "Error: $1" >&2
    exit 1
}

if [[ $EUID -ne 0 ]]; then # we can compare directly with this syntax.
    echo "Please run as root/sudo"
    exit 1
fi

# download the mysql release package from url
echo "Downloading mysql release package from specified url: $MYSQL_RELEASE_URL..."
wget -O $MYSQL_RELEASE $MYSQL_RELEASE_URL || exitError "Could not fetch required release of mysql: ($MYSQL_RELEASE_URL)"

# The installation command adds the MySQL Yum repository to your system's repository list
# and downloads the GnuPG key to check the integrity of the software packages.
echo "Adding mysql yum repo in the system repo list..."
yum localinstall -y $MYSQL_RELEASE || exitError "Unable to install mysql release ($MYSQL_RELEASE) locally with yum"

# check that the MySQL Yum repository has been successfully added or not
echo "Checking that mysql yum repo has been added successfully..."
yum repolist enabled | grep "mysql.*-community.*" || exitError "Mysql release package ($MYSQL_RELEASE) has not been added in repolist"

# check whather release subrepo is enabled (at least one of them should be enabled)
echo "Checking that at least one subrepository is enabled for one release..."
yum repolist enabled | grep mysql || exitError "At least one subrepository should be enabled for one release series at any time."

# now install mysql-community-server
echo "Installing mysql-community-server..."
yum install -y mysql-community-server || exitError "Unable to install mysql mysql-community-server"

# # set proper sql-mode=ALLOW_INVALID_DATES with just appending 
# (or maybe better include it right under [mysqld] section with some script!)
# if cat /etc/my.cnf | grep "sql-mode"; then
#     echo "sql-mode already has been set !!!"
# else
#     echo "Setting up sql-mode in /etc/my.cnf..."
#     echo 'sql-mode="ALLOW_INVALID_DATES"' >> /etc/my.cnf || exitError "Unable to set sql-mode in /etc/my.cnf file"
#     echo "sql-mode has been set to ALLOW_INVALID_DATES in /etc/my.cnf"
# fi

# after installation, start the server
echo "Starting mysql service..."
service $MYSQL_SERVICE start || exitError "Could not start mysql service"

# check whether service is running or not
echo "Checking status of mysql service..."
service $MYSQL_SERVICE status || exitError "Mysql service is not running"

echo "Setting up mysql as in startup service..."
chkconfig mysqld on

# get auto generated password from log file
echo "extracting password from log file: ${MYSQL_LOG_FILE}..."
MYSQL_PWD=$(grep -oP '(?<=A temporary password is generated for root@localhost: )[^ ]+' ${MYSQL_LOG_FILE})
# echo "Auto generated password is: ${MYSQL_PWD}"

# install expect program to interact with mysql program
yum install -y expect

MYSQL_UPDATE=$(expect -c "
set timeout 5
spawn mysql -u root -p
expect \"Enter password: \"
send \"${MYSQL_PWD}\r\"
expect \"mysql>\"
send \"ALTER USER 'root'@'localhost' IDENTIFIED BY 'MySQL!57';\r\"
expect \"mysql>\"
send \"uninstall plugin validate_password;\r\"
expect \"mysql>\"
send \"ALTER USER 'root'@'localhost' IDENTIFIED BY '';\r\"
expect \"mysql>\"
send \"CREATE USER 'ec2-user'@'localhost';\r\"
expect \"mysql>\"
send \"quit;\r\"
expect eof
")

echo "$MYSQL_UPDATE"

# remove expect program
yum remove -y expect