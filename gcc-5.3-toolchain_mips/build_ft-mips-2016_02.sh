#! /bin/sh

##status FT sources: commit f1591a3578704a181b6a990763677aef3c3aadc4 ; 27.1.2022

## path to the local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-mips

## path to the FreshTomato patches for new mips-toolchain
FT_PATCHES_DIR=$HOME/Artix_FreshTomato/gcc-5.3-toolchain_mips

## path to mips-toolchain with gcc 5.3 and binutils 2.23.2
FT_TOOLCHAIN_DIR=$HOME/buildroot-2016.02_mips/output/host

export PATH=$FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-5.3/usr/bin:$PATH
RT_VERS="src-rt-6.x"

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
git checkout mips-RT-AC

clear

### insert new toolchain
rm -rf  $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-4.2.4
mkdir -p $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-5.3/usr
cp -rf $FT_TOOLCHAIN_DIR/usr/* $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-5.3/usr


#### userland
## router/Makefiles
patch -i  $FT_PATCHES_DIR/Makefile_mips4.patch $FT_REPO_DIR/release/src/router/Makefile
patch -i $FT_PATCHES_DIR/common.mak.patch $FT_REPO_DIR/release/src/router/common.mak

## router/libbcmcrypto
patch -i $FT_PATCHES_DIR/Makefile_libbcmcrypto.patch $FT_REPO_DIR/release/src/router/libbcmcrypto/Makefile

## router/rc
patch -i $FT_PATCHES_DIR/services.c.patch $FT_REPO_DIR/release/src/router/rc/services.c

## router/shared
patch -i $FT_PATCHES_DIR/shutils.h.patch $FT_REPO_DIR/release/src/router/shared/shutils.h

## router/ebtables
patch -i $FT_PATCHES_DIR/libebtc.c.patch $FT_REPO_DIR/release/src/router/ebtables/libebtc.c

## router/httpd
patch -i $FT_PATCHES_DIR/ctype.h.patch $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-5.3/usr/mipsel-brcm-linux-uclibc/sysroot/usr/include/ctype.h
patch -i $FT_PATCHES_DIR/Makefile_httpd.patch $FT_REPO_DIR/release/src/router/httpd/Makefile

## router/hotplug2
patch -i $FT_PATCHES_DIR/mem_utils.c.patch $FT_REPO_DIR/release/src/router/hotplug2/mem_utils.c
patch -i $FT_PATCHES_DIR/hotplug2_utils.c.patch $FT_REPO_DIR/release/src/router/hotplug2/hotplug2_utils.c

## router/dnscrypt - due to message "using unsafe headers" - only for AIO version
patch -i $FT_PATCHES_DIR/configure.ac_dnscrypt.patch $FT_REPO_DIR/release/src/router/dnscrypt/configure.ac

## router/glib; multiple definitions - only for AIO version
patch -i $FT_PATCHES_DIR/glib.h.patch $FT_REPO_DIR/release/src/router/glib/glib.h

## router/samba3
##      due to message "using unsafe libraries in usr/local/lib" and 
##      "using unsafe headers in usr/local/include" (ICONV_LOOK_DIRS)
patch -i $FT_PATCHES_DIR/configure_samba.patch $FT_REPO_DIR/release/src/router/samba3/source3/configure

## router/iptables; thanks to iptables source code in https://github.com/john9527/asuswrt-merlin
patch -i $FT_PATCHES_DIR/ip6tables.c.patch $FT_REPO_DIR/release/src/router/iptables/ip6tables.c
patch -i $FT_PATCHES_DIR/libip6tc.c.patch $FT_REPO_DIR/release/src/router/iptables/libiptc/libip6tc.c
patch -i $FT_PATCHES_DIR/iptables-multi.c.patch $FT_REPO_DIR/release/src/router/iptables/iptables-multi.c
patch -i $FT_PATCHES_DIR/ip6tables-save.c.patch $FT_REPO_DIR/release/src/router/iptables/ip6tables-save.c
patch -i $FT_PATCHES_DIR/ip6tables-restore.c.patch $FT_REPO_DIR/release/src/router/iptables/ip6tables-restore.c
patch -i $FT_PATCHES_DIR/ip6tables-standalone.c.patch $FT_REPO_DIR/release/src/router/iptables/ip6tables-standalone.c

## router/zebra (https://www.iteye.com/blog/siwind-1160830)
patch -i $FT_PATCHES_DIR/zebra.h.patch $FT_REPO_DIR/release/src/router/zebra/lib/zebra.h

## router/openvpn_plugin_auth_nvram
patch -i $FT_PATCHES_DIR/Makefile_openvpn_plugin_auth_nvram.patch $FT_REPO_DIR/release/src/router/openvpn_plugin_auth_nvram/Makefile

## others
patch -i $FT_PATCHES_DIR/libfoo.pl.patch $FT_REPO_DIR/release/src/btools/libfoo.pl

### kernel built-in
## turn off warnings "... not used"
patch -i $FT_PATCHES_DIR/Makefile_linux.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/Makefile
patch -p1 -d$FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6 < $FT_PATCHES_DIR/linux-2.6.32.60-gcc5.patch

## binutils >=2.24 differentiate much more between soft-float and hard-float; 
#patch -i $FT_PATCHES_DIR/alternate_2/r4k_fpu.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/r4k_fpu.S
#patch -i $FT_PATCHES_DIR/alternate_2/r4k_switch.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/r4k_switch.S
#patch -i $FT_PATCHES_DIR/alternate_2/genex.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/genex.S
#patch -i $FT_PATCHES_DIR/alternate_2/branch.c.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/branch.c
#patch -i $FT_PATCHES_DIR/alternate_2/mipsregs.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/mipsregs.h
#patch -i $FT_PATCHES_DIR/alternate_2/fpregdef.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/fpregdef.h
#patch -i $FT_PATCHES_DIR/alternate_2/asmmacro-32.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/asmmacro-32.h
#patch -i $FT_PATCHES_DIR/alternate_2/Makefile_arch_mips.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/Makefile

## "alias"-functions not allowed anymore in binutils 2.23 - both patch versions similar to  https://patchwork.linux-mips.org/patch/3866
patch -i $FT_PATCHES_DIR/page.c.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/page.c
patch -i $FT_PATCHES_DIR/uasm.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/uasm.h
patch -i $FT_PATCHES_DIR/uasm.c.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/uasm.c

patch -i $FT_PATCHES_DIR/Makefile_mm_2.6.26.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/Makefile
patch -i $FT_PATCHES_DIR/war.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/war.h
patch -i $FT_PATCHES_DIR/bugs.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/bugs.h
patch -i $FT_PATCHES_DIR/cpu-features.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/cpu-features.h
patch -i $FT_PATCHES_DIR/page-funcs.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/mm/page-funcs.S
patch -i $FT_PATCHES_DIR/mips_ksyms.c.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/mips_ksyms.c


## kernel-modules: et-driver
patch -i $FT_PATCHES_DIR/etc.c.patch $FT_REPO_DIR/release/$RT_VERS/et/sys/etc.c
patch -i $FT_PATCHES_DIR/etc_adm.c.patch $FT_REPO_DIR/release/$RT_VERS/et/sys/etc_adm.c
patch -i $FT_PATCHES_DIR/etc47xx.c.patch $FT_REPO_DIR/release/$RT_VERS/et/sys/etc47xx.c
patch -i $FT_PATCHES_DIR/etcgmac.c.patch $FT_REPO_DIR/release/$RT_VERS/et/sys/etcgmac.c

## compressed kernel -  variant not needed by Asus RT-N66U
patch -i $FT_PATCHES_DIR/bzip2_inflate.c.patch $FT_REPO_DIR/release/$RT_VERS/shared/bzip2_inflate.c
## lzma-loader
patch -i $FT_PATCHES_DIR/head.S.patch $FT_REPO_DIR/release/src/lzma-loader/head.S
patch -i $FT_PATCHES_DIR/Makefile_lzma-loader.patch $FT_REPO_DIR/release/src/lzma-loader/Makefile


cd $FT_REPO_DIR/release/$RT_VERS

make r64e  #1> log.txt 2>&1
