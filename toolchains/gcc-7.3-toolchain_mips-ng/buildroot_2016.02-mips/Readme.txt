1.) Download and extract sources of buildroot-2016.02 (https://buildroot.org/downloads/buildroot-2016.02.tar.bz2) into a new subfolder of your $HOME directory (e.g. $HOME/buildroot-2016.02_mips_7.3-ng). From now, this is the path of local buildroot-2016.02 directory.
2.) Copy m4-1.4.17-glibc-change-work-around.patch and m4-1.4.18-glibc-sigstksz.patch of this repo into package/m4 subfolder of your local buildroot-2016.02 directory.  
3.) Download buildroot-2013.11 sources (https://buildroot.org/downloads/buildroot-2013.11.tar.bz2), extract them into a temporary folder and copy the subfolder package/uclibc into the /package subfolder of your local buildroot-2016.02 directory.
4.) Copy .config_2016.02_mod_binutils2.28.1_uclibc-ng_mips of this repo into buildroot-2016.02 folder and rename it to .config. 
5.) Download buildroot-2018.02 sources (https://buildroot.org/downloads/buildroot-20108.02.tar.bz2), extract them into a temporary folder and copy the subfolders: 
	- package/gcc/7.3.0, package/gcc/gcc.hash und Config.in.host into the /package/gcc subfolder of your local buildroot-2016.02 directory
	- packages/binutils into the /package subfolder of your local buildroot-2016.02 directory
      Copy gcc.mk of this repo into /package/gcc subfolder of your local buildroot-2016.02 directory .
6.) Copy socket.h.patch into  /package/linux-header subfolder of your local buildroot-2016.02 directory.
7.) Replace uClibc-ng.config in package/uclibc subfolder of your local buildroot-2016.02 directory by uClibc-ng.config of this package. 
9.) Create a subfolder dl_save in your local buildroot-2016.02 directory, generate an archive of the linux sources in FT repos (archive has to be named to "linux-2.6.tar.xz"),  and place archive into the dl_save folder.
		mkdir $HOME/buildroot-2016.02_mips/dl_save		
		cd $HOME/freshtomato-mips/release/src-rt-6.x/linux
		tar cJvf linux-2.6.tar.xz linux-2.6
		mv linux-2.6.tar.xz $HOME/buildroot-2016.02_mips/dl_save

10.) Start the building process with "make".
