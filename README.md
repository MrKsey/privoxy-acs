# privoxy-acs
HTTP proxy with anti-censorship.
This is a way to route domain-based traffic through an encrypted tunnel.

### Key futures:
- autoupdates OS, privoxy and filters
- flexible configuration with config.ini

### default ports:
- Privoxy listen port 8118 (HTTP proxy)
- Forwarding traffic to port 1843 (Socks5 proxy)

### Requrements:
Sock5 proxy. For example - ["ShadowSocks"](https://github.com/MrKsey/ss-tls-v2ray)

### Installing
- сreate "/privoxy" directory (for example) on your host
- connect host directory "/privoxy" to the container directory "/etc/privoxy" and start container:
```
docker run --name privoxy-acs -d --restart=unless-stopped --net=host -v /privoxy:/etc/privoxy ksey/privoxy-acs

```
