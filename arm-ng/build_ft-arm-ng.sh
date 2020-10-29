#! /bin/sh

FT_PATCHES_DIR=$HOME/freshtomato_artix
FT_REPO_DIR=$HOME/freshtomato-arm

PATH="$PATH:$FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/bin"

cd $FT_REPO_DIR
git clean -dxf 
git reset --hard
#git pull

git checkout arm-ng

patch -i $FT_PATCHES_DIR/common.mak.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/common.mak
patch -i $FT_PATCHES_DIR/Makefile_arm-ng.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile
patch -i $FT_PATCHES_DIR/configure.ac_tor.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/tor/configure.ac
patch -i $FT_PATCHES_DIR/genconfig.sh.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/miniupnpd/genconfig.sh

patch -p1 -d$FT_REPO_DIR/release/src-rt-6.x.4708/router/config < $FT_PATCHES_DIR/config_gcc10.patch

cd release/src-rt-6.x.4708

time make ac68z #1> log.txt 2>&1
# AIO:z; VPN:e
