#!/usr/bin/env bash



# Clean journal logs
journalctl --vacuum-size=5M
journalctl --verify
sed -i -e "s/#SystemMaxUse=/SystemMaxUse=5M/g" /etc/systemd/journald.conf
sed -i -e "s/#SystemMaxFileSize=/SystemMaxFileSize=1M/g" /etc/systemd/journald.conf
sed -i -e "s/#SystemMaxFiles=100/SystemMaxFiles=5/g" /etc/systemd/journald.conf
systemctl daemon-reload
systemctl restart systemd-journald


#DISABLE AUTO-UPDATE for Ubuntu 24.04
apt remove unattended-upgrades -y


apt update -y
apt install curl net-tools iftop nload jq -y
apt autoremove --purge snapd -y


# IP VPS
IPVPS=`ip addr show $ETH | grep global | sed -En -e 's/.*inet ([0-9.]+).*/\1/p' | head -n1`


#RANDOM MARZ PORT
RANDPORT=`echo $(( ( RANDOM % 65535 )  + 1025 ))`


#RANDOM MARZ PASSWORD
PASSMARZBAN=`openssl rand -hex 16`




# Download env and fix pass.
cd /root/
curl -sL "https://raw.githubusercontent.com/RoganovDA/MarzbanScript/refs/heads/main/.env.example_0.8.4" -o .env.example
cp -r .env.example env_marzban
sed -i -e '1iSUDO_PASSWORD = "'$PASSMARZBAN'"  ' env_marzban
sed -i -e '1iSUDO_USERNAME = "admin1"  ' env_marzban



# nginx intall
dpkg -P nginx nginx-common
apt install nginx -y

# proxy config to localhost:8000/dashboard/login
curl -sL "https://raw.githubusercontent.com/RoganovDA/MarzbanScript/refs/heads/main/nginx_proxy_1.conf" -o /etc/nginx/sites-enabled/default
sed -i -e 's/5555/'$RANDPORT'/1' /etc/nginx/sites-enabled/default
systemctl restart nginx



# install marzban 0.8.x  with fixed .env
bash -c "$(curl -sL https://raw.githubusercontent.com/RoganovDA/MarzbanScript/refs/heads/main/marzban4.sh )" @ install v0.8.4



# 40 sec waiting for start marzban
sleep 40




# CURL > 8.3.0
# GET TOKEN

TOKEN_RESPONSE=$(curl -s -X POST --variable passmarban=$PASSMARZBAN http://$IPVPS:$RANDPORT/api/admin/token -H 'accept: application/json' -H 'Content-Type: application/x-www-form-urlencoded' -d username=admin1 --expand-data 'password={{passmarban}}' )
#echo $TOKEN_RESPONSE

TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])" )
#echo $TOKEN




# CREATE 10 VLESS TCP-REALITY XTLS

counter=1
while [ $counter -le 10 ]
do


curl -s -X  'POST' --variable counter1=$counter http://$IPVPS:$RANDPORT/api/user -H 'accept: application/json'   -H "Authorization: Bearer "${TOKEN}""   -H 'Content-Type: application/json'   --expand-data '{
  "username": "user{{counter1}}",
  "proxies": {
    "vless": {"flow": "xtls-rprx-vision"}
  },
  "inbounds": {

    "vless": [
      "VLESS TCP REALITY"
    ]
  },
  "expire": 0,
  "data_limit": 0,
  "data_limit_reset_strategy": "no_reset",
  "status": "active",
  "note": "",
  "on_hold_timeout": "2023-11-03T20:30:00",
  "on_hold_expire_duration": 0
}'


CONFIGS=$(curl -s -X 'GET'  http://$IPVPS:$RANDPORT/api/user/user$counter -H 'accept: application/json'   -H "Authorization: Bearer "${TOKEN}"")
CONFIGS1=$(echo "$CONFIGS" | jq '.links[0]')
echo $CONFIGS1 >> /root/configs_10.txt
echo "" >> /root/configs_10.txt



((counter++))

done





echo ""
echo ""
echo ""
echo "------------------------------------------"
echo "WEB interface Marzban IP: http://"$IPVPS":"$RANDPORT"/dashboard/login"
echo "WEB interface Marzban login: admin1"
echo "WEB interface Marzban password:" $PASSMARZBAN
echo "------------------------------------------"
echo "ALL configs:"
sed -e 's/[""]//g' /root/configs_10.txt



