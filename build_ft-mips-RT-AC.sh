#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
git pull

git checkout mips-RT-AC

clear

patch -i $FT_PATCHES_DIR/Makefile.patch $FT_REPO_DIR/release/src/router/Makefile

cd release/src-rt-6.x

time make z #1> log.txt 2>&1
## Insert you router model in line above; AIO:z; VPN:e