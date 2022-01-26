#! /bin/sh

##status FT sources: commit 3641ad6cfa7c4b99e40a0b59aa6b00385590cbdd; 23.12.2021

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
patch -i $FT_PATCHES_DIR/Makefile_arm.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile
## router/libbcm
patch -i $FT_PATCHES_DIR/Makefile_libbcm.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/libbcm/Makefile
## router/rc
patch -i $FT_PATCHES_DIR/services.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/rc/services.c
## router/shared
patch -i $FT_PATCHES_DIR/shutils.h.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/shared/shutils.h
## router/ebtables
patch -i $FT_PATCHES_DIR/libebtc.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/ebtables/libebtc.c
## router/httpd
patch -i $FT_PATCHES_DIR/ctype.h.patch $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/ctype.h
patch -i $FT_PATCHES_DIR/Makefile_httpd.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/httpd/Makefile
## router/hotplug2
patch -i $FT_PATCHES_DIR/mem_utils.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/hotplug2/mem_utils.c
patch -i $FT_PATCHES_DIR/hotplug2_utils.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/hotplug2/hotplug2_utils.c
## router/fmpeg - avoid implicit declarations
patch -i $FT_PATCHES_DIR/h264dsp_init_arm.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/ffmpeg/libavcodec/arm/h264dsp_init_arm.c
patch -i $FT_PATCHES_DIR/h264pred_init_arm.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/ffmpeg/libavcodec/arm/h264pred_init_arm.c
## router/wireguard - definition from Linux 3.1 netlink.h
patch -i $FT_PATCHES_DIR/netlink_wireguard.h.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/wireguard-tools/src/netlink.h
## router/dnscrypt - due to message "using unsafe headers"
patch -i $FT_PATCHES_DIR/configure.ac_dnscrypt.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/dnscrypt/configure.ac
# router/glib multiple definitions - alternate 1
patch -i $FT_PATCHES_DIR/glib.h.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/glib/glib.h
# router/glib multiple definitions - alternate 2
#patch -i $FT_PATCHES_DIR/glib_mod1.h.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/glib/glib.h
#patch -i $FT_PATCHES_DIR/gmessages.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/glib/gmessages.c

## kernel
patch -p1 -d$FT_REPO_DIR/release/src-rt-6.x.4708/linux/linux-2.6.36 < $FT_PATCHES_DIR/linux-2.6.32.60-gcc5.patch
## module: et-driver
patch -i $FT_PATCHES_DIR/et_linux.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/et_linux.c
patch -i $FT_PATCHES_DIR/etc.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/etc.c
patch -i $FT_PATCHES_DIR/etc_adm.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/etc_adm.c
patch -i $FT_PATCHES_DIR/etc47xx.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/etc47xx.c
patch -i $FT_PATCHES_DIR/etcgmac.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/etcgmac.c
patch -i $FT_PATCHES_DIR/etc_fa.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/etc_fa.c
## module: 4g modem driver cdc-ncm.c
patch -i $FT_PATCHES_DIR/string.h.patch $FT_REPO_DIR/release/src-rt-6.x.4708/linux/linux-2.6.36/include/linux/string.h
patch -i $FT_PATCHES_DIR/kernel.h.patch $FT_REPO_DIR/release/src-rt-6.x.4708/linux/linux-2.6.36/include/linux/kernel.h
patch -i $FT_PATCHES_DIR/string.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/linux/linux-2.6.36/lib/string.c

cd $FT_REPO_DIR/release/src-rt-6.x.4708

time make ac68e  #z #1> log.txt 2>&1

## change ac68e to your Arm-router model if needed
