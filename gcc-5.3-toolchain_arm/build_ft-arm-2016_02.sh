#! /bin/sh

##status FT sources: commit cb0e7b09dab56cd3e9b2d59265ebf2357d3f955b; 26.02.2022

## path to the local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-arm

## path to the FreshTomato patches for new arm-toolchain
FT_PATCHES_DIR=$HOME/Artix_FreshTomato/gcc-5.3-toolchain_arm

## path to arm-toolchain with gcc 5.3 and binutils 2.25.1
FT_TOOLCHAIN_DIR=$HOME/buildroot-2016.02_arm/output/host

export PATH=$HOME/freshtomato-arm/release/src-rt-6.x.4708/toolchains/hndtools-arm-uclibc-5.3/usr/bin:$PATH

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
git checkout arm-master
#git pull

clear

## insert new toolchain
rm -rf  $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3
mkdir -p $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-uclibc-5.3/usr
cp -rf $FT_TOOLCHAIN_DIR/usr/* $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-uclibc-5.3/usr

## normal Artix-related Makefile patch
patch -i $FT_PATCHES_DIR/../Makefile.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile

## router/Makefile
patch -i $FT_PATCHES_DIR/Makefile.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile
patch -i $FT_PATCHES_DIR/common.mak.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/common.mak

## router/rc
patch -i $FT_PATCHES_DIR/services.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/rc/services.c

## router/ebtables
patch -i $FT_PATCHES_DIR/libebtc.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/ebtables/libebtc.c

## router/httpd
patch -i $FT_PATCHES_DIR/ctype.h.patch $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-uclibc-5.3/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/ctype.h

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

# router/glib multiple definitions
patch -i $FT_PATCHES_DIR/glib.h.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/glib/glib.h

## kernel
patch -p1 -d$FT_REPO_DIR/release/src-rt-6.x.4708/linux/linux-2.6.36 < $FT_PATCHES_DIR/linux-2.6.32.60-gcc5.patch
patch -i  $FT_PATCHES_DIR/Makefile_linux_arm.patch $FT_REPO_DIR/release/src-rt-6.x.4708/linux/linux-2.6.36/Makefile

## module: et-driver
patch -i $FT_PATCHES_DIR/et_linux.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/et_linux.c
patch -i $FT_PATCHES_DIR/etc.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/etc.c
patch -i $FT_PATCHES_DIR/etc_adm.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/etc_adm.c
patch -i $FT_PATCHES_DIR/etc47xx.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/etc47xx.c
patch -i $FT_PATCHES_DIR/etcgmac.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/etcgmac.c
patch -i $FT_PATCHES_DIR/etc_fa.c.patch $FT_REPO_DIR/release/src-rt-6.x.4708/et/sys/etc_fa.c


cd $FT_REPO_DIR/release/src-rt-6.x.4708

time make ac68e  #z #1> log.txt 2>&1

## change ac68e to your arm-router model
