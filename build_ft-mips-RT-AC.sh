#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-mips

cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
#git pull

git checkout mips-RT-AC

clear

patch -i $FT_PATCHES_DIR/Makefile.patch $FT_REPO_DIR/release/src/router/Makefile

############# only needed on Artix, when using full graphical desktop environments ##############
# cp -vf $FT_PATCHES_DIR/CMakeLists.txt $FT_REPO_DIR/release/src/router/getdns
# rm $FT_REPO_DIR/release/src/router/nettle/desdata.stamp
# patch -i  $FT_PATCHES_DIR/Makefile_transmission.patch $FT_REPO_DIR/release/src/router/Makefile
##############################################################################
cd release/src-rt-6.x

time make r64e #1> log.txt 2>&1
## Insert you router model in line above; AIO:z; VPN:e
