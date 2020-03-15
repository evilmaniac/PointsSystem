#!/bin/bash

# Where dependencies will be downloaded
DOWNLOAD_LOCATION="dependencies"

# Sourcemod download version & URL
SOURCEMOD_VERSION="1.10"
SOURCEMOD_BASE_DOWNLOAD_URL="https://sm.alliedmods.net/smdrop/"
SOURCEMOD_LATEST="sourcemod-latest-linux"

SOURCEMOD_DOWNLOAD_DIR=$SOURCEMOD_BASE_DOWNLOAD_URL$SOURCEMOD_VERSION
SOURCEMOD_LATEST_RELEASE_NAME=$(wget -O- -q $SOURCEMOD_DOWNLOAD_DIR/$SOURCEMOD_LATEST)
SOURCEMOD_DOWNLOAD_URL=$SOURCEMOD_DOWNLOAD_DIR/$SOURCEMOD_LATEST_RELEASE_NAME

if [ ! -f $DOWNLOAD_LOCATION/$SOURCEMOD_LATEST_RELEASE_NAME ]; then
    wget -P $DOWNLOAD_LOCATION $SOURCEMOD_DOWNLOAD_URL
else
    echo "SourceMod available. Download not required"
fi

tar -zxvf $DOWNLOAD_LOCATION/$SOURCEMOD_LATEST_RELEASE_NAME \
    addons/sourcemod/scripting/include \
    addons/sourcemod/scripting/spcomp \
    addons/sourcemod/scripting/compile.sh
