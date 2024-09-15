#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout mips-RT-AC

clear

patch -i $FT_PATCHES_DIR/Makefile.patch $FT_REPO_DIR/release/src/router/Makefile

cd release/src-rt

time make r64e #1> log.txt 2>&1
## AIO:z; VPN:e
