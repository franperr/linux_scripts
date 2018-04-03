#!/bin/bash

# This file works with the Livebox Fibra made by Arcadyan

IP_LIVEBOX=192.168.1.1
USER=admin
PASSMD5=xxxxx # We need the password MD5 hash, not the password in plain text
# To obtain PASSMD5, log in the livebox interface and then open http://IP_LIVEBOX/cgi/cgi_system.js
# In this file, find the value of http_pwd1 . It's the value you need.

# Login
wget --user-agent=Mozilla/5.0 --quiet \
     --header "Cookie: defpg=status%2Ehtm; menu_sel=0; menu_adv=0; urn=" \
     --keep-session-cookies \
     --post-data "GO=&usr=$USER&pws=$PASSMD5" \
     --delete-after \
     http://$IP_LIVEBOX/login.cgi

# Getting status (to get urn value)
wget --user-agent=Mozilla/5.0 --quiet \
     --no-cookies \
     --header "Referer: http://$IP_LIVEBOX/index.htm" \
     --header "Cookie: defpg=status%2Ehtm; menu_sel=0; menu_adv=0; urn=" \
     --keep-session-cookies \
     http://$IP_LIVEBOX/status.htm \
     -O /tmp/livebox_status.htm

# Saving URN
URN=$(cat /tmp/livebox_status.htm | grep "new_urn =" | cut -d= -f2 | sed "s/[^0-9^a-f]//g")
#rm /tmp/livebox_status.htm

# Getting CSRF_TOKEN value
wget --user-agent=Mozilla/5.0 --quiet \
     --no-cookies \
     --header "Referer: http://$IP_LIVEBOX/index.htm" \
     --header "Cookie: defpg=status%2Ehtm; menu_sel=0; menu_adv=0; urn=$URN" \
     --keep-session-cookies \
     http://$IP_LIVEBOX/support_restart.htm \
     -O /tmp/livebox_support_restart.htm
CSRF_TOKEN=$(cat /tmp/livebox_support_restart.htm | grep "pi" | cut -d\" -f4)

# Getting SYS_REBOOT ID value
wget --user-agent=Mozilla/5.0 --quiet \
     --no-cookies \
     --header "Referer: http://$IP_LIVEBOX/index.htm" \
     --header "Cookie: defpg=status%2Ehtm; menu_sel=0; menu_adv=0; urn=$URN" \
     --keep-session-cookies \
     http://$IP_LIVEBOX/cgi/cgi_system.js \
     -O /tmp/livebox_cgi_system.js
SYS_REBOOT_ID=$(cat /tmp/livebox_cgi_system.js | grep sys_reboot | cut -d, -f2)


[[ -z "$URN" ]] && { echo "URN is empty ! Something went wrong..." ; exit; }
[[ -z "$CSRF_TOKEN" ]] && { echo "CSRF_TOKEN is empty ! Something went wrong..." ; exit; }
[[ -z "$SYS_REBOOT_ID" ]] && { echo "SYS_REBOOT_ID is empty ! Something went wrong..." ; exit; }

echo "URN is $URN"
echo "CSRF_TOKEN is $CSRF_TOKEN"
echo "SYS_REBOOT_ID is $SYS_REBOOT_ID"
echo "Rebooting..."

# Rebooting
wget --user-agent=Mozilla/5.0 --quiet \
     --no-cookies \
     --header "Referer: http://$IP_LIVEBOX/support_restart.htm" \
     --header "Cookie: defpg=status%2Ehtm; menu_sel=0; menu_adv=0; urn=$URN" \
     --post-data "CMD=&GO=support_restart.htm&SET0=$SYS_REBOOT_ID%3DREBOOT&pi=$CSRF_TOKEN" \
     --keep-session-cookies \
     --timeout=10 \
     --delete-after \
     http://$IP_LIVEBOX/apply.cgi

echo "It should be rebooting now"
