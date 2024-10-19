#!/bin/sh
set -e

if [ ! -d /mnt/dest ]; then
	echo "Please bind-mount to /mnt/dest" >/dev/stderr
	exit 1
fi

if [ "x${USERNAME}" = "x" ]; then
	echo "Please provide a \$USERNAME" >/dev/stderr
	exit 1
fi

if [ "x${FILE__PASSWORD}" = "x" -o ! -f "${FILE__PASSWORD}" ]; then
	echo "Please provide a valid \$FILE__PASSWORD" >/dev/stderr
	exit 1
fi

mkdir -p /mnt/src
mount -t cifs \
	//${HOSTNAME}/C$ \
	/mnt/src \
	-o "ro,username=${USERNAME},password=`cat ${FILE__PASSWORD}`"

exec rsync -rtv --delete /mnt/src/ /mnt/dest/
