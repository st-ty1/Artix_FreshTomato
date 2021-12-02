# Artix_Freshtomato-arm_Samba4

How to build Samba 4.11.x for FreshTomato-arm:
1. Download source of samba-4.11.9 (https://download.samba.org/pub/samba/stable/samba-4.11.9.tar.gz) and extract it into a first folder in your home directory.
2. Download source code of libtirpc-1.2.5 (https://sourceforge.net/projects/libtirpc/files/libtirpc/1.2.5/libtirpc-1.2.5.tar.bz2/download) and extract it into a second folder in your home directory.
3. Download source code of gnutls-3.6.13 (https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.13.tar.xz) and extract it into a third folder in your home directory.
4. Download Artix_Freshtomato repo (https://github.com/st-ty1/Artix_FreshTomato) into a forth subfolder of your home directory.
5. Download this repo and extract it into a fifth folder in your home directory.
6. Start building a new arm-uClibc-toolchain (according to https://github.com/st-ty1/arm-uClibc-toolchain_buildroot) into a sixth folder of your home directory. Before building make sure, that in uClibc-0.9.32.config-file the option UCLIBC_SUPPORT_AI_ADDRCONFIG is set: "UCLIBC_SUPPORT_AI_ADDRCONFIG=y". After building is complete, make sure that if_pppox.h and ctype.h from the original toolchain is copied into your new arm-toolchain. (All steps needed in README.md of this repo.)
7. Align the paths in shell script "build_ft-arm_samba-4.11.sh" to your six folders in your home directory of step 1.) -6.).
8. Start shell script "build_ft-arm_samba-4.11.sh".
 
Actual size for ac68z (RT-AC56U; AIO-version): ~22.7 MB

BR st-ty1/st_ty_
