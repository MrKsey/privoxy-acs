#!/bin/bash

# Start load configs
. /config.sh

# Updates
. /update.sh

# Start privoxy
/etc/init.d/privoxy start &
tail --retry --follow=name /var/log/privoxy/logfile &

# endless work...
tail -f /dev/null
