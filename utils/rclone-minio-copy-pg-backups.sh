#! /usr/bin/env bash

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker run --rm \
       -v ${THISDIR}/rclone/rclone.conf:/config/rclone/rclone.conf \
       -v ${THISDIR}/../data/volumes/db-backup:/data \
       rclone/rclone \
       copy /data minio:bucket
