#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
git pull

git checkout mips-master

clear

cd release/src-rt

make $@

mkdir /image
cp $FT_REPO_DIR/release/src-rt/image/* /image
