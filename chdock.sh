#!/usr/bin/env bash

set -e

set -u

if [ "$EUID" -ne 0 ]; then
   echo "Please run as root"
   exit 1
fi

mount_arr=(dev sys proc)
CONTAINER_ID=$1
CONTAINER_TAR=""$CONTAINER_ID".tar"
GREP_ID=`docker ps | grep "$CONTAINER_ID"`

if [ -z "$GREP_ID" ]; then
    echo "Container does not exist!" >&2
    exit 1
fi

mkdir "$CONTAINER_ID" > /dev/null 2>&1 &
cd "$CONTAINER_ID"

if [ -z "echo ${PWD} | grep "$CONTAINER_ID"" ]; then
    echo "Wrong dir" >&2
    exit 2
fi

docker export "$CONTAINER_ID" > "$CONTAINER_TAR"
tar -xvf "$CONTAINER_TAR" || {
    echo "Couldn't extract tar" >&2
    exit 3
}

for i in ${mount_arr[@]}
do
    mount --rbind /$i ./$i
done

chroot .
mount -a
su -

for i in ${mount_arr[@]}
do
    echo -e "Unmounting \033[0;34m"$i"\033[0m."
    umount -l ${PWD}/$i
done
echo -e "\033[0;32mOK\033[0m"
