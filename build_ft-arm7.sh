#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-arm

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout arm-sdk7

clear

patch -i $FT_PATCHES_DIR/Makefile_arm.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile
patch -i $FT_PATCHES_DIR/miniupnpd_config.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/miniupnpd/configure
patch -i $FT_PATCHES_DIR/configure.in_apcupsd.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/apcupsd/autoconf/configure.in
patch -i  $FT_PATCHES_DIR/configure.ac_transmission.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/transmission/configure.ac

cd release/src-rt-7.x.main/src

time make ac3200z
# AIO:z; VPN:e
