#!/bin/bash

# Start load configs
. /config.sh

# Updates
. /update.sh

# Start privoxy
tail -n 0 --retry --follow=name /var/log/privoxy/logfile &
/etc/init.d/privoxy start &

# endless work...
tail -f /dev/null
