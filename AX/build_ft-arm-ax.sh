#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato
FT_REPO_DIR=$HOME/freshtomato-ax

cd $FT_REPO_DIR
git clean -dxf 
git reset --hard
git pull

git checkout master

clear

# according to Readme of repo of freshtomato-ax 
sudo ln -s $FT_REPO_DIR/release/src-rt-5.04axhnd.675x/toolchains/brcm /opt/toolchains

# according to Readme of repo of freshtomato-ax
export PATH=$PATH:/opt/toolchains/crosstools-aarch64-gcc-9.2-linux-4.19-glibc-2.30-binutils-2.32/usr/bin
export PATH=$PATH:/opt/toolchains/crosstools-arm-gcc-9.2-linux-4.19-glibc-2.30-binutils-2.32/usr/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/toolchains/crosstools-arm-gcc-9.2-linux-4.19-glibc-2.30-binutils-2.32/usr/lib

# Due to setting of LD_LIBRARY_PATH, pkgconf of host-OS Artix Linux is forced to use lib of pkconf, packed with toolchains of freshtomato-ax.
# But both versions seem to differ either in their version number or in way they were build, therefore resulting in error "missing symbols". 
# Easiest way is to simply remove libpkgconf located in freshtomato-ax toolchain folder.
rm -v $FT_REPO_DIR/release/src-rt-5.04axhnd.675x/toolchains/brcm/crosstools-arm-gcc-9.2-linux-4.19-glibc-2.30-binutils-2.32/lib/libpkgconf.so.3.0.0
rm -v $FT_REPO_DIR/release/src-rt-5.04axhnd.675x/toolchains/brcm/crosstools-aarch64-gcc-9.2-linux-4.19-glibc-2.30-binutils-2.32/lib/libpkgconf.so.3.0.0

# Makefaile need only to be patched due to use of Linux Artix as host-OS: Artix uses libxml.so, libdaemon.so and more libs of gcc, even from 
# the start of installation in its base configuration.
patch -i  $FT_PATCHES_DIR/AX/Makefile_ax.patch $FT_REPO_DIR/release/src/router/Makefile

# intermediate patch, only needed with actual iperf3 version; should be obsolete when using higher versions of iperf3 in future
patch -i  $FT_PATCHES_DIR/AX/configure.ac_iperf3.patch $FT_REPO_DIR/release/src/router/iperf3/configure.ac

cd $HOME/freshtomato-ax/release/src-rt-5.04axhnd.675x
make tuf-ax3000_v2 1> log.txt 2>&1  #1>log.txt
