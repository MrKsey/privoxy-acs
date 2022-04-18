#!/bin/bash

echo " "
echo "=================================================="
echo "$(date): update.sh started"
echo "=================================================="
echo " "

if [ -s $CONFIG_PATH/.config.env ]; then
    set -a; . $CONFIG_PATH/.config.env; set +a
fi

# Update OS
if [ "$OS_UPDATE" = "true" ]; then
    echo "$(date): Start checking for OS updates ..."
    apt-get update && apt-get upgrade -y && apt-get purge -y -q --auto-remove
    # Update ADBLOCK to PRIVOXY script
    wget --no-verbose --no-check-certificate --user-agent="$USER_AGENT" --output-document=/usr/local/bin/privoxy-blocklist.sh --tries=3 $ADBLOCK2PRIVOXY_SCRIPT
    chown -R root:root /usr/local/bin && chmod -R a+x /usr/local/bin
    echo "$(date): Finished checking for OS updates."
fi

mkdir -p /tmp/upd && cd /tmp/upd

# Update Roskomnadzor unblock list
if [ "$RKN_ENABLED" = "true" ]; then
    echo "$(date): Updating Roskomnadzor's unblock list ..."
    wget --no-verbose --no-check-certificate --user-agent="$USER_AGENT" --output-document=/tmp/upd/rkn.txt --tries=3 $RKN_SOURCE
    if [ $? -eq 0 ]; then
        RKN_SIZE=$(wc -l rkn.txt | cut -d ' ' -f 1)
		if [ $RKN_SIZE -ge 100 ]; then
            echo "$(date): Roskomnadzor's unblocking list contains $RKN_SIZE domains. Updating rkn.action..."
			echo "{+forward-override{forward-socks5 $FORWARD_ADDRESS_PORT .}}" > $CONFIG_PATH/rkn.action
			cat /tmp/upd/rkn.txt | grep -E "^[0-9A-Za-z]" | sed 's/^/./' >> $CONFIG_PATH/rkn.action
		else
		    echo "$(date): Roskomnadzor's unblocking list contains $RKN_SIZE lines. It is too small. Update terminated...."
		fi
    else
        echo "$(date): Update Roskomnadzor's unblocking list failed. Check update source url: $RKN_SOURCE"
    fi
fi

# Update Russia unblock list
if [ "$RU_ENABLED" = "true" ]; then
    echo "$(date): Updating Russia's unblock list ..."
    wget --no-verbose --no-check-certificate --user-agent="$USER_AGENT" --output-document=/tmp/upd/ru.txt --tries=3 $RU_SOURCE
    if [ $? -eq 0 ]; then
        RU_SIZE=$(wc -l ru.txt | cut -d ' ' -f 1)
		if [ $RU_SIZE -ge 3 ]; then
            echo "$(date): Russia's unblocking list contains $RU_SIZE domains. Updating ru.action..."
			echo "{+forward-override{forward-socks5 $FORWARD_ADDRESS_PORT .}}" > $CONFIG_PATH/ru.action
			cat /tmp/upd/ru.txt | grep -E "^[0-9A-Za-z]" | sed 's/^/./' >> $CONFIG_PATH/ru.action
		else
		    echo "$(date): Russia's unblocking list contains $RU_SIZE lines. It is too small. Update terminated...."
		fi
    else
        echo "$(date): Update Russia's unblocking list failed. Check update source url: $RU_SOURCE"
    fi
fi

# Update Adblock Plus list
if [ "$ADBLOCK_ENABLED" = "true" ]; then
    echo "$(date): Updating Adblock Plus list ..."
    privoxy-blocklist.sh -c $CONFIG_PATH/privoxy-blocklist.conf
fi

cd / && rm -rf /tmp/upd

echo " "
echo "=================================================="
echo "$(date): update.sh finished"
echo "=================================================="
echo " "
