#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout mips-master

clear

patch -i $FT_PATCHES_DIR/Makefile.patch $FT_REPO_DIR/release/src/router/Makefile

cd release/src-rt

time make r2z #1> log.txt 2>&1
## AIO:z; VPN:e
