#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout mips-RT-AC
clear

patch -i $FT_PATCHES_DIR/alloca.m4.patch $FT_REPO_DIR/release/src/router/mysql/config/ac-macros/alloca.m4
patch -i $FT_PATCHES_DIR/Makefile_mips.patch $FT_REPO_DIR/release/src/router/Makefile
patch -i $FT_PATCHES_DIR/miniupnpd_config.patch $FT_REPO_DIR/release/src/router/miniupnpd/configure
patch -i $FT_PATCHES_DIR/configure.in_apcupsd.patch $FT_REPO_DIR/release/src/router/apcupsd/autoconf/configure.in
patch -i  $FT_PATCHES_DIR/configure.ac_transmission.patch $FT_REPO_DIR/release/src/router/transmission/configure.ac

cd release/src-rt-6.x

make wndr4500z # z: AIO e: VPN
