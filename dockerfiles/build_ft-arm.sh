#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-arm

cd $HOME/freshtomato-arm 
git clean -dxf 
git reset --hard
#git pull

git checkout arm-master

clear

cd release/src-rt-6.x.4708

make $@

mkdir /image
cp $FT_REPO_DIR/release/src-rt-6.x4708/image/* /image
