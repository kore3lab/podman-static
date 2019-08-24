#!/bin/sh

IMAGE=${PODMAN_IMAGE:-mgoltzsche/podman}

set -ex

while [ $# -gt 0 ]; do
	case "$1" in
		build)
			docker build --force-rm -t ${IMAGE} .
		;;
		test)
			echo TEST PODMAN AS ROOT '(using CNI)'
			docker run --rm --name podman --privileged --entrypoint /bin/sh \
				-v "`pwd`/storage-root":/var/lib/containers/storage \
				${IMAGE} \
				-c 'podman run --cgroup-manager=cgroupfs --rm alpine:3.10 wget -O /dev/null http://example.org'
			echo TEST PODMAN AS UNPRIVILEGED USER '(using fuse-overlayfs & slirp4netns)'
			docker run -ti --rm --name podman --privileged \
				-v "`pwd`/storage-user":/podman/.local/share/containers/storage \
				${IMAGE} \
				docker run --rm alpine:3.10 wget -O /dev/null http://example.org
			echo TEST BUILDAH AS UNPRIVILEGED USER
			docker run -ti --rm --name podman --privileged \
				-v "`pwd`/storage-user":/podman/.local/share/containers/storage \
				${IMAGE} \
				buildah from alpine:3.10
		;;
		run)
			docker run -ti --rm --name podman --privileged \
				-v "`pwd`/storage-user":/podman/.local/share/containers/storage \
				${IMAGE} /bin/sh
		;;
	esac
	shift
done