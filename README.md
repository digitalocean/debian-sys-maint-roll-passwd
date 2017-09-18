## Script

This script currently runs on:
- Ubuntu 14.04
- Ubuntu 16.04
- Ubuntu 17.10
- Debian 7
- Debian 8

Debian 9 is not affected by this particular issue.

Running this script on end-of-life distributions such as Ubuntu 12.04 will fail. You are strongly urged to upgrade any out of life distributions.

To apply the fix, simply run:

```
wget -O fix.sh https://raw.githubusercontent.com/digitalocean/debian-sys-maint-roll-passwd/master/fix.sh
bash fix.sh
```

### Explanation of the fix

The fix:
* reads the current password for the `debian-sys-maint` user
* updates `/etc/mysql/debian.cnf` to change the `debian-sys-maint` password to a random value.
* updates the MySQL `debian-sys-maint` database password
* restarts MySQL
