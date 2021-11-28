#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_Freshtomato
FT_REPO_DIR=$HOME/freshtomato-mips

cd $FT_REPO_DIR 
git clean -dxf
git reset --hard
#git pull

git checkout mips-RT-AC

patch -i $FT_PATCHES_DIR/mysql_autotools/Makefile_autotools.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile

cd $FT_REPO_DIR/release/src-rt-6.x

time make wndr4500v2z #1>log.txt 2>&1
# AIO:z; VPN:e > build.txt
