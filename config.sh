#!/bin/bash

echo " "
echo "=================================================="
echo "$(date): config.sh started"
echo "=================================================="
echo " "

# Download configuration files from github
echo "$(date): Download configuration files from github"
svn checkout $GIT_URL/trunk/config $CONFIG_PATH
# chown -R root:root $CONFIG_PATH
# chmod -R 644 $CONFIG_PATH

# Start load configs
if [ -s $CONFIG_PATH/config.ini ]; then
    # Load config from config.ini
    echo "$(date): Load config from config.ini"
    sed -i -e "s/\r//g" $CONFIG_PATH/config.ini
    . $CONFIG_PATH/config.ini && export $(grep -E ^[a-zA-Z] $CONFIG_PATH/config.ini | cut -d= -f1)
else
    # If config.ini not downloaded - create empty
    echo "$(date): config.ini not downloaded, create empty"
    touch $CONFIG_PATH/config.ini
    tail -c1 $CONFIG_PATH/config.ini | read -r _ || echo >> $CONFIG_PATH/config.ini
fi


# Check vars, set defaults in config.ini ==========================
echo "$(date): Check vars, set defaults..."

# PRIVOXY_ADDRESS_PORT
[ -z "$PRIVOXY_ADDRESS_PORT" ] && export PRIVOXY_ADDRESS_PORT=$(grep -o -s -E "^listen-address [0-9\.:]+" $CONFIG_PATH/config | cut -d ' ' -f 2)
[ -z "$PRIVOXY_ADDRESS_PORT" ] && export PRIVOXY_ADDRESS_PORT=:8118
sed -i "/^PRIVOXY_ADDRESS_PORT=/{h;s/=.*/=${PRIVOXY_ADDRESS_PORT}/};\${x;/^$/{s//PRIVOXY_ADDRESS_PORT=${PRIVOXY_ADDRESS_PORT}/;H};x}" $CONFIG_PATH/config.ini
sed -i "/^listen-address /{h;s/ .*/ ${PRIVOXY_ADDRESS_PORT}/};\${x;/^$/{s//listen-address ${PRIVOXY_ADDRESS_PORT}/;H};x}" $CONFIG_PATH/config

# FORWARD_ADDRESS_PORT
[ -z "$FORWARD_ADDRESS_PORT" ] && export FORWARD_ADDRESS_PORT=$(grep -o -s -E "forward-socks5 [0-9\.:]+" $CONFIG_PATH/user.action | cut -d ' ' -f 2)
[ -z "$FORWARD_ADDRESS_PORT" ] && export FORWARD_ADDRESS_PORT=$(grep -o -s -E "forward-socks5 [0-9\.:]+" $CONFIG_PATH/rkn.action | cut -d ' ' -f 2)
[ -z "$FORWARD_ADDRESS_PORT" ] && export FORWARD_ADDRESS_PORT=$(grep -o -s -E "forward-socks5 [0-9\.:]+" $CONFIG_PATH/ru.action | cut -d ' ' -f 2)
[ -z "$FORWARD_ADDRESS_PORT" ] && export FORWARD_ADDRESS_PORT=127.0.0.1:1843
sed -i "/^FORWARD_ADDRESS_PORT=/{h;s/=.*/=${FORWARD_ADDRESS_PORT}/};\${x;/^$/{s//FORWARD_ADDRESS_PORT=${FORWARD_ADDRESS_PORT}/;H};x}" $CONFIG_PATH/config.ini

#  OS_UPDATE
[ -z "$OS_UPDATE" ] && export OS_UPDATE=true
[ "$OS_UPDATE" != "true" ] && export OS_UPDATE=false
sed -i "/^OS_UPDATE=/{h;s/=.*/=${OS_UPDATE}/};\${x;/^$/{s//OS_UPDATE=${OS_UPDATE}/;H};x}" $CONFIG_PATH/config.ini

#  UPDATE_SCHEDULE
if [ -z "$UPDATE_SCHEDULE" ]; then
    # generate update time in interval 2-4h and 0-59m 
    UPDATE_H=$(shuf -i2-4 -n1)
    UPDATE_M=$(shuf -i0-59 -n1)
    export UPDATE_SCHEDULE="\"$UPDATE_M $UPDATE_H \* \* \*\""
fi
sed -i "/^UPDATE_SCHEDULE=/{h;s/=.*/=${UPDATE_SCHEDULE}/};\${x;/^$/{s//UPDATE_SCHEDULE=${UPDATE_SCHEDULE}/;H};x}" $CONFIG_PATH/config.ini
sed -i -E "s/UPDATE_SCHEDULE=(.*)/UPDATE_SCHEDULE=\"\1\"/" $CONFIG_PATH/config.ini
sed -i "s/\"\"/\"/g" $CONFIG_PATH/config.ini

# Add to cron scheduled updates
if [ ! -z "$UPDATE_SCHEDULE" ]; then
    echo "$(echo "$UPDATE_SCHEDULE" | sed 's/\\//g' | sed "s/\"//g") /update.sh >> /var/log/cron.log 2>&1" | crontab -
    cron -f >> /var/log/cron.log 2>&1&
fi

# Roskomnadzor unblock list (domains)
[ -z "$RKN_ENABLED" ] && export RKN_ENABLED=true
[ "$RKN_ENABLED" != "true" ] && export RKN_ENABLED=false
[ -z "$RKN_SOURCE" ] && export RKN_ENABLED=false
sed -i "/^RKN_ENABLED=/{h;s/=.*/=${RKN_ENABLED}/};\${x;/^$/{s//RKN_ENABLED=${RKN_ENABLED}/;H};x}" $CONFIG_PATH/config.ini
if [ "$RKN_ENABLED" = "true" ]; then
    sed -i "/.*actionsfile rkn.action/{h;s//actionsfile rkn.action/};\${x;/^$/{s//actionsfile rkn.action/;H};x}" $CONFIG_PATH/config
else
    sed -i "/.*actionsfile rkn.action/{h;s//#actionsfile rkn.action/};\${x;/^$/{s//#actionsfile rkn.action/;H};x}" $CONFIG_PATH/config
fi

# Russia unblock list
[ -z "$RU_ENABLED" ] && export RU_ENABLED=true
[ "$RU_ENABLED" != "true" ] && export RU_ENABLED=false
[ -z "$RU_SOURCE" ] && export RU_ENABLED=false
sed -i "/^RU_ENABLED=/{h;s/=.*/=${RU_ENABLED}/};\${x;/^$/{s//RU_ENABLED=${RU_ENABLED}/;H};x}" $CONFIG_PATH/config.ini
if [ "$RU_ENABLED" = "true" ]; then
    sed -i "/.*actionsfile ru.action/{h;s//actionsfile ru.action/};\${x;/^$/{s//actionsfile ru.action/;H};x}" $CONFIG_PATH/config
else
    sed -i "/.*actionsfile ru.action/{h;s//#actionsfile ru.action/};\${x;/^$/{s//#actionsfile ru.action/;H};x}" $CONFIG_PATH/config
fi

# Adblock Plus list
[ -z "$ADBLOCK_ENABLED" ] && export ADBLOCK_ENABLED=false
[ "$ADBLOCK_ENABLED" != "true" ] && export ADBLOCK_ENABLED=false
[ -z "$ADBLOCK_SOURCE" ] && export ADBLOCK_SOURCE==$(grep -s -E "^URLS" $CONFIG_PATH/privoxy-blocklist.conf | cut -d '=' -f 2)
[ -z "$ADBLOCK_SOURCE" ] && export ADBLOCK_ENABLED=false
sed -i "/^ADBLOCK_ENABLED=/{h;s/=.*/=${ADBLOCK_ENABLED}/};\${x;/^$/{s//ADBLOCK_ENABLED=${ADBLOCK_ENABLED}/;H};x}" $CONFIG_PATH/config.ini
sed -i "/^ADBLOCK_SOURCE=/{h;s/=.*/=${ADBLOCK_SOURCE}/};\${x;/^$/{s//ADBLOCK_SOURCE=${ADBLOCK_SOURCE}/;H};x}" $CONFIG_PATH/config.ini
sed -i "/^URLS=/{h;s/=.*/=${ADBLOCK_SOURCE}/};\${x;/^$/{s//URLS=${ADBLOCK_SOURCE}/;H};x}" $CONFIG_PATH/privoxy-blocklist.conf


# Save ENV VARS to file
echo "$(date): Save ENV VARS to file"
env | grep -v UPDATE_SCHEDULE | awk 'NF {sub("=","=\"",$0); print ""$0"\""}' > $CONFIG_PATH/.config.env && chmod 644 $CONFIG_PATH/.config.env

echo " "
echo "=================================================="
echo "$(date): config.sh finished"
echo "=================================================="
echo " "
