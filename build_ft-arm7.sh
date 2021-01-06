#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-arm

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout arm-sdk7
clear

patch -i $FT_PATCHES_DIR/common.mak.patch $FT_REPO_DIR/release/src-rt-7.x.main/src/router/common.mak
patch -i $FT_PATCHES_DIR/Makefile_arm.patch $FT_REPO_DIR/release/src-rt-7.x.main/src/router/Makefile
patch -i $FT_PATCHES_DIR/miniupnpd_config.patch $FT_REPO_DIR/release/src-rt-7.x.main/router/miniupnpd/configure

cd release/src-rt-7.x.main/src

time make ac3200z
# AIO:z; VPN:e
