#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-arm

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout arm-sdk7

clear

cd release/src-rt-7.x.main/src

make $@

mkdir /image
cp $FT_REPO_DIR/release/src-rt-7.x.main/image/* /image
