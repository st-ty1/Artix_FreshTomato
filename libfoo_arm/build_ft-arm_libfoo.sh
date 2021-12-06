#! /bin/sh

## path to the local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-arm

## path to the local libfoo repo
LIBFOO_DIR=$HOME/Artix_FreshTomato/libfoo_arm

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
git checkout arm-master

clear

#libfoo_arm
cp -v $LIBFOO_DIR/libfoo_arm.pl $FT_REPO_DIR/release/src-rt-6.x.4708/btools/libfoo.pl
patch -i $LIBFOO_DIR/Makefile_libfoo.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile

cd $FT_REPO_DIR/release/src-rt-6.x.4708

time make ac68z ## AIO: z; VPN: e

## change ac68e to your Arm-router model if needed
