#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-arm

PATH="$PATH:$FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/bin"

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout arm-sdk7

patch -i $FT_PATCHES_DIR/common.mak.patch $FT_REPO_DIR/release/src-rt-7.x.main/src/router/common.mak
patch -i $FT_PATCHES_DIR/Makefile_arm.patch $FT_REPO_DIR/release/src-rt-7.x.main/src/router/Makefile

cd release/src-rt-7.x.main/src

make $@

mkdir /image
cp $FT_REPO_DIR/release/src-rt-7.x.main/image/* /image
