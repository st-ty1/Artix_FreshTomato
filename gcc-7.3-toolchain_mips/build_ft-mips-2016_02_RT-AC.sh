#! /bin/sh

##status FT sources: commit f1591a3578704a181b6a990763677aef3c3aadc4 ; 27.1.2022

## path to the local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-mips

## path to the FreshTomato patches for new mips-toolchain
FT_PATCHES_DIR=$HOME/Artix_FreshTomato/gcc-7.3-toolchain_mips

## path to mips-toolchain with gcc 7.3 and binutils 2.28.1
FT_TOOLCHAIN_DIR=$HOME/buildroot-2016.02_mips/output/host

export PATH=$FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-7.3/usr/bin:$PATH
RT_VERS="src-rt-6.x"

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull
#git checkout master
git checkout mips-RT-AC

clear

### insert new toolchain
rm -rf  $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-4.2.4
mkdir -p $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-7.3/usr
cp -rf $FT_TOOLCHAIN_DIR/usr/* $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-7.3/usr

exit
#### userland
## router/Makefiles
#+patch -i  $FT_PATCHES_DIR/FT_mod/Makefile_mips4.patch $FT_REPO_DIR/release/src/router/Makefile
cp -vf $FT_PATCHES_DIR/FT_mod/Makefile $FT_REPO_DIR/release/src/router/Makefile
patch -i $FT_PATCHES_DIR/FT_mod/common.mak.patch $FT_REPO_DIR/release/src/router/common.mak

## lzma-loader
patch -i $FT_PATCHES_DIR/FT_mod/head.S.patch $FT_REPO_DIR/release/src/lzma-loader/head.S
patch -i $FT_PATCHES_DIR/FT_mod/Makefile_lzma-loader.patch $FT_REPO_DIR/release/src/lzma-loader/Makefile

## router/libbcmcrypto
patch -i $FT_PATCHES_DIR/FT_mod/Makefile_libbcmcrypto.patch $FT_REPO_DIR/release/src/router/libbcmcrypto/Makefile

## router/rc
patch -i $FT_PATCHES_DIR/FT_mod/services.c.patch $FT_REPO_DIR/release/src/router/rc/services.c

## router/shared  - neu
patch -i $FT_PATCHES_DIR/FT_mod/shutils.h.patch $FT_REPO_DIR/release/src/router/shared/shutils.h

## router/ebtables
patch -i $FT_PATCHES_DIR/FT_mod/libebtc.c.patch $FT_REPO_DIR/release/src/router/ebtables/libebtc.c

## router/httpd
patch -i $FT_PATCHES_DIR/FT_mod/ctype.h.patch $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-7.3/usr/mipsel-brcm-linux-uclibc/sysroot/usr/include/ctype.h
patch -i $FT_PATCHES_DIR/FT_mod/Makefile_httpd.patch $FT_REPO_DIR/release/src/router/httpd/Makefile

## router/hotplug2
patch -i $FT_PATCHES_DIR/FT_mod/mem_utils.c.patch $FT_REPO_DIR/release/src/router/hotplug2/mem_utils.c
patch -i $FT_PATCHES_DIR/FT_mod/hotplug2_utils.c.patch $FT_REPO_DIR/release/src/router/hotplug2/hotplug2_utils.c

## router/dnscrypt - due to message "using unsafe headers" - nur bei AIO
patch -i $FT_PATCHES_DIR/FT_mod/configure.ac_dnscrypt.patch $FT_REPO_DIR/release/src/router/dnscrypt/configure.ac

## router/glib; multiple definitions - nur bei AIO
patch -i $FT_PATCHES_DIR/FT_mod/glib.h.patch $FT_REPO_DIR/release/src/router/glib/glib.h

## router/samba3
##      due to message "using unsafe libraries in usr/local/lib" and "using unsafe headers in usr/local/include" (ICONV_LOOK_DIRS)
patch -i $FT_PATCHES_DIR/FT_mod/configure_samba.patch $FT_REPO_DIR/release/src/router/samba3/source3/configure

## router/iptables; thanks to source code of github asuswrt-john
patch -i $FT_PATCHES_DIR/FT_mod/ip6tables.c.patch $FT_REPO_DIR/release/src/router/iptables/ip6tables.c
patch -i $FT_PATCHES_DIR/FT_mod/libip6tc.c.patch $FT_REPO_DIR/release/src/router/iptables/libiptc/libip6tc.c
patch -i $FT_PATCHES_DIR/FT_mod/iptables-multi.c.patch $FT_REPO_DIR/release/src/router/iptables/iptables-multi.c
patch -i $FT_PATCHES_DIR/FT_mod/ip6tables-save.c.patch $FT_REPO_DIR/release/src/router/iptables/ip6tables-save.c
patch -i $FT_PATCHES_DIR/FT_mod/ip6tables-restore.c.patch $FT_REPO_DIR/release/src/router/iptables/ip6tables-restore.c
patch -i $FT_PATCHES_DIR/FT_mod/ip6tables-standalone.c.patch $FT_REPO_DIR/release/src/router/iptables/ip6tables-standalone.c

## router/zebra
patch -i $FT_PATCHES_DIR/FT_mod/zebra.h.patch $FT_REPO_DIR/release/src/router/zebra/lib/zebra.h

## router/openvpn_plugin_auth_nvram
patch -i $FT_PATCHES_DIR/FT_mod/Makefile_openvpn_plugin_auth_nvram.patch $FT_REPO_DIR/release/src/router/openvpn_plugin_auth_nvram/Makefile

## others 
## geändert bei gcc 7.3
patch -i $FT_PATCHES_DIR/FT_mod/libfoo.pl.patch $FT_REPO_DIR/release/src/btools/libfoo.pl

### kernel built-in
## off warnings  not used
patch -i $FT_PATCHES_DIR/FT_mod/Makefile_linux.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/Makefile
patch -p1 -d$FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6 < $FT_PATCHES_DIR/FT_mod/linux-2.6.32.60-gcc5.patch

## binutils >=2.24 differentiate much more between soft-float and hard-float; adapted from https://marc.info/?l=linux-mips&m=141302219906796&w=2
patch -i $FT_PATCHES_DIR/FT_mod/r4k_fpu.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/r4k_fpu.S
patch -i $FT_PATCHES_DIR/FT_mod/r4k_switch.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/r4k_switch.S
patch -i $FT_PATCHES_DIR/FT_mod/genex.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/genex.S
patch -i $FT_PATCHES_DIR/FT_mod/branch.c.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/branch.c
patch -i $FT_PATCHES_DIR/FT_mod/mipsregs.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/mipsregs.h
patch -i $FT_PATCHES_DIR/FT_mod/fpregdef.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/fpregdef.h
patch -i $FT_PATCHES_DIR/FT_mod/asmmacro-32.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/asmmacro-32.h
patch -i $FT_PATCHES_DIR/FT_mod/Makefile_arch_mips.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/Makefile

## "alias"-functions not allowed anymore in binutils 2.23 - patch similar to  https://patchwork.linux-mips.org/patch/3866
patch -i $FT_PATCHES_DIR/FT_mod/page.c.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/page.c
patch -i $FT_PATCHES_DIR/FT_mod/uasm.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/uasm.h
patch -i $FT_PATCHES_DIR/FT_mod/uasm.c.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/uasm.c
patch -i $FT_PATCHES_DIR/FT_mod/Makefile_mm_2.6.26.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/Makefile
patch -i $FT_PATCHES_DIR/FT_mod/war.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/war.h
patch -i $FT_PATCHES_DIR/FT_mod/bugs.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/bugs.h
patch -i $FT_PATCHES_DIR/FT_mod/cpu-features.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/cpu-features.h
patch -i $FT_PATCHES_DIR/FT_mod/page-funcs.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/page-funcs.S
patch -i $FT_PATCHES_DIR/FT_mod/mips_ksyms.c.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/mips_ksyms.c


## kernel-modules: et-driver
patch -i $FT_PATCHES_DIR/FT_mod/etc.c.patch $FT_REPO_DIR/release/$RT_VERS/et/sys/etc.c
patch -i $FT_PATCHES_DIR/FT_mod/etc_adm.c.patch $FT_REPO_DIR/release/$RT_VERS/et/sys/etc_adm.c
patch -i $FT_PATCHES_DIR/FT_mod/etc47xx.c.patch $FT_REPO_DIR/release/$RT_VERS/et/sys/etc47xx.c
patch -i $FT_PATCHES_DIR/FT_mod/etcgmac.c.patch $FT_REPO_DIR/release/$RT_VERS/et/sys/etcgmac.c

## compressed kernel -  variant not needed by Asus RT-N66U
patch -i $FT_PATCHES_DIR/FT_mod/bzip2_inflate.c.patch $FT_REPO_DIR/release/$RT_VERS/shared/bzip2_inflate.c

## new with gcc 7.x
patch -i $FT_PATCHES_DIR/FT_mod/hotplug2.c.patch $FT_REPO_DIR/release/src/router/hotplug2/hotplug2.c
patch -i $FT_PATCHES_DIR/FT_mod/101-tomato-additional-files.patch.patch $FT_REPO_DIR/release/src/router/patches/iptables/101-tomato-additional-files.patch


cd $FT_REPO_DIR/release/$RT_VERS

time make r64z  #1> log.txt 2>&1
