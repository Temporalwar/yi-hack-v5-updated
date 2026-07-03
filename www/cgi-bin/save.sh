#!/bin/sh

# 1.1.0

printf "Content-type: application/octet-stream\r\n\r\n"

TMP_DIR="/tmp/yi-temp-save"
mkdir $TMP_DIR
cd $TMP_DIR || exit 1
cp /tmp/sd/yi-hack-v5/etc/*.conf .
if [ -f /tmp/sd/yi-hack-v5/etc/hostname ]; then
    cp /tmp/sd/yi-hack-v5/etc/hostname .
fi
tar cvf config.tar * > /dev/null
bzip2 config.tar
cat $TMP_DIR/config.tar.bz2
cd /tmp || exit 1
rm -rf $TMP_DIR
