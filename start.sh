#!/bin/bash

# Start load configs
. /config.sh

# Updates
. /update.sh

# Start privoxy
/etc/init.d/privoxy start &

# endless work...
tail -f /dev/null
