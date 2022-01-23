#! /bin/sh
##
##status FT sources: commit bcec436b91843d78516be04795baa7f334422e47; 17.12.2021
##

## path to your local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-mips

## path to the FreshTomato patches for new mips-toolchain (within your local Artix_FreshTomato repo)
FT_PATCHES_DIR=$HOME/Artix_FreshTomato/gcc-5.3-toolchain_mips

## path to mips-toolchain with gcc 5.3 and binutils 2.23.1
FT_TOOLCHAIN_DIR=$HOME/buildroot-2016.02_mips/output/host

export PATH=$FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-5.3/usr/bin:$PATH
RT_VERS="src-rt-6.x"

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git checkout master
git checkout mips-RT-AC


#### 1. insert new toolchain
rm -rf  $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-4.2.4
mkdir -p $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-5.3/usr
cp -rf $FT_TOOLCHAIN_DIR/usr/* $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-5.3/usr


#### 2. userland
## 2.1 router/Makefiles
cp -vf $FT_PATCHES_DIR/FT/Makefile_mips $FT_REPO_DIR/release/src/router/Makefile
cp -vf $FT_PATCHES_DIR/FT/common.mak $FT_REPO_DIR/release/src/router

## 2.2 router/libbcmcrypto
cp -vf $FT_PATCHES_DIR/FT/Makefile_libbcmcrypto $FT_REPO_DIR/release/src/router/libbcmcrypto/Makefile

## 2.3 router/rc
cp -vf $FT_PATCHES_DIR/FT/services.c $FT_REPO_DIR/release/src/router/rc

## 2.4 router/shared
cp -vf $FT_PATCHES_DIR/FT/shutils.h $FT_REPO_DIR/release/src/router/shared

## 2.5 router/ebtables
cp -vf $FT_PATCHES_DIR/FT/libebtc.c $FT_REPO_DIR/release/src/router/ebtables

## 2.6 router/httpd
cp -vf $FT_PATCHES_DIR/FT/ctype.h $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-5.3/usr/mipsel-brcm-linux-uclibc/sysroot/usr/include
cp -vf $FT_PATCHES_DIR/FT/Makefile_httpd $FT_REPO_DIR/release/src/router/httpd/Makefile

## 2.7 router/hotplug2
cp -vf $FT_PATCHES_DIR/FT/mem_utils.c $FT_REPO_DIR/release/src/router/hotplug2
cp -vf $FT_PATCHES_DIR/FT/hotplug2_utils.c $FT_REPO_DIR/release/src/router/hotplug2

## 2.8 router/dnscrypt - due to message "using unsafe headers"
cp -vf $FT_PATCHES_DIR/FT/configure.ac_dnscrypt $FT_REPO_DIR/release/src/router/dnscrypt/configure.ac

## 2.9 router/glib; due to "multiple definitions" - 2 alternate patches, only use one of them
cp -vf $FT_PATCHES_DIR/FT/glib.h $FT_REPO_DIR/release/src/router/glib
#cp -vf $FT_PATCHES_DIR/FT/glib_mod1.h $FT_REPO_DIR/release/src/router/glib/glib.h
#cp -vf $FT_PATCHES_DIR/FT/gmessages.c $FT_REPO_DIR/release/src/router/glib

## 2.10 router/samba3
cp -vf $FT_PATCHES_DIR/FT/Makefile_samba $FT_REPO_DIR/release/src/router/samba3/Makefile
##      due to message "using unsafe libraries in usr/local/lib" and 
##      "using unsafe headers in usr/local/include" (ICONV_LOOK_DIRS)
cp -vf $FT_PATCHES_DIR/FT/configure_samba $FT_REPO_DIR/release/src/router/samba3/source3/configure

## 2.11 router/iptables; thanks to iptables source code in https://github.com/john9527/asuswrt-merlin
cp -vf $FT_PATCHES_DIR/FT/ip6tables.c $FT_REPO_DIR/release/src/router/iptables
cp -vf $FT_PATCHES_DIR/FT/libip6tc.c $FT_REPO_DIR/release/src/router/iptables/libiptc
cp -vf $FT_PATCHES_DIR/FT/iptables-multi.c $FT_REPO_DIR/release/src/router/iptables
cp -vf $FT_PATCHES_DIR/FT/ip6tables-save.c $FT_REPO_DIR/release/src/router/iptables
cp -vf $FT_PATCHES_DIR/FT/ip6tables-restore.c $FT_REPO_DIR/release/src/router/iptables
cp -vf $FT_PATCHES_DIR/FT/ip6tables-standalone.c $FT_REPO_DIR/release/src/router/iptables

## 2.12 router/zebra
cp -vf $FT_PATCHES_DIR/FT/zebra.h $FT_REPO_DIR/release/src/router/zebra/lib

## 2.13 router/openvpn_plugin_auth_nvram
cp -vf $FT_PATCHES_DIR/FT/Makefile_openvpn_plugin_auth_nvram $FT_REPO_DIR/release/src/router/openvpn_plugin_auth_nvram/Makefile

## 2.14 others
cp -vf $FT_PATCHES_DIR/FT/libfoo_mips2.pl $FT_REPO_DIR/release/src/btools/libfoo.pl

#### 3. kernel 
## 3.1 built-in
##         turn off warnings about non-used variables and functions
cp -vf $FT_PATCHES_DIR/FT/Makefile_linux $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/Makefile
##         known patch to use gcc5
patch -p1 -d$FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6 < $FT_PATCHES_DIR/FT/linux-2.6.32.60-gcc5.patch
##          "alias"-functions not allowed anymore in binutils 2.23
##          backport of arch-specific memeory management parts of linux 2.6.26 and patch similar to  https://patchwork.linux-mips.org/patch/3866
cp -vf $FT_PATCHES_DIR/FT/page.c $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm
cp -vf $FT_PATCHES_DIR/FT/uasm.c $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm
cp -vf $FT_PATCHES_DIR/FT/uasm.h $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm
cp -vf $FT_PATCHES_DIR/FT/Makefile_mm $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/Makefile
cp -vf $FT_PATCHES_DIR/FT/war.h $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips
cp -vf $FT_PATCHES_DIR/FT/bugs.h $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips
cp -vf $FT_PATCHES_DIR/FT/cpu-features.h $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips
cp -vf $FT_PATCHES_DIR/FT/page-funcs.S $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm
cp -vf $FT_PATCHES_DIR/FT/mips_ksyms.c $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel

## 3.2 kernel-modules: et-driver
cp -vf $FT_PATCHES_DIR/FT/etc.c $FT_REPO_DIR/release/$RT_VERS/et/sys
cp -vf $FT_PATCHES_DIR/FT/etc_adm.c $FT_REPO_DIR/release/$RT_VERS/et/sys
cp -vf $FT_PATCHES_DIR/FT/etc47xx.c $FT_REPO_DIR/release/$RT_VERS/et/sys
cp -vf $FT_PATCHES_DIR/FT/etcgmac.c $FT_REPO_DIR/release/$RT_VERS/et/sys

## 3.3 compressed kernel and lzma-loader (loader.gz) - both not needed by Asus and Netgear routers
cp -vf $FT_PATCHES_DIR/FT/bzip2_inflate.c $FT_REPO_DIR/release/$RT_VERS/shared
cp -vf $FT_PATCHES_DIR/FT/head.S $FT_REPO_DIR/release/src/lzma-loader
cp -vf $FT_PATCHES_DIR/FT/Makefile_lzma-loader $FT_REPO_DIR/release/src/lzma-loader/Makefile


cd $FT_REPO_DIR/release/$RT_VERS

make r64e  #1> log.txt 2>&1
