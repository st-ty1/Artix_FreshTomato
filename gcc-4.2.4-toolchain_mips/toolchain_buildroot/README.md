Building of mipsel-uClibc-toolchain with buildroot vers. 2011.02 (tested only on Artix/Arch Linux; not tested on Debian/Ubuntu, but should also work).

- Download buildroot-2011.02 from https://buildroot.org/downloads/buildroot-2011.02.tar.gz

- Extract sources into a new folder in your home directory (e.g. $HOME/buildroot-2011.02)

- Copy all patches of gcc, uclibc und binutils of FT- or asuswrt-toolchain to appropriate subfolders in buildroot-2011.02 directory:

   - *</your/path/to/your/local/FT- or asuswrt-repo>*/toolchain/toolchain/gcc/patches to buildroot-2011.02/toolchain/gcc/4.2.4
	
   - *</your/path/to/your/local/FT- or asuswrt-repo>*/toolchain/toolchain/uClibc/patches/0.9.30.1 to buildroot-2011.02/toolchain/uClibc
	
   - *</your/path/to/your/local/FT- or asuswrt-repo>*/toolchain/toolchain/binutils/patches/2.20.1 to buildroot-2011.02/package/binutils/binutils-2.20.1
   

- Create a subfolder dl_save in your local buildroot-2011.02 directory, generate an archive of the linux sources in FT repos (archive has to be named to "linux-2.6.22.19.tar.gz"),  and place archive into the dl_save folder.
		
		mkdir $HOME/buildroot-2011.02/dl_save
		
		cd $HOME/freshtomato-mips/release/src-rt-6.x/linux
		
		tar czvf linux-2.6.tar.gz linux-2.6.22.19
		
		mv linux-2.6.22.19.tar.gz $HOME/buildroot-2011.02/dl_save

- Then, some buildroot files have to be replaced (The mods are listed in detail in modifications_buildroot-files.txt.):
	- Copy .config of this repo to the buildroot-2011.02 directory.
	- Copy kernel-headers.mk in config of this repo to folder buildroot-2011.02/toolchain/kernel-headers.
	- Copy Makefile.in of this repo to folder buildroot-2011.02/packages.
	- Copy uClibc-0.9.30.config and uclibc.mk of this repo to folder buildroot-2011.02/toolchain/uClibc.
	- Copy gcc-uclibc-4.x.mk of this repo to folder buildroot-2011.02/toolchain/gcc. 
	- Copy 1030_gcc_inline_functions.patch of this repo to buildroot-2011.02/toolchain/gcc/4.2.4 .
	- Copy 020-fcommon-gcc10-binutils.patch to buildroot-2011.02/package/binutils/binutils-2.20.1 and buildroot-2011.02/package/binutils/binutils-2.19.1.

- Shell script build_ft-mips-2011.02_RT-AC.sh shows a way, how to integrate this mips-toolchain into the sources of FT (for use with sources of asuswrt-Merlin/John's fork the paths in the script have to be 
  amended respectively), as some patches are also needed.

BR st-ty1\/_st_ty\/st_ty_
