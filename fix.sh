#!/bin/bash

if [ "${UID}" -ne 0 ]; then
    cat <<EOM
This script must be run as root. Please run:
    sudo bash $(readlink -f ${0})
EOM
fi

log_f="/root/mysql-fix-$(date +%s).log"
failed() {
    cat <<EOM
==============================================================

WARNING: your system may still be affected.

==============================================================

If you are running this on a DigitalOcean Droplet, please file
a ticket with DigitalOcean support and include include
${log_f} if you require further assistance.

==============================================================

EOM
    exit 1
}

cat <<EOM

This script changes the MySQL system maintance user used by
packaging scripts to maintain MySQL during upgrades.

This process entails:
- reading the current password
- generating a new password
- updating the password in /etc/mysql/debian.cnf
- updating the password in MySQL
- restarting MySQL

EOM

if [ ! -f /etc/mysql/debian.cnf ]; then
    echo "This system is not affected."
    exit 0
fi


# Setup logging
exec > >(tee ${log_f}) 2>&1
echo "Logging to ${log_f}"


# Get the current username/password for the user
dsm_user="$(awk '/user/{print $NF; exit;}' /etc/mysql/debian.cnf)"
old_dsm_pass="$(awk '/password/{print $NF; exit;}' /etc/mysql/debian.cnf)"

# Error checking
dsm_user="${dsm_user:?Failed to find debian-sys-maint user in /etc/mysql/debian.cfg. This system  is not likely affected.}"
old_dsm_pass="${old_dsm_pass:?Failed to find the current password for ${dsm_user}. Unable to automatically fix.}"

# Set the new password
new_dsm_pass="$(openssl rand -hex 24)"

cname="$(lsb_release -c -s)"
cname="${cname:?unable to determine Debian version name. If this is not a Debian/Ubuntu system, it is not affected.}"

if [ "${cname}" == "stretch" ]; then
    echo "Debian 9 is not affected by the issue."
    exit 0
fi

case ${cname} in
  wheezy|jessie)
    mysql_restart_cmd="/usr/sbin/service mysql restart";;
  trusty)
    mysql_restart_cmd="/sbin/restart mysql";;
  *)
    mysql_restart_cmd="/bin/systemctl restart mysql.service";;
esac

case ${cname} in
  trusty|wheezy|jessie|stretch)
    passwd_reset_query="use mysql; update user set password=password('${new_dsm_pass}') where user='${dsm_user}'; GRANT ALL PRIVILEGES ON *.* TO '${dsm_user}'@'localhost' IDENTIFIED BY '${new_dsm_pass}'";;
  *)
    passwd_reset_query="ALTER USER '${dsm_user}'@'localhost' IDENTIFIED BY '${new_dsm_pass}'";;
esac

trap "failed" EXIT

# Update password
echo "Updating ${dsm_user} with new password"
mysql -u${dsm_user} -p${old_dsm_pass} -e "${passwd_reset_query};"

# Re-write the configuration file
cat > /etc/mysql/debian.cnf <<EOM
# Automatically generated for Debian scripts. DO NOT TOUCH!
# This was updated via a 1-Click HotFix on $(date -R)
[client]
host     = localhost
user     = ${dsm_user}
password = ${new_dsm_pass}
socket   = /var/run/mysqld/mysqld.sock
[mysql_upgrade]
host     = localhost
user     = ${dsm_user}
password = ${new_dsm_pass}
socket   = /var/run/mysqld/mysqld.sock
EOM

${mysql_restart_cmd}

trap - EXIT ERR

cat <<EOM

Done. This system is no longer affected.

EOM
