HowTo: Rebuild arm-toolchain (gcc 4.5.3 + uClibc 0.9.3X.X) for FreshTomato with Buildroot (2012.02) 


1.) Get the source code of "buildroot-2012.02" which is available from published ASUS GPL codes and copy it into a new folder of your user directory.

2.) Make following script-files in buildroot-directory executable:
	 
    buildroot-2012.02/support/gnuconfig/config.guess 
    buildroot-2012.02/support/dependencies/check-host-tar.sh
    buildroot-2012.02/support/dependencies/dependencies.sh  
    buildroot-2012.02/support/scripts/setlocalversion
    buildroot-2012.02/support/scripts/apply-patches.sh

3.) Copy buildroot-2012.02/dl/defconfig-arm-uclibc to buildroot-2012.02 an rename it to .config.
    Additionally in this .config file, change directory of BR2_STAGING_DIR= to a directory you have write permission to (default: "$(HOST_DIR)/usr").
    
4.) In buildroot-2012.02/toolchain/uClibc/uClibc-0.9.32.config change "#UCLIBC_SUPPORT_AI_ADDRCONFIG is not set" 
    to "UCLIBC_SUPPORT_AI_ADDRCONFIG=y" 

5.) In directory buildroot-2012.02/dl-save 

   - remove link "binutils-2.21.1.tar.bz2" and rename "binutils-2.21.1a.tar.bz2" to "binutils-2.21.1.tar.bz2"
    
   - new version of m4 is needed: download m4-1.4.18.tar.bz2 (https://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.bz2), 
      move it to dl-save and rename it to m4-1.4.16.tar.bz2

6.) Copy m4-1.4.16-glibc-change-work-around.patch to buildroot-2012.02/packages/m4 (because of "texinfo"-error)

7.) Copy autoconf-2.65-texi-patch2.patch and autoconf-2.65-port-texi-6.3.patch to buildroot-2012.02/packages/autoconf 

8.) Copy 900-gcc46-texi.patch, 901_gcc_missing.patch and 902_cfns_fix mismatch in gnu_inline attributes.patch to 
   buildroot-2012.02/toolchain/gcc/4.5.3 
   
9.) Replace buildroot-2012.02/toolchain/gcc/gcc-uclibc-4.x.mk by gcc-uclibc-4.x.mk of this repo (Makefile=missing is added to all 3 build-stages of gcc-4.5.3). 

10.) Add uClibc-0.9.32.1-gen_wctype.patch to buildroot-2012.02/toolchain/uClibc  ("wchar-error")
   If you use uclibc-0.33-versions replace "32" by "33" in filenames of the two patches in this folder.
   
11.) Delete buildroot-2012.02/fs/skeleton/var/cache

12.) Then build the toolchain with:

         cd $HOME/buildroot-2012.02
         make clean
         make

 No older gcc-compiler is needed for building process of toolchain. E.g., toolchain can be built with gcc-10.1.0 (on Artix/Arch-Linux). After building process is finished, toolchain is located under BR2_STAGING_DIR (if you have chosen default configuartion in .config file, this means buildroot-2012.02/output/host/usr).

In order to use this toolchain as toolchain for FT:

1.) Copy hndtools-arm-linux-2.6.36-uclibc-4.5.3/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/linux/if_pppox.h
of original FT-arm-toolchain to buildroot-2012.02/output/host/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/linux/if_pppox.h

2.) Copy hndtools-arm-linux-2.6.36-uclibc-4.5.3/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include/ctype.h of original FT-arm-toolchain to buildroot-2012.02/output/host/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/include of your toolchain

Replacement of files in steps 1.) and 2.) are needed as these two files have been patched after first release of original FT-arm-toolchain.

3.) Copy content of buildroot-2012.02/output/host/usr/arm-brcm-linux-uclibcgnueabi/sysroot/usr/lib to buildroot-2012.02/output/host/usr/lib

4.) Remove old original toolchain in your FT-repo. 

5.) Copy new toolchain under buildroot-2012.02/output/host/usr into \<path to your local FT-arm-repo\>/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3/
