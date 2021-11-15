#! /bin/sh

## path to the local FreshTomato repo
FT_REPO_DIR=$HOME/freshtomato-arm

## path to newly created, modified arm-toolchain
FT_TOOLCHAIN_DIR=$HOME/toolchain-arm_new

## path to your local repo of Artix_Freshtomato-arm_Samba4
FT_SAMBA_DIR=$FT_PATCHES_DIR/arm-Samba4

## path to extracted libtirpc-sources
LIBTIRPC_DIR=$HOME/libtirpc-1.2.5

## path to extracted gnutls-sources
GNUTLS_DIR=$HOME/gnutls-3.6.13

## path to extracted samba-sources
SAMBA_DIR=$HOME/samba-4.11.9


cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard
git checkout arm-master

clear

## inserting modified arm-toolchain in FT-arm source code
rm -rf $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3
cp -rvf $FT_TOOLCHAIN_DIR/hndtools-arm-linux-2.6.36-uclibc-4.5.3 $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains
cp -rvf $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/arm-brcm-linux-uclibcgnueabi/sysroot/lib/* $FT_REPO_DIR/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/lib

## stuff / patches needed for gnutls
rm -rf $FT_REPO_DIR/release/src-rt-6.x.4708/router/gnutls
mkdir $FT_REPO_DIR/release/src-rt-6.x.4708/router/gnutls
cp -rf $GNUTLS_DIR/* $FT_REPO_DIR/release/src-rt-6.x.4708/router/gnutls
rm -f $FT_REPO_DIR/release/src-rt-6.x.4708/router/gnutls/lib/Makefile.in
patch -i $FT_SAMBA_DIR/Makefile_samba_libtirpc_gnutls.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile

## stuff needed for libtirpc
rm -rf $FT_REPO_DIR/release/src-rt-6.x.4708/router/libtirpc
mkdir $FT_REPO_DIR/release/src-rt-6.x.4708/router/libtirpc
cp -rf $LIBTIRPC_DIR/* $FT_REPO_DIR/release/src-rt-6.x.4708/router/libtirpc

## stuff needed for samba4.11
rm -rf  $FT_REPO_DIR/release/src-rt-6.x.4708/router/samba4
mkdir $FT_REPO_DIR/release/src-rt-6.x.4708/router/samba4
cp -rf $SAMBA_DIR/* $FT_REPO_DIR/release/src-rt-6.x.4708/router/samba4
cp -f $FT_SAMBA_DIR/answer_positiv_arm.txt $FT_REPO_DIR/release/src-rt-6.x.4708/router/samba4/answer.txt
cp -f $FT_SAMBA_DIR/Makefile_samba4.11 $FT_REPO_DIR/release/src-rt-6.x.4708/router/samba4/Makefile
patch -p1 -d$FT_REPO_DIR/release/src-rt-6.x.4708/router/samba4 < $FT_SAMBA_DIR/Bug_14164_ASN1_syntax_error.patch

cd $FT_REPO_DIR/release/src-rt-6.x.4708

time make ac68e 

## change ac68e to your Arm-router model if needed
