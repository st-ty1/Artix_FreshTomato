 #! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

PATH="$FT_REPO_DIR/tools/brcm/hndtools-mipsel-uclibc/bin:$PATH"

clear

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
git pull

git checkout mips-master

patch -i $FT_PATCHES_DIR/common.mak.patch $FT_REPO_DIR/release/src/router/common.mak
patch -i $FT_PATCHES_DIR/Makefile_mips.patch $FT_REPO_DIR/release/src/router/Makefile
patch -i $FT_PATCHES_DIR/mksquashfs.c.patch $FT_REPO_DIR/release/src-rt/linux/linux-2.6/scripts/squashfs/mksquashfs.c 
patch -i $FT_PATCHES_DIR/miniupnpd_config.patch $FT_REPO_DIR/release/src/router/miniupnpd/configure

cd release/src-rt 

make z ## > build.txt; AIO: z; VPN: e; mini:f
