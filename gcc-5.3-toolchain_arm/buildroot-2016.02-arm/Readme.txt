1.) Download and extract sources of buildroot-2016.02 (https://buildroot.org/downloads/buildroot-2016.02.tar.bz2) into a new folder of your $HOME directory (e.g. $HOME/buildroot-2016.02).
2.) Copy m4-1.4.17-glibc-change-work-around.patch of this repo into package/m4 subfolder of your local buildroot-2016.02 directory.  
3.) Download buildroot-2013.11 sources (https://buildroot.org/downloads/buildroot-2013.11.tar.bz2), extract them into a temporary folder and copy the subfolder package/uclibc into the /package subfolder of your local buildroot-2016.02 directory 
4.) Delete .config of your local buildroot-2016.02 directory, copy .config_buildroot-2016.02 of this repo into buildroot-2016.02 folder and rename it to .config. ( will replace "BR2_UCLIBC_CONFIG="toolchain/uClibc/uClibc-0.9.32.config" by "BR2_UCLIBC_CONFIG="package/uclibc/uClibc-0.9.32.config")
5.) Change mirror of isl in package/isl/isl.mk to https://mirror.sobukus.de/files/src/isl/
6.) Change in file package/Makefile.in "HOST_CFLAGS   += $(HOST_CPPFLAGS)" to "HOST_CFLAGS   += $(HOST_CPPFLAGS) -std=c++11" (od.stdc++03)
7.) Replace uclibc.mk in /package/uclibc subfolder of your local buildroot-2016.02 directory by uclibc.mk of this package (XLOCALE issue)
8.) Replace uClibc-0.9.32.config in /package/uclibc subfolder of your local buildroot-2016.02 directory by uClibc-0.9.32.config (or by uClibc-0.9.32.config_nptl, if you want to build a nptl-version) of this package
9.) Copy 910-cfns-fix-mismatch-in-gnu_inline-attributes.patch of this repo in packages/gcc/5.3.0 of your local buildroot-2016.02 directory.
10.) Copy uClibc-0.9.32.1-gen_wctype.patch (and for versions with NPTL also 0071-Fix-libgcc_s_resume-issue.patch) of this repo in packages/uclibc/0.9.32.1 of your local buildroot-2016.02 directory.
11.) Generate a package of the linux sources in FT repos (file name has to be "linux-2.6.tar.xz") and place package into dl_save folder of your local buildroot-2016.02 directory
		cd $HOME/freshtomato-mips/release/src-rt-6.x/linux
		tar cf - linux-2.6/ | xz -z - > linux-2.6.tar.xz
		cp linux-2.6.tar.xz $HOME/buildroot-2016.02_mips/dl_save
12.) Start the building process with "make".
