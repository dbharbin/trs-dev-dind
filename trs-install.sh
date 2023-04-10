#!/usr/bin/env bash
#set -euxo pipefail

MANIFEST=default.xml
USE_HOST_YOCTO_CACHE=
USE_REFERENCE=
CONTAINER_TRS_REPO=trs-reference-repo

################################################################################
# Parse arguments
################################################################################
while getopts "m:rh" opt; do
	case $opt in
		h)
			USE_HOST_YOCTO_CACHE=1
			;;
		m)
			MANIFEST=$OPTARG
			;;
		r)
			USE_REFERENCE=1
			;;
		*)
			#Printing error message
			echo "invalid option or argument $OPTARG"
			;;
	esac
done

################################################################################
# Use host provided cache?
################################################################################
if [ -z $USE_HOST_YOCTO_CACHE ]; then
	echo "Not using Yocto cache from host"
	rm build/*
else
	echo "Using Yocto cache from host"
fi

################################################################################
# Get the source code
################################################################################
if [ -z $USE_REFERENCE ]; then
	echo "Not using reference from host"
	yes | repo init -u https://gitlab.com/Linaro/trusted-reference-stack/trs-manifest.git -m $MANIFEST --reference $HOME/local-reference
else
	echo "Using reference from host"
	yes | repo init -u https://gitlab.com/Linaro/trusted-reference-stack/trs-manifest.git -m $MANIFEST --reference $HOME/$CONTAINER_TRS_REPO
fi

repo sync -j10

################################################################################
# Setup pre-reqs
################################################################################
yes | make apt-prereqs
make python-prereqs

################################################################################
# Source python environment and start the build
################################################################################
source .pyvenv/bin/activate
nice -1 make
