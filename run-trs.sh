#!/usr/bin/env bash
set -euxo pipefail

TEMP_GID=$(id -g)
TEMP_UID=$(id -u)

# Defaults
IMAGE=trs-docker
USERNAME=dev
HOST_TRS_REPO=$HOME/trs_reference_repo
CONTAINER_HOME=/home/$USERNAME
CONTAINER_DEV_DIR=$CONTAINER_HOME/trs-workspace
CONTAINER_TRS_REPO=$CONTAINER_HOME/trs-reference-repo
HOST_YOCTO_CACHE=yocto_cache
CONTAINER_YOCTO_CACHE=yocto_cache

install_docker="NO"

################################################################################
# Parse arguments
################################################################################
while getopts "i:r:d" opt; do
	case $opt in
		i)
			IMAGE=$OPTARG
			;;
		r)
			CONTAINER_TRS_REPO=$OPTARG
			;;
		d)
			install_docker="YES"
			;;
		*)
			#Printing error message
			echo "invalid option or argument $OPTARG"
			;;
	esac
done

if [ -n "${DL_DIR-}" ]; then
	echo "DL_DIR not empty"
elif [ "${DL_DIR+defined}" = defined ]; then
	echo "DL_DIR empty but defined, set it"
	DL_DIR=$HOME/$HOST_YOCTO_CACHE/downloads
	mkdir -p $DL_DIR
else
	echo "DL_DIR unset, set it"
	DL_DIR=$HOME/$HOST_YOCTO_CACHE/downloads
	mkdir -p $DL_DIR
fi
HOST_DL_DIR=$DL_DIR
CONTAINER_DL_DIR=$CONTAINER_DEV_DIR/build/downloads


if [ -n "${SSTATE_DIR-}" ]; then
	echo "SSTATE_DIR not empty"
elif [ "${SSTATE_DIR+defined}" = defined ];then
	echo "SSTATE_DIR empty but defined, set it under $HOME/yocto_cache"
	SSTATE_DIR=$HOME/$HOST_YOCTO_CACHE/sstate-cache
	mkdir -p $SSTATE_DIR
else
	echo "SSTATE_DIR unset, set it under $HOME/yocto_cache"
	SSTATE_DIR=$HOME/$HOST_YOCTO_CACHE/sstate-cache
	mkdir -p $SSTATE_DIR
fi
HOST_SSTATE_DIR=$SSTATE_DIR
CONTAINER_SSTATE_DIR=$CONTAINER_DEV_DIR/build/sstate-cache

echo "Create the TRS shared repo directory on the host if doesn't already exist"
mkdir -p $HOST_TRS_REPO

################################################################################
# Run docker
################################################################################
echo "Running docker instance with params:"
echo "IMAGE:          $IMAGE"
echo "USERNAME:       $USERNAME"
echo "UID:            $TEMP_UID"
echo "GID:            $TEMP_GID"
echo "HOST_TRS_REFERENCE: $HOST_TRS_REPO"
echo "CONTAINER_TRS_REPO: $CONTAINER_TRS_REPO"
echo "HOST_DL_DIR:         $HOST_DL_DIR"
echo "HOST_SSTATE_DIR:     $HOST_SSTATE_DIR"
echo "CONTAINER_DL_DIR:         $CONTAINER_DL_DIR"
echo "CONTAINER_SSTATE_DIR:     $CONTAINER_SSTATE_DIR"


################################################################################
# Use this run command to pass the same UID/GID as the host to the container. 
# Also, this one passes in the DL_DIR and SSTATE_DIR enviromental variables 
# so that the trs build works correctly. These are needed in the trs/build/makefile 
# to define the directory location for the yocto downloads and sstate caches.
################################################################################
if [ $install_docker = 'YES' ]; then

	echo "Enabling the docker.sock from Host"
	docker run --privileged -it \
		--user $USERNAME \
		-e DL_DIR=$CONTAINER_DL_DIR \
		-e SSTATE_DIR=$CONTAINER_SSTATE_DIR \
		-v $HOST_DL_DIR:$CONTAINER_HOME/$CONTAINER_YOCTO_CACHE/downloads \
		-v $HOST_SSTATE_DIR:$CONTAINER_HOME/$CONTAINER_YOCTO_CACHE/sstate-cache \
		-v $HOST_TRS_REPO:$CONTAINER_TRS_REPO \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$IMAGE
else
	echo "docker.sock from Host disabled"
	docker run --privileged -it \
		--user $USERNAME \
		-e DL_DIR=$CONTAINER_DL_DIR \
		-e SSTATE_DIR=$CONTAINER_SSTATE_DIR \
		-v $HOST_DL_DIR:$CONTAINER_HOME/$CONTAINER_YOCTO_CACHE/downloads \
		-v $HOST_SSTATE_DIR:$CONTAINER_HOME/$CONTAINER_YOCTO_CACHE/sstate-cache \
		-v $HOST_TRS_REPO:$CONTAINER_TRS_REPO \
		$IMAGE
fi

# Use this one when the UID/GID defined in the Dockerfile. Must update Dockerfile as well.
#docker run -it \
#	--user $USERNAME \
#	-v $HOST_DL_DIR:$CONTAINER_HOME/$CONTAINER_YOCTO_CACHE/downloads \
#	-v $HOST_SSTATE_DIR:$CONTAINER_HOME/$CONTAINER_YOCTO_CACHE/sstate-cache \
#	-v $HOST_TRS_REPO:$CONTAINER_TRS_REPO \
#	$IMAGE
