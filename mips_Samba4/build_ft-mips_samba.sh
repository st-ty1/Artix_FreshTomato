#! /bin/sh

## path to the FT-repo folder
FT_REPO_DIR=$HOME/freshtomato-mips

## path to your local repo of FT-samba4
FT_SAMBA_DIR=$FT_PATCHES_DIR/mips-Samba4

## path to extracted libtirpc-sources
LIBTIRPC_DIR=$HOME/libtirpc_1.1.4


cd $FT_REPO_DIR 
git clean -dxf 
git reset --hard

## for RT-images:
#git checkout mips-master
## for RT-N- and RT-AC-images:
git checkout mips-RT-AC


## patches for samba4
mkdir $FT_REPO_DIR/release/src/router/samba4
cp -rf $FT_SAMBA_DIR/samba-4.9.16/* $FT_REPO_DIR/release/src/router/samba4
cp -rf $FT_SAMBA_DIR/answer_positiv.txt $FT_REPO_DIR/release/src/router/samba4/answer.txt
cp -rf $FT_SAMBA_DIR/Makefile_samba4 $FT_REPO_DIR/release/src/router/samba4/Makefile
patch -i $FT_SAMBA_DIR/Makefile_samba_libtirpc.patch $FT_REPO_DIR/release/src/router/Makefile
mkdir $FT_REPO_DIR/release/src/router/libtirpc
cp -rf $LIBTIRPC_DIR/* $FT_REPO_DIR/release/src/router/libtirpc

## for RT-AC-images:
cd release/src-rt-6.x
make wndr4500v2z 

## only RT-N-Images
#cd release/src-rt
#make n64z  


