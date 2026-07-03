#!/bin/sh

# 1.1.0

CONF_FILE="etc/system.conf"

YI_HACK_PREFIX="/tmp/sd/yi-hack-v5"

get_config()
{
    grep -w "$1" "$YI_HACK_PREFIX/$CONF_FILE" | cut -d "=" -f2 | awk 'NR==1 {print; exit}'
}

MAX_RETRY=10
N_RETRY=0

REMOTE_RELEASE_URL=https://api.github.com/repos/Temporalwar/yi-hack-v5-updated/releases/latest
REMOTE_RELEASE_FILE=/tmp/.hackremoterel
REMOTE_VERSION_FILE=/tmp/.hackremotever
REMOTE_NEWVERSION_FILE=/tmp/.hacknewver

LOCAL_VERSION_FILE=/tmp/sd/yi-hack-v5/version
CA_BUNDLE="$YI_HACK_PREFIX/etc/ssl/certs/ca-certificates.crt"

# Fetch a URL to a file with TLS certificate verification.
# Prefers the bundled curl (linked against our patched OpenSSL);
# falls back to busybox wget only if curl is unavailable.
fetch_url()
{
    url=$1
    out=$2
    if command -v curl > /dev/null 2>&1; then
        if [ -f "$CA_BUNDLE" ]; then
            curl -sSf -m 10 --cacert "$CA_BUNDLE" -o "$out" "$url" > /dev/null 2>&1
        else
            curl -sSf -m 10 -o "$out" "$url" > /dev/null 2>&1
        fi
    else
        wget -T 10 -O "$out" "$url" > /dev/null 2>&1
    fi
    # Don't leave a zero-byte/partial file behind on failure
    if [ ! -s "$out" ]; then
        rm -f "$out"
        return 1
    fi
    return 0
}

if [ "$(get_config CHECK_UPDATES)" = "yes" ] ; then
    while : ; do
        # Get the latest version number from github
        fetch_url "$REMOTE_RELEASE_URL" "$REMOTE_RELEASE_FILE"

        if [ ! -f "$REMOTE_RELEASE_FILE" ]; then
            # The remote version number hasn't been downloaded yet (timeout)
            # The camera might be connecting to the wifi
            # Keep checking every 5 seconds and increment retry number
            sleep 5
            N_RETRY=$((N_RETRY+1))
        fi

        [ ! -f "$REMOTE_RELEASE_FILE" ] && [ "$N_RETRY" -le "$MAX_RETRY" ] || break
    done

    if [ -f "$REMOTE_RELEASE_FILE" ] ; then
        jq -r .tag_name < "$REMOTE_RELEASE_FILE" | sed 's/^v//' > "$REMOTE_VERSION_FILE"
        rm "$REMOTE_RELEASE_FILE"
        V_LOCAL=$(cut -d'_' -f1 < "$LOCAL_VERSION_FILE")
        V_REMOTE=$(cut -d'_' -f1 < "$REMOTE_VERSION_FILE")

        LOCAL_MAJOR=$(echo "$V_LOCAL" | cut -d'.' -f1)
        LOCAL_MINOR=$(echo "$V_LOCAL" | cut -d'.' -f2)
        LOCAL_PATCH=$(echo "$V_LOCAL" | cut -d'.' -f3)

        REMOTE_MAJOR=$(echo "$V_REMOTE" | cut -d'.' -f1)
        REMOTE_MINOR=$(echo "$V_REMOTE" | cut -d'.' -f2)
        REMOTE_PATCH=$(echo "$V_REMOTE" | cut -d'.' -f3)

        V_LOCAL_NUM=$(printf "%03d%03d%03d" "$LOCAL_MAJOR" "$LOCAL_MINOR" "$LOCAL_PATCH")
        V_REMOTE_NUM=$(printf "%03d%03d%03d" "$REMOTE_MAJOR" "$REMOTE_MINOR" "$REMOTE_PATCH")

        if [ "$V_LOCAL_NUM" -lt "$V_REMOTE_NUM" ] ; then
            echo "yes" > "$REMOTE_NEWVERSION_FILE"
        elif [ "$V_LOCAL_NUM" -eq "$V_REMOTE_NUM" ] ; then
            echo "no" > "$REMOTE_NEWVERSION_FILE"
        elif [ "$V_LOCAL_NUM" -gt "$V_REMOTE_NUM" ] ; then
            echo "no_currentversionisbeta" > "$REMOTE_NEWVERSION_FILE"
        fi
    fi
fi
