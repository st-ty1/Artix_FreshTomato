#! /bin/sh

## fill in username, under which you have installed your local FT-repo
## assuming, that freshtomato-mips repo is cloned to $HOME/freshtomato-arm

PATH="$PATH:/home/<username>/freshtomato-arm/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/bin"
export PERL5LIB=/usr/share/autoconf:/usr/share/automake-1.16

cd $HOME/freshtomato-arm 
git clean -dxf 
git reset --hard
git checkout shibby-arm7

## patching source files, do not store these patches under your FT-repo directory, 
## they should be resident in folder beside FT-repo folder, 
## e.g. $HOME/documents/freshtomato-arm
patch -i $HOME/documents/freshtomato-arm7/common.mak.patch $HOME/freshtomato-arm/release/src-rt-6.x.4708/router/common.mak
patch -i $HOME/documents/freshtomato-arm7/Makefile_arm7.patch $HOME/freshtomato-arm/release/src-rt-6.x.4708/router/Makefile
patch -i $HOME/documents/freshtomato-arm7/Makefile.linux.patch $HOME/freshtomato-arm/release/src-rt-6.x.4708/router/miniupnpd/Makefile.linux
patch -i $HOME/documents/freshtomato-arm7/genconfig.sh.patch $HOME/freshtomato-arm/release/src-rt-6.x.4708/router/miniupnpd/genconfig.sh

cd release/src-rt-7.x.main/src
make ac3200z
# AIO:z; VPN:e > build.txt
