#! /bin/sh

##status FT sources: commit  fc63211121c6212b53442d50f5af240159f6a971	01/04/2022

## path to the local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-mips

## path to the FreshTomato patches for new mips-toolchain
FT_PATCHES_DIR=$HOME/Artix_FreshTomato/gcc-11.2-toolchain_mips-ng

## path to mips-toolchain with gcc 11.2 and binutils 2.37
FT_TOOLCHAIN_DIR=$HOME/buildroot-2021.11.1_mips_11.2-ng/output/host

export PATH=$FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-11.2-ng/usr/bin:$PATH
RT_VERS="src-rt-6.x"

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
##git pull
git checkout mips-RT-AC

clear

### insert new toolchain
rm -rf  $FT_REPO_DIR/tools/brcm
mkdir -p $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-11.2-ng/usr
cp -rf $FT_TOOLCHAIN_DIR/usr/* $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-11.2-ng/usr


#### userland
## router/Makefiles
patch -i  $FT_PATCHES_DIR/Makefile.patch $FT_REPO_DIR/release/src/router/Makefile
patch -i $FT_PATCHES_DIR/common.mak.patch $FT_REPO_DIR/release/src/router/common.mak

## lzma-loader
patch -i $FT_PATCHES_DIR/head.S.patch $FT_REPO_DIR/release/src/lzma-loader/head.S
## amended for use with gcc11.2
patch -i $FT_PATCHES_DIR/Makefile_lzma-loader.patch $FT_REPO_DIR/release/src/lzma-loader/Makefile

## router/libbcmcrypto
patch -i $FT_PATCHES_DIR/Makefile_libbcmcrypto.patch $FT_REPO_DIR/release/src/router/libbcmcrypto/Makefile

## router/rc
patch -i $FT_PATCHES_DIR/services.c.patch $FT_REPO_DIR/release/src/router/rc/services.c

## router/shared
patch -i $FT_PATCHES_DIR/shutils.h.patch $FT_REPO_DIR/release/src/router/shared/shutils.h

## router/ebtables
patch -i $FT_PATCHES_DIR/libebtc.c.patch $FT_REPO_DIR/release/src/router/ebtables/libebtc.c

## router/httpd
patch -i $FT_PATCHES_DIR/ctype.h.patch $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-11.2-ng/usr/mipsel-brcm-linux-uclibc/sysroot/usr/include/ctype.h

## router/hotplug2; 3rd patch new for gcc-7.3
patch -i $FT_PATCHES_DIR/mem_utils.c.patch $FT_REPO_DIR/release/src/router/hotplug2/mem_utils.c
patch -i $FT_PATCHES_DIR/hotplug2_utils.c.patch $FT_REPO_DIR/release/src/router/hotplug2/hotplug2_utils.c
patch -i $FT_PATCHES_DIR/hotplug2.c.patch $FT_REPO_DIR/release/src/router/hotplug2/hotplug2.c

## router/dnscrypt - due to message "using unsafe headers" - nur bei AIO
patch -i $FT_PATCHES_DIR/configure.ac_dnscrypt.patch $FT_REPO_DIR/release/src/router/dnscrypt/configure.ac

## router/glib; multiple definitions - nur bei AIO
patch -i $FT_PATCHES_DIR/glib.h.patch $FT_REPO_DIR/release/src/router/glib/glib.h

## router/samba3
##      due to message "using unsafe libraries in usr/local/lib" and "using unsafe headers in usr/local/include" (ICONV_LOOK_DIRS)
patch -i $FT_PATCHES_DIR/configure_samba.patch $FT_REPO_DIR/release/src/router/samba3/source3/configure

## router/iptables; thanks to source code of github asuswrt-john; 1st patch amended for gcc-7.3/uclibc;  2nd patch new with gcc 7.x
cp -vf $FT_PATCHES_DIR/122_new-toolchain_small.patch $FT_REPO_DIR/release/src/router/patches/iptables

## router/zebra
patch -i $FT_PATCHES_DIR/zebra.h.patch $FT_REPO_DIR/release/src/router/zebra/lib/zebra.h

## router/openvpn_plugin_auth_nvram
patch -i $FT_PATCHES_DIR/Makefile_openvpn_plugin_auth_nvram.patch $FT_REPO_DIR/release/src/router/openvpn_plugin_auth_nvram/Makefile

## others ; libfoo.patch amended with change to gcc 7.3/uClibc-ng
patch -i $FT_PATCHES_DIR/libfoo.pl.patch $FT_REPO_DIR/release/src/btools/libfoo.pl

## router/dhcpv6;  new with uClibc-ng
patch -i $FT_PATCHES_DIR/timer.c.patch $FT_REPO_DIR/release/src/router/dhcpv6/timer.c

## new with gc-7.3/uClibc-ng: replacement of portmap by rpcbind/libtirpc: install new sources + patch in nfs-utils source code
mkdir -p $FT_REPO_DIR/release/src/router/libtirpc
cp -rf $HOME/libtirpc-1.3.2/* $FT_REPO_DIR/release/src/router/libtirpc
mkdir -p $FT_REPO_DIR/release/src/router/rpcbind
cp -rf $HOME/rpcbind-1.2.6/* $FT_REPO_DIR/release/src/router/rpcbind
patch -i $FT_PATCHES_DIR/nfs.c.patch $FT_REPO_DIR/release/src/router/rc/nfs.c
rm -rf  $FT_REPO_DIR/release/src/router/portmap

## router/nfs-utils; new needed by using gcc11.2
patch -p1 -d$FT_REPO_DIR/release/src/router/nfs-utils  < $FT_PATCHES_DIR/nfs-utils_fno-common.patch

## router/minidlna; new needed by using gcc11.2
patch -p1 -d$FT_REPO_DIR/release/src/router/minidlna  < $FT_PATCHES_DIR/minidlna_fno-common.patch

## router/iproute2; new needed by using gcc11.2
cp -vf $FT_PATCHES_DIR/130_gcc11.2_filter.patch $FT_REPO_DIR/release/src/router/patches/iproute2

### kernel built-in
## off warnings  not used
patch -i $FT_PATCHES_DIR/Makefile_linux.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/Makefile
patch -p1 -d$FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6 < $FT_PATCHES_DIR/linux-2.6.32.60-gcc5.patch
## new for gcc-11.2
patch -i $FT_PATCHES_DIR/vmlinux.lds.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/vmlinux.lds.S
patch -i $FT_PATCHES_DIR/log2.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/linux/log2.h
patch -i $FT_PATCHES_DIR/Makefile_compressed.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/brcm-boards/bcm947xx/compressed/Makefile

## binutils >=2.24 differentiate much more between soft-float and hard-float; adapted from https://marc.info/?l=linux-mips&m=141302219906796&w=2
patch -i $FT_PATCHES_DIR/r4k_fpu.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/r4k_fpu.S
patch -i $FT_PATCHES_DIR/r4k_switch.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/r4k_switch.S
patch -i $FT_PATCHES_DIR/genex.S.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/genex.S
patch -i $FT_PATCHES_DIR/branch.c.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/kernel/branch.c
patch -i $FT_PATCHES_DIR/mipsregs.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/mipsregs.h
patch -i $FT_PATCHES_DIR/fpregdef.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/fpregdef.h
patch -i $FT_PATCHES_DIR/asmmacro-32.h.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/include/asm-mips/asmmacro-32.h
patch -i $FT_PATCHES_DIR/Makefile_arch_mips.patch $FT_REPO_DIR/release/$RT_VERS/linux/linux-2.6/arch/mips/Makefile

## "alias"-functions not allowed anymore in binutils 2.23 - patch similar to  https://patchwork.linux-mips.org/patch/3866
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


cd $FT_REPO_DIR/release/$RT_VERS

make r64z  #1> log.txt 2>&1
