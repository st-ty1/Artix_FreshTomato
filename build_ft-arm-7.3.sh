#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-arm
FT_TOOLCHAIN_DIR=$HOME/buildroot-2016.02-arm/output

cd $FT_REPO_DIR
git clean -dxf
git reset --hard
#git pull

git checkout arm-master

clear

## insert new toolchain
mkdir $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-uclibc-7.3
cp -rf $FT_TOOLCHAIN_DIR/hndtools-arm-uclibc-7.3/* $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-uclibc-7.3/

patch -i $FT_PATCHES_DIR/Makefile.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile
cp -vf $FT_PATCHES_DIR/target.mak-7.3 $FT_REPO_DIR/release/src-rt-6.x.4708

cd release/src-rt-6.x.4708

time make ac68z #1> log.txt 2>&1
## AIO:z; VPN:e
