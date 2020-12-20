#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

PATH="$HOME/freshtomato-mips/tools/brcm/hndtools-mipsel-uclibc/bin:$PATH"

clear
cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard

git checkout mips-RT-AC

patch -i $FT_PATCHES_DIR/common.mak.patch $FT_REPO_DIR/release/src/router/common.mak
patch -i $FT_PATCHES_DIR/Makefile_mips.patch $FT_REPO_DIR/release/src/router/Makefile
patch -i $FT_PATCHES_DIR/mksquashfs.c.patch $FT_REPO_DIR/release/src-rt-6.x/linux/linux-2.6/scripts/squashfs/mksquashfs.c

cd release/src-rt-6.x

make $@

mkdir /image
cp $FT_REPO_DIR/release/src-rt-6.x/image/* /image
