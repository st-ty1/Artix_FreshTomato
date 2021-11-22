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
BR

st-ty1/\_st_ty/st_ty_
