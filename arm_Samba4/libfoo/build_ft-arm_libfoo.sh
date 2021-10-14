#! /bin/sh

## path to special Artix-patches for building FT
FT_PATCHES_DIR=$HOME/Artix_FreshTomato

## path to the local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-arm

## path to the local libfoo repo
LIBFOO_DIR=$HOME/Artix_Freshtomato/arm_Samba4/libfoo

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
git checkout arm-master

clear

## Arch-Linux-patches if build on Artix/Arch Linux, not needed on Debian
patch -i $FT_PATCHES_DIR/Makefile_arm.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile
patch -i $FT_PATCHES_DIR/alloca.m4.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/mysql/config/ac-macros/alloca.m4
patch -i $FT_PATCHES_DIR/miniupnpd_config.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/miniupnpd/configure
patch -i $FT_PATCHES_DIR/configure.in_apcupsd.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/apcupsd/autoconf/configure.in
patch -i $FT_PATCHES_DIR/configure.ac_transmission.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/transmission/configure.ac

#libfoo_arm
cp -v $LIBFOO_DIR/0101-Create-short-Makefiles-for-Debian.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/patches/diskdev_cmds-332.25
cp -v $LIBFOO_DIR/libfoo_arm2.pl $FT_REPO_DIR/release/src-rt-6.x.4708/btools/libfoo.pl
patch -i $LIBFOO_DIR/Makefile_libfoo.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile
patch -i $LIBFOO_DIR/Makefile_lib_so.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile

cd $FT_REPO_DIR/release/src-rt-6.x.4708

#make clean
time make ac68z ## AIO: z; VPN: e

## change ac68e to your Arm-router model if needed
