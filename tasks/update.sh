#!/bin/sh

if [ ! -z "${PT_repo}" ]; then
    /usr/bin/equo update "${PT_repo}"
else
    /usr/bin/equo update
fi
