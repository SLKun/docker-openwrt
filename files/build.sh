#!/bin/bash

set -e
# set -x

mount_rootfs() {
	echo "* mounting image"
	offset=$(sfdisk -d ${IMG} | grep "${IMG}2" | sed -E 's/.*start=\s+([0-9]+).*/\1/g')
	tmpdir=$(mktemp -u -p .)
	mkdir -p "${tmpdir}"
	mount -o loop,offset=$((512 * $offset)) -t ext4 ${IMG} ${tmpdir}
}

docker_build() {
	echo "* building Docker image"
	docker build \
		--build-arg ROOT_PW \
		-t ${BUILD_TAG} \
		-f files/Dockerfile ${tmpdir}
}


cleanup() {
	echo "* cleaning up"
	umount ${tmpdir}
	rm -rf ${tmpdir}
}

IMG=${1:-'x'}
test -f ${IMG} || { echo 'no image file found'; exit 1; }
trap cleanup EXIT
mount_rootfs
docker_build