#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

clear
cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout mips-RT-AC

rm -f $FT_REPO_DIR/relase/src/router/nettle/desdata.stamp

cd release/src-rt-6.x

make wndr4500z # z: AIO e: VPN
