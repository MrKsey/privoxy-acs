#
# HTTP proxy with anti-censorship
#

FROM ubuntu:latest


ENV GIT_URL="https://github.com/MrKsey/privoxy-acs"
ENV ADBLOCK2PRIVOXY_SCRIPT="https://raw.githubusercontent.com/Andrwe/privoxy-blocklist/main/privoxy-blocklist.sh"
ENV USER_AGENT="Mozilla/5.0 (X11; Linux x86_64; rv:77.0) Gecko/20100101 Firefox/77.0"
ENV CONFIG_PATH="/etc/privoxy"

RUN export DEBIAN_FRONTEND=noninteractive \
&& chmod a+x /start.sh && chmod a+x /config.sh && chmod a+x /update.sh \
&& apt-get update && apt-get upgrade -y \
&& apt-get install --no-install-recommends -y ca-certificates tzdata curl wget subversion cron dos2unix privoxy \
&& dos2unix /start.sh && dos2unix /config.sh && dos2unix /update.sh \
&& wget --no-verbose --no-check-certificate --user-agent="$USER_AGENT" --output-document=/usr/local/bin/privoxy-blocklist.sh --tries=3 $ADBLOCK2PRIVOXY_SCRIPT \
&& chown -R root:root /usr/local/bin && chmod -R a+x /usr/local/bin \
&& apt-get purge -y -q --auto-remove \
&& apt-get clean \
&& touch /var/log/cron.log \
&& ln -sf /proc/1/fd/1 /var/log/cron.log

VOLUME [ "$CONFIG_PATH" ]

ENTRYPOINT ["/start.sh"]
