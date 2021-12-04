 #! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

clear

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
git pull

git checkout mips-master


rm -f $FT_REPO_DIR/release/src/router/nettle/desdata.stamp

cd release/src-rt 

make z ## > build.txt; AIO: z; VPN: e; mini:f
