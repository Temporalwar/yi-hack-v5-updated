#!/bin/sh

# 1.1.0

validateNumber()
{
    RES=$(echo ${1} | sed -E 's/^[0-9]*$//g')
    if [ -z $RES ]; then
        TIME=$1
    else
        TIME="invalid"
    fi
}

TIME=60

CONF="$(echo $QUERY_STRING | cut -d'&' -f1 | cut -d'=' -f1)"
VAL="$(echo $QUERY_STRING | cut -d'&' -f1 | cut -d'=' -f2)"

if [ "$CONF" == "time" ] ; then
    TIME="$VAL"
fi

if ! validateNumber "$TIME" ; then
    printf "Content-type: application/json\r\n\r\n"
    printf "{\n"
    printf "\"error\":\"Invalid time\"\n"
    printf "}\n"
    exit
fi

ipc_cmd -S $TIME &

printf "Content-type: application/json\r\n\r\n"
printf "{\n"
printf "}\n"
