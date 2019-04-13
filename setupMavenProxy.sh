#!/bin/bash

function main() {
    if [ -z "$1" ]; then
        echo "No proxy configured"
        return 0
    fi
    local pScheme=`echo "$1" | sed -E 's,(https?)://([^:/]*):?([0-9]*),\1,'`
    local pHost=`echo "$1" | sed -E 's,(https?)://([^:/]*):?([0-9]*),\2,'`
    local pPort=`echo "$1" | sed -E 's,(https?)://([^:/]*):?([0-9]*),\3,'`

    sed \
        -i -E \
        's,^.*</settings>$,'"<proxies><proxy><id>proxy-http</id><active>true</active><protocol>${pScheme}</protocol><host>${pHost}</host><port>${pPort}</port><nonProxyHosts>localhost\|${pHost}</nonProxyHosts></proxy></proxies>"'\0,' \
        /usr/share/maven/ref/settings-docker.xml
    return $?
}

main "$HTTPS_PROXY"
exit $?
