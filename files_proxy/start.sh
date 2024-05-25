#!/bin/sh

nc -lkp 8088 -e /proxy_pac.sh &

/glider -config /glider.conf
