#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-arm

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout arm-master

clear

# common patches needed by Artix/Arch Linux
patch -i $FT_PATCHES_DIR/common.mak.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/common.mak
patch -i $FT_PATCHES_DIR/Makefile_arm.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile
patch -i $FT_PATCHES_DIR/miniupnpd_config.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/miniupnpd/configure
patch -i $FT_PATCHES_DIR/configure.in_apcupsd.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/apcupsd/autoconf/configure.in
patch -i $FT_PATCHES_DIR/configure.in_mysql.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/mysql/configure.in

# patches specific for building transmission by cmake
cp -v $FT_PATCHES_DIR/transmission3.0_cmake/subprocess-test.cmd $FT_REPO_DIR/release/src-rt-6.x.4708/router/transmission/libtransmission
patch -i $FT_PATCHES_DIR/transmission3.0_cmake/transmission_cmake.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile

cd release/src-rt-6.x.4708

time make ac68z #1> log.txt 2>&1
## AIO:z; VPN:e
