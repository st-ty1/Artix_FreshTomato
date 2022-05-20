1.) Download and extract sources of buildroot-2021.11.1 (https://buildroot.org/downloads/buildroot-2021.11.1.tar.bz2) into a new subfolder of your $HOME directory (e.g. $HOME/buildroot-2021.11.1_mips_11.2-ng). From now, this is the path of local 2021.11.1 directory.
2.) Copy config_gcc11.2_binutils2.37_uclibc-ng1.0.40_mips of this repo into buildroot-2021.11.1 folder and rename it to .config. (This configuration is not optimized for mipsr2, so it can be used for also for routers with only mips32/mipsR3000 CPU.) 
3.) Copy socket.h.patch of this repo  into  /package/linux-header subfolder of your local buildroot-2021.11.1 directory.
4.) Create a subfolder dl_save in your local buildroot-2021.11.1 directory, generate an archive of the linux sources in FT repos (archive has to be named to "linux-2.6.tar.xz"),  and place archive into the dl_save folder.
		mkdir $HOME/buildroot-2021.11.1_mips_11.2-ng/dl_save		
		cd $HOME/freshtomato-mips/release/src-rt-6.x/linux
		tar cJvf linux-2.6.tar.xz linux-2.6
		mv linux-2.6.tar.xz $HOME/buildroot-2021.11.1_mips_11.2-ng/dl_save

5.) Start the building process with "make".
