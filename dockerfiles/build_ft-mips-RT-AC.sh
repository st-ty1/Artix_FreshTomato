#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard

git checkout mips-RT-AC

clear

cd release/src-rt-6.x

make $@

mkdir /image
cp $FT_REPO_DIR/release/src-rt-6.x/image/* /image
