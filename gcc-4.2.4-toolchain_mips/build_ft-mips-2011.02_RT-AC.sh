#! /bin/sh

##status FT sources:commit 54e0aac2d817ce12ab1a1223589c4da6c330d732	May 18 2022

## path to the local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-mips

## path to the FreshTomato patches for new mips-toolchain
FT_PATCHES_DIR=$HOME/Artix_FreshTomato/gcc-4.2.4-toolchain_mips

## path to mips-toolchain with gcc 4.2.4 and binutils 2.20.1
FT_TOOLCHAIN_DIR=$HOME/buildroot-2011.02/output/host

export PATH=$FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-4.2.4/usr/bin:$PATH

RT_VERS="src-rt-6.x"

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
##git pull
git checkout mips-RT-AC

clear

### insert new toolchain
rm -rf  $FT_REPO_DIR/tools/brcm
mkdir -p $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-4.2.4/usr
cp -rf $FT_TOOLCHAIN_DIR/usr/* $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-4.2.4/usr

## amended Makefiles
patch -i $FT_PATCHES_DIR/Makefile.patch $FT_REPO_DIR/release/src/router/Makefile
patch -i $FT_PATCHES_DIR/common.mak.patch $FT_REPO_DIR/release/src/router/common.mak

## router/lzma-loader
patch -i $FT_PATCHES_DIR/head.S.patch $FT_REPO_DIR/release/src/lzma-loader/head.S

## router/iperf
patch -i $FT_PATCHES_DIR/endian.h.patch $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-4.2.4/usr/mipsel-linux-uclibc/sysroot/usr/include/endian.h

## router/httpd
patch -i $FT_PATCHES_DIR/ctype.h.patch $FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc-4.2.4/usr/mipsel-linux-uclibc/sysroot/usr/include/ctype.h

## router/libiconv
patch -i $FT_PATCHES_DIR/getprogname.c.patch $FT_REPO_DIR/release/src/router/libiconv/srclib/getprogname.c

## router/nano
patch -i $FT_PATCHES_DIR/getprogname.c.patch $FT_REPO_DIR/release/src/router/nano/lib/getprogname.c


cd $FT_REPO_DIR/release/$RT_VERS

make r64z  #1> log.txt 2>&1