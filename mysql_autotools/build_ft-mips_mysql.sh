#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_Freshtomato
FT_REPO_DIR=$HOME/freshtomato-mips

cd $FT_REPO_DIR 
git clean -dxf
git reset --hard
#git pull

git checkout mips-RT-AC
clear

patch -i $FT_PATCHES_DIR/mysql_autotools/Makefile_autotools.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile

## standard ARTIX-patches
patch -i $FT_PATCHES_DIR/Makefile_mips.patch $FT_REPO_DIR/release/src/router/Makefile
patch -i $FT_PATCHES_DIR/miniupnpd_config.patch $FT_REPO_DIR/release/src/router/miniupnpd/configure
patch -i $FT_PATCHES_DIR/configure.in_apcupsd.patch $FT_REPO_DIR/release/src/router/apcupsd/autoconf/configure.in
patch -i  $FT_PATCHES_DIR/configure.ac_transmission.patch $FT_REPO_DIR/release/src/router/transmission/configure.ac

cd $FT_REPO_DIR/release/src-rt-6.x
exit
time make wndr4500v2z #1>log.txt 2>&1
# AIO:z; VPN:e > build.txt
