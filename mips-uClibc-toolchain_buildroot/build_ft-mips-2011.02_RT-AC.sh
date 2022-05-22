#! /bin/sh

##status FT sources: commit  fc63211121c6212b53442d50f5af240159f6a971	01/04/2022

## path to the local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-mips

## path to the FreshTomato patches for new mips-toolchain
FT_PATCHES_DIR=$HOME/Artix_FreshTomato/mips-uClibc-toolchain_buildroot

## path to mips-toolchain with gcc 4.2.4 and binutils 2.20.1
FT_TOOLCHAIN_DIR=$HOME/buildroot-2011.02/output/host

export PATH=$FT_REPO_DIR/tools/brcm/K26/hndtools-mipsel-uclibc/usr/bin:$PATH
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


cd $FT_REPO_DIR/release/$RT_VERS

make r64z  #1> log.txt 2>&1
