1.) Download and extract sources of buildroot-2016.02 (https://buildroot.org/downloads/buildroot-2016.02.tar.bz2) into a new subfolder of your $HOME directory (e.g. $HOME/buildroot-2016.02_mips). From now, this is the path of local buildroot-2016.02 directory.
2.) Copy m4-1.4.17-glibc-change-work-around.patch and of this repo into package/m4 subfolder of your local buildroot-2016.02 directory.  
3.) Download buildroot-2013.11 sources (https://buildroot.org/downloads/buildroot-2013.11.tar.bz2), extract them into a temporary folder and copy the subfolder package/uclibc into the /package subfolder of your local buildroot-2016.02 directory 
4.) Copy .config_2016.02_mipsr2_binutils_xxx of this repo into buildroot-2016.02 folder and rename it to .config. (This will replace "BR2_UCLIBC_CONFIG="toolchain/uClibc/uClibc-0.9.32.config" by "BR2_UCLIBC_CONFIG="package/uclibc/uClibc-0.9.32.config")
5.) Download buildroot-2018.02 sources (https://buildroot.org/downloads/buildroot-20108.02.tar.bz2), extract them into a temporary folder and copy the subfolders 
	- package/gcc/7.3.0, package/gcc/gcc.hash and Config.in.host into the /package/gcc subfolder of your local buildroot-2016.02 directory
	- packages/binutils into the /package subfolder of your local buildroot-2016.02 directory
    Copy gcc.mk of this repo into /package/gcc subfolder of your local buildroot-2016.02 directory.
6.) Replace uclibc.mk in package/uclibc subfolder of your local buildroot-2016.02 directory by uclibc.mk of this package.
7.) Replace uClibc-0.9.32.config in package/uclibc subfolder of your local buildroot-2016.02 directory by uClibc-0.9.32.config_nptl of this package. 
8.) Copy uClibc-0.9.32.1-gen_wctype.patch (and for versions with nptl also 0071-Fix-libgcc_s_resume-issue.patch) of this repo into packages/uclibc/0.9.32.1 folder of your local buildroot-2016.02 directory.
9.) Ccreate subfolder dl_save in your local buildroot-2016.02 directory, generate an archive of the linux sources in FT repos (file name has to be "linux-2.6.tar.xz") and place the archive into the dl_save folder:
		mkdir $HOME/buildroot-2016.02_mips/dl_save		
		cd $HOME/freshtomato-mips/release/src-rt-6.x/linux
		tar cJvf linux-2.6.tar.xz linux-2.6
		mv linux-2.6.tar.xz $HOME/buildroot-2016.02_mips/dl_save
		
10.) Start the building process with "make".
11.) After build process is finished, copy interp.os from subfolder output/build/uclibc-0.9.32.1/lib to subfolder output/host/usr/mipsel-brcm-linux-uclibc/sysroot/usr/lib .
