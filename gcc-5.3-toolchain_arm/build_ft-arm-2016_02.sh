#! /bin/sh

##status FT sources: commit bcec436b91843d78516be04795baa7f334422e47; 17.12.2021

## path to the local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-arm

## path to the FreshTomato patches for new arm-toolchain
FT_PATCHES_DIR=$HOME/freshtomato-arm/gcc-5.3-toolchain_arm

## path to arm-toolchain with gcc 5.3 and binutils 2.25.1
FT_TOOLCHAIN_DIR=$HOME/buildroot-2016.02_arm/output/host

export PATH=$HOME/freshtomato-arm/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/usr/bin:$PATH

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
git checkout master
#git pull

clear

## insert new toolchain
rm -rf  $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/*
mkdir $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/usr
cp -rvf $FT_TOOLCHAIN_DIR/usr/* $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/usr

## router/Makefile
cp -vf $FT_PATCHES_DIR/FT/Makefile_arm $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile
## router/libbcm
cp -vf $FT_PATCHES_DIR/FT/Makefile_libbcm $FT_REPO_DIR/release/src-rt-6.x.4708/router/libbcm/Makefile
## router/rc
cp -vf $FT_PATCHES_DIR/FT/services.c $FT_REPO_DIR/release/src-rt-6.x.4708/router/rc

## router/shared
cp -vf $FT_PATCHES_DIR/FT/shutils.h $FT_REPO_DIR/release/src-rt-6.x.4708/router/shared
## router/ebtables
cp -vf $FT_PATCHES_DIR/FT/libebtc.c $FT_REPO_DIR/release/src-rt-6.x.4708/router/ebtables
## router/httpd
cp -vf $FT_PATCHES_DIR/FT/ctype.h $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include
cp -vf $FT_PATCHES_DIR/FT/Makefile_httpd $FT_REPO_DIR/release/src-rt-6.x.4708/router/httpd/Makefile
## router/hotplug2
cp -vf $FT_PATCHES_DIR/FT/mem_utils.c $FT_REPO_DIR/release/src-rt-6.x.4708/router/hotplug2
cp -vf $FT_PATCHES_DIR/FT/hotplug2_utils.c $FT_REPO_DIR/release/src-rt-6.x.4708/router/hotplug2
## router/fmpeg - avoid implicit declarations
cp -vf $FT_PATCHES_DIR/FT/h264dsp_init_arm.c $FT_REPO_DIR/release/src-rt-6.x.4708/router/ffmpeg/libavcodec/arm
cp -vf $FT_PATCHES_DIR/FT/h264pred_init_arm.c $FT_REPO_DIR/release/src-rt-6.x.4708/router/ffmpeg/libavcodec/arm
## router/wireguard - definition from Linux 3.1 netlink.h
cp -vf $FT_PATCHES_DIR/FT/netlink_wireguard.h $FT_REPO_DIR/release/src-rt-6.x.4708/router/wireguard-tools/src/netlink.h
## router/dnscrypt - due to message "using unsafe headers"
cp -vf $FT_PATCHES_DIR/FT/configure.ac_dnscrypt $FT_REPO_DIR/release/src-rt-6.x.4708/router/dnscrypt/configure.ac
# router/glib multiple definitions - alternate 1 
cp -vf $FT_PATCHES_DIR/FT/glib.h $FT_REPO_DIR/release/src-rt-6.x.4708/router/glib
# router/glib multiple definitions - alternate 2
#cp -vf $FT_PATCHES_DIR/FT/glib_mod1.h $FT_REPO_DIR/release/src-rt-6.x.4708/router/glib/glib.h
#cp -vf $FT_PATCHES_DIR/FT/gmessages.c $FT_REPO_DIR/release/src-rt-6.x.4708/router/glib

## kernel
patch -p1 -d$FT_REPO_DIR/release/src-rt-6.x.4708/linux/linux-2.6.36 < $FT_PATCHES_DIR/FT/linux-2.6.32.60-gcc5.patch
## module: et-driver
cp -vf $FT_PATCHES_DIR/FT/et_linux.c $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys
cp -vf $FT_PATCHES_DIR/FT/etc.c $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys
cp -vf $FT_PATCHES_DIR/FT/etc_adm.c $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys
cp -vf $FT_PATCHES_DIR/FT/etc47xx.c $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys
cp -vf $FT_PATCHES_DIR/FT/etcgmac.c $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys
cp -vf $FT_PATCHES_DIR/FT/etc_fa.c $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys
## module: 4g modem driver cdc-ncm.c
cp -vf $FT_PATCHES_DIR/FT/string.h $FT_REPO_DIR/release/src-rt-6.x.4708/linux/linux-2.6.36/include/linux
cp -vf $FT_PATCHES_DIR/FT/kernel.h $FT_REPO_DIR/release/src-rt-6.x.4708/linux/linux-2.6.36/include/linux
cp -vf $FT_PATCHES_DIR/FT/string.c $FT_REPO_DIR/release/src-rt-6.x.4708/linux/linux-2.6.36/lib

cd $FT_REPO_DIR/release/src-rt-6.x.4708

time make ac68e  #z #1> log.txt 2>&1

## change ac68e to your Arm-router model if needed