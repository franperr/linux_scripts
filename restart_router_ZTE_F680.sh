#!/bin/bash
IP_ROUTER=192.168.1.1
# Account used in the router web interface (http://192.168.1.1
USER=xxx
PASSWORD=xxx

# Retrieving login form
wget --user-agent=Mozilla/5.0 \
     --save-cookies ./cookie.txt \
     --keep-session-cookies \
     -O /tmp/router_index.html \
     http://$IP_ROUTER/
LOGIN_TOKEN=$(cat /tmp/router_index.html | grep "(\"Frm_Logintoken" | cut -d= -f 2 | sed "s/[^0-9]//g")
[[ -z "$LOGIN_TOKEN" ]] && { echo "LOGIN_TOKEN is empty ! Something went wrong..." ; exit; }
echo "LOGIN_TOKEN is $LOGIN_TOKEN"

# Login
wget --user-agent=Mozilla/5.0 \
     --header "Referer: http://$IP_ROUTER/" \
     --load-cookies ./cookie.txt \
     --save-cookies ./cookie.txt \
     --keep-session-cookies \
     --post-data "frashnum=&action=login&Frm_Logintoken=$LOGIN_TOKEN&port=&Username=$USER&Password=$PASSWORD" \
     -O /tmp/router_index_log_in.html \
     --quiet \
     http://$IP_ROUTER/

# Retrieving reboot form
wget --user-agent=Mozilla/5.0 \
     --header "Referer: http://$IP_ROUTER/" \
     --load-cookies ./cookie.txt \
     --save-cookies ./cookie.txt \
     --keep-session-cookies \
     --quiet \
     -O /tmp/router_reboot_form.html \
     http://$IP_ROUTER/getpage.gch?pid=1002\&nextpage=manager_dev_conf_t.gch

SESSION_TOKEN=$(cat /tmp/router_reboot_form.html | grep "var session_token" | cut -d= -f2 | sed "s/[^0-9]//g")
ROUTER_PID=$(cat /tmp/router_reboot_form.html | grep "menu_subitems\['mmManager'\]\['smSysMgr'\]\['ssmSysMgr'\]\['URL'\]" | cut -d= -f3 | sed "s/[^0-9]//g")
[[ -z "$SESSION_TOKEN" ]] && { echo "SESSION_TOKEN is empty ! Something went wrong..." ; exit; }
[[ -z "$ROUTER_PID" ]] && { echo "ROUTER_PID is empty ! Something went wrong..." ; exit; }
echo "SESSION_TOKEN is $SESSION_TOKEN"
echo "ROUTER_PID is $ROUTER_PID"

echo "Rebooting..."

wget --user-agent=Mozilla/5.0 \
     --header "Referer: http://$IP_ROUTER/getpage.gch?pid=$ROUTER_PID&nextpage=manager_dev_conf_t.gch" \
     --load-cookies ./cookie.txt \
     --save-cookies ./cookie.txt \
     --keep-session-cookies \
     --quiet \
     --post-data "IF_ACTION=devrestart&IF_ERRORSTR=SUCC&IF_ERRORPARAM=SUCC&IF_ERRORTYPE=-1&flag=1&_SESSION_TOKEN=$SESSION_TOKEN" \
     --timeout=10 \
     --delete-after \
     http://$IP_ROUTER/getpage.gch?pid=$ROUTER_PID\&nextpage=manager_dev_conf_t.gch


echo "It should be rebooting now"
