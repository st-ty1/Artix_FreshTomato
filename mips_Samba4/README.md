# Artix_Freshtomato-mips_Samba4
How to build Samba4 for FreshTomato-mips
(samba.4.9 is the lastest samba4-version, which can be compiled by the mipsel-toolchain, used in Freshtomato. As with samba 4.10 gnutls is needed which itself can only be built with obligatory TLS (thread-local storage)-support, but actual mips-uClibc toolchains do not provided thread local support.)

Steps needed:

1.) Download source of samba-4.9.18 (https://download.samba.org/pub/samba/samba-4.9.18.tar.gz) and extract it into a first subfolder of your home directory.

2.) Download this repo into a second subfolder of your home directory. 

3.) Download Artix_Freshtomato repo (https://github.com/st-ty1/Artix_FreshTomato) into third subfolder of your home directory. 

4.) Download source of libtirpc_1.1.4 (https://sourceforge.net/projects/libtirpc/files/libtirpc/1.1.4/libtirpc-1.1.4.tar.bz2/download) and extract it into a forth subfolder of your home directory.(samba4 depends on libtirpc) 

5.) Change the sym-link to python in /usr/bin to from python3 to python2 (Artix/Arch Linux OS).

6.) Start shell script build_ft-mips_samba.sh of local copy of this repo. (This script-file patches FT-sources for use on Artix/Arch Linux, inserts samba4 sources, the samba4-own Makefile, the answer-file (need for cross-compiling samba4 with waf) and libtirpc sources into FT-sources. It modifies also the Makefile of FT by inserting new targets for libtirpc and replaces two positions "samba3" by "samba4".)
 
Remember that install-target of this Makefile is not optimized yet, i.e. also libfoo.pl has to be adapted because of newer and more libraries, which can be striped compared to samba-3.6.

BR
st-ty1/_st_ty/st_ty_
