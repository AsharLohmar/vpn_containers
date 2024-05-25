#!/bin/sh

DIR=/autostart.d
if [ -d "$DIR" ]; then
    /bin/run-parts --exit-on-error "$DIR"
fi
