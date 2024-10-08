arm-uClibc-toolchain_buildroot
HowTo: Rebuild arm-toolchain (gcc 4.5.3 + uClibc 0.9.3X.X) for FreshTomato with Buildroot (2012.02) 

0.) rsync must be installed.

All of the folwing steps are enclosed in toolchain_arm.sh.

1.) Get the source code of buildroot-2012.02 and extract it into a new folder of your user directory ( e.g."buildroot-2012.02").

2.) Copy defconfig-arm-uclibc to buildroot-2012.02 folder and rename it to .config.
    
3.)  In buildroot-2012.02/toolchain/uClibc/uClibc-0.9.32.config change "#UCLIBC_SUPPORT_AI_ADDRCONFIG is not set" 
    to "UCLIBC_SUPPORT_AI_ADDRCONFIG=y" 

4.) A new version of m4 1.4.19 is needed: copy m4.mk to buildroot-2012.02/packages/m4 and remove m4-1.4.16-001-MB_CUR_MAX.patch in buildroot-2012.02/package/m4

5.) A new version of gmp 6.0.0a  is needed: copy gmp.mk to buildroot-2012.02/package/m4 

6.) A new version of mpfr 3.1.2 is needed: copy mpfr.mk to buildroot-2012.02/package/m4

7.) Copy autoconf-2.65-texi-patch2.patch and autoconf-2.65-port-texi-6.3.patch to buildroot-2012.02/package/autoconf 

8.) Copy 900-gcc46-texi.patch, 901_gcc_missing.patch and 902_cfns_fix_mismatch_in_gnu_inline_attributes.patch to 
      buildroot-2012.02/toolchain/gcc/4.5.3 
   
9.) Replace buildroot-2012.02/toolchain/gcc/gcc-uclibc-4.x.mk by gcc-uclibc-4.x.mk of this repo (Makefile=missing is added to all 3 build-stages of gcc-4.5.3). 

10.) Add uClibc-0.9.32.1-gen_wctype.patch to buildroot-2012.02/toolchain/uClibc  ("wchar-error")
        If you use uclibc-0.33-versions replace "32" by "33" in filenames of the two patches in this folder.
   
11.) Delete buildroot-2012.02/fs/skeleton/var/cache.

12.) Then build the toolchain with:

         cd $HOME/buildroot-2012.02
         make clean
         make

   There is no need for an older gcc-compiler to build the toolchain. I.e., toolchain can be built with gcc 12 (on Artix/Arch-Linux). After building process is  finished, toolchain is located under BR2_STAGING_DIR (if you have chosen default configuration in .config file, this means buildroot-2012.02/output/host/usr).

In order to use this toolchain as toolchain for FT:

13.) Copy hndtools-arm-linux-2.6.36-uclibc-4.5.3/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/linux/if_pppox.h
of original FT-arm-toolchain to buildroot-2012.02/output/host/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/linux/if_pppox.h

14.) Copy hndtools-arm-linux-2.6.36-uclibc-4.5.3/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/ctype.h of original FT-arm-toolchain to buildroot-2012.02/output/host/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include of your toolchain

Replacement of files in steps 1.) and 2.) are needed as these two files has been patched after first release of original FT-arm-toolchain.

15.) Copy content of buildroot-2012.02/output/host/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/lib to buildroot-2012.02/output/host/usr/lib

16.) Remove old original toolchain in your FT-repo. 

17.) Copy new toolchain under buildroot-2012.02/output/host/usr into \<path to your local FT-arm-repo\>/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3 .


