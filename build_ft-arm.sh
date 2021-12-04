#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-arm

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout arm-master

clear

patch -i $FT_PATCHES_DIR/Makefile_arm.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile

cd release/src-rt-6.x.4708

time make ac68z #1> log.txt 2>&1
## AIO:z; VPN:e