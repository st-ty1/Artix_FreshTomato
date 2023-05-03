#! /bin/sh

TOOLCHAIN_PATCH_DIR=$HOME/Artix_FreshTomato/gcc-4.5.3-toolchain_arm
FT_REPO_DIR=$HOME/freshtomato-arm 			#  directory of your local FreshTomato-arm repo

mkdir $HOME/buildroot-2012.02
cd $HOME
wget https://git.busybox.net/buildroot/snapshot/buildroot-2012.02.tar.bz2
mkdir $HOME/buildroot-2012.02
tar -vxf buildroot-2012.02.tar.bz2
cd $HOME/buildroot-2012.02
cp $TOOLCHAIN_PATCH_DIR/defconfig-arm-uclibc .config 

#hosttools
cp $TOOLCHAIN_PATCH_DIR/gmp.mk package/gmp 
cp $TOOLCHAIN_PATCH_DIR/mpfr.mk package/mpfr 
rm package/mpfr/mpfr-3.0.1_p4.patch
cp $TOOLCHAIN_PATCH_DIR/m4.mk package/m4
cp $TOOLCHAIN_PATCH_DIR/autoconf-2.65-texi-patch2.patch package/autoconf 
cp $TOOLCHAIN_PATCH_DIR/autoconf-2.65-port-texi-6.3.patch  package/autoconf
#toolchain 
cp $TOOLCHAIN_PATCH_DIR/900-gcc46-texi.patch toolchain/gcc/4.5.3  
cp $TOOLCHAIN_PATCH_DIR/901_gcc_missing.patch toolchain/gcc/4.5.3 
cp $TOOLCHAIN_PATCH_DIR/902_cfns_fix_mismatch_in_gnu_inline_attributes.patch toolchain/gcc/4.5.3
cp $TOOLCHAIN_PATCH_DIR/gcc-uclibc-4.x.mk toolchain/gcc 
cp $TOOLCHAIN_PATCH_DIR/uClibc-0.9.32.config toolchain/uClibc
cp $TOOLCHAIN_PATCH_DIR/uClibc-0.9.32.1-gen_wctype.patch toolchain/uClibc
rm fs/skeleton/var/cache
mkdir dl_save
cd $FT_REPO_DIR/release/src-rt-6.x.4708/linux
tar cJvf linux-2.6.tar.xz linux-2.6
mv linux-2.6.tar.xz $HOME/buildroot-2012.02/dl_save/linux-2.6.tar.xz
cd $HOME/buildroot-2012.02
make clean
make

cp $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/linux/if_pppox.h output/host/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/linux/if_pppox.h
cp $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/ctype.h output/host/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include
cp -vrf output/host/usr/arm-brcm-linux-uclibcgnueabi/sysroot/lib output/host/usr/lib
rm -rf $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3 
cp -vr output/host/usr $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/
