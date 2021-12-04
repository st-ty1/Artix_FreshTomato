#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout mips-RT-AC

rm -f $FT_REPO_DIR/release/src/router/nettle/desdata.stamp

cd release/src-rt 

make r64z ## > build.txt; AIO: z; VPN: e; 
