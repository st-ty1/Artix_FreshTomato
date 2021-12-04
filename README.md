# Artix_FreshTomato
HowTo: Build FreshTomato-mips/-arm on Artix host system 


Instead of the packages needed for building FreshTomato on Debian (which are mentioned under step 8-11 in Readme.txt of FT-sources), following packages are needed for building FreshTomato on Artix:
make, gcc, which, autoconf, automake, pkgconf, patch, bison, flex, cmake, rpcsvc-proto, gperf, python, intltool, re2c and gtk-doc

The precompiled 32-bit host-tools of FT need also following packages: lib32-glibc, lib32-gcc-libs and lib32-zlib
(Therefore, don't forget to uncomment the lines of the "Multilib" and the "lib32" section in /etc/pacman.conf).

For generating/editing Artix-specific patches installing of package diffutils should be helpful. If you are working with Artix or Arch Linux 
on wsl2/Windows then you should also install the nano package.

(Makefile_arm_alternate.patch: Instead of removing the *.la-files in router/Makefile, same effect can be reached by amending the *.la-files instead with an amended LIB path. This is done by using Makefile_arm_alternate.patch on Makefile)

With introduction of irq-balance in source code of FT-arm, Makefile_arm.patch is now needed for compiling both arm versions of FT sources on Artix/Arch Linux.
You can apply patch to directly to /release/src-rt-6.x.4708/router/Makefile before starting building process or use one of the supplied patches build_ft-arm7.sh/build_ft-arm.sh of this repo after cloning it locally. Please check if path in the script file to your local FT repo is correct.

In source code of FT-mips, file desdata.stamp in relase/src/router/nettle has to be deleted. arm. You can delete this file just before starting building process or use one of the supplied patches build_ft-mips-RT.sh/build_ft-mips-RT-N/build_ft-mips-RT-AC.sh of this repo after cloning it locally. Please check if path in the script file to your local FT repo is correct.

Best practice:
   - Copy or clone this repo into a subfolder of your home directory. 
   - Make the shell script executable you need for your router model (depending on architecture of CPU of router) .
   - Please have a look into the shell script, as the path to your local FT-repo is defined in FT_REPO_DIR and the path to your local copy/repo of Artix_FreshTomato is defined in FT_PATCHES_DIR. You should change them to your own needs.
   - Start the shell script. Applying of the shell script is only needed, if you are working with "git clean -dxf" (e.g. 1st build after cloning repo, after updating repo, ...) for cleaning sources. If cleaning of sources is done only by "make clean", the start script and patches are not needed anymore. 

BR

st-ty1/\_st_ty/st_ty_
