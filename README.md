## Script
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
