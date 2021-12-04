#! /bin/sh

FT_PATCHES_DIR=$HOME/Artix_FreshTomato/mysql
FT_REPO_DIR=$HOME/freshtomato-arm
FT_MYSQL_DIR=$HOME/mysql-5.5.62

cd $FT_REPO_DIR

git clean -dxf
git reset --hard
#git pull

git checkout arm-master

clear

# insert mysql sources in FT sources 
rm -rf $FT_REPO_DIR/release/src-rt-6.x.4708/router/mysql 
mkdir -p $FT_REPO_DIR/release/src-rt-6.x.4708/router/mysql 
cp -rf $FT_MYSQL_DIR/* $FT_REPO_DIR/release/src-rt-6.x.4708/router/mysql

## MySQL patches
patch -i $FT_PATCHES_DIR/Makefile_CMake.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/Makefile
patch -i $FT_PATCHES_DIR/CMakeLists.txt.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/mysql/CMakeLists.txt
patch -i $FT_PATCHES_DIR/70_mysql_va_list.patch $FT_REPO_DIR/release/src-rt-6.x.4708/router/mysql/sql-common/client_plugin.c


## standard ARTIX-patches
# look at repo at https://github.com/st-ty1/Artix_FreshTomatoArtix_FreshTomato ; patches may vary


cd $FT_REPO_DIR/release/src-rt-6.x.4708

time make ac68z 
