#! /bin/sh

## fill in username, under which you have installed your local FT-rep
## assuming, that freshtomato-mips repo is cloned to $HOME/freshtomato-mips
PATH="/home/<username>/freshtomato-mips/tools/brcm/hndtools-mipsel-linux/bin:$PATH"
PATH="/home/<username>/freshtomato-mips/tools/brcm/hndtools-mipsel-uclibc/bin:$PATH"


cd $HOME/freshtomato-mips 
git clean -dxf 
git reset --hard

## chechout correct branch by uncommenting needed line

## checkout for RT-Images:
#git checkout mips-master

## checkout for RT-N und RT-AC-images:
git checkout mips-RT-AC

## patching source files, do not store these patches under your FT-repo directory, 
## they should be resident in folder beside FT-repo folder

patch -i $HOME/documents/freshtomato-mips/common.mak.patch $HOME/freshtomato-mips/release/src/router/common.mak
patch -i $HOME/documents/freshtomato-mips/Makefile.linux.patch $HOME/freshtomato-mips/release/src/router/miniupnpd/Makefile.linux
patch -i $HOME/documents/freshtomato-mips/genconfig.sh.patch $HOME/freshtomato-mips/release/src/router/miniupnpd/genconfig.sh

rm -f /home/stephan/freshtomato-mips/release/src/router/nettle/desdata.stamp

# now choose which kind of firmware image is needed and adjust your router model

## uncomment following lines only if RT-AC-Image are needed, 
## and keep the lines for RT- and RT-N-images commented

patch -i $HOME/Dokumente/freshtomato-mips/Makefile_RT-AC.patch $HOME/freshtomato-mips/release/src/router/Makefile
cd release/src-rt-6.x
patch -i $HOME/Dokumente/freshtomato-mips/mksquashfs.c.patch $HOME/freshtomato-mips/release/src-rt-6.x/linux/linux-2.6/scripts/squashfs/mksquashfs.c
make wndr4500v2z ## > build.txt; AIO: z; VPN: e

## uncomment following lines only if RT-N-Images are needed, 
## and keep the lines for RT-AC- and RT-N-images commented

#patch -i $HOME/Dokumente/freshtomato-mips/Makefile_RT-AC.patch $HOME/freshtomato-mips/release/src/router/Makefile
#cd release/src-rt
#patch -i $HOME/Dokumente/freshtomato-mips/mksquashfs.c.patch $HOME/freshtomato-mips/release/src-rt/linux/linux-2.6/scripts/squashfs/mksquashfs.c 
#make n64z ## > build.txt; AIO: z; VPN: e; 

## uncomment following lines only if RT-Images are needed, 
## and keep the lines above for RT-AC-Images and RT-N-images commented

#patch -i $HOME/Dokumente/freshtomato-mips/Makefile_master.patch $HOME/freshtomato-mips/release/src/router/Makefile
#patch -i $HOME/Dokumente/freshtomato-mips/mksquashfs.c.patch $HOME/freshtomato-mips/release/src-rt/linux/linux-2.6/scripts/squashfs/mksquashfs.c
#cd release/src-rt 
#make r2z ## > build.txt; AIO: z; VPN: e; 




