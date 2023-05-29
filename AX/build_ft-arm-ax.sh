#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-ax

cd $FT_REPO_DIR
git clean -dxf 
git reset --hard
git pull

git checkout master

clear

sudo ln -s $FT_REPO_DIR/release/src-rt-5.04axhnd.675x/toolchains/brcm /opt/toolchains

export PATH=$PATH:/opt/toolchains/crosstools-aarch64-gcc-9.2-linux-4.19-glibc-2.30-binutils-2.32/usr/bin
export PATH=$PATH:/opt/toolchains/crosstools-arm-gcc-9.2-linux-4.19-glibc-2.30-binutils-2.32/usr/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/toolchains/crosstools-arm-gcc-9.2-linux-4.19-glibc-2.30-binutils-2.32/usr/lib

rm -v $FT_REPO_DIR/release/src-rt-5.04axhnd.675x/toolchains/brcm/crosstools-arm-gcc-9.2-linux-4.19-glibc-2.30-binutils-2.32/lib/libpkgconf.so.3.0.0
rm -v $FT_REPO_DIR/release/src-rt-5.04axhnd.675x/toolchains/brcm/crosstools-aarch64-gcc-9.2-linux-4.19-glibc-2.30-binutils-2.32/lib/libpkgconf.so.3.0.0
patch -i  $FT_PATCHES_DIR/AX/Makefile_ax.patch $FT_REPO_DIR/release/src/router/Makefile
patch -i  $FT_PATCHES_DIR/AX/configure.ac_iperf3.patch $FT_REPO_DIR/release/src/router/iperf3/configure.ac

cd $HOME/freshtomato-ax/release/src-rt-5.04axhnd.675x/
make tuf-ax3000_v2 #1> log.txt 2>&1  #1>log.txt