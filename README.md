# Artix_FreshTomato
HowTo: Build FreshTomato-mips/-arm on Artix host system 


Instead of the packages needed for building FreshTomato on Debian (which are mentioned under step 8-11 in Readme.txt of FT-sources), following packages are needed for building FreshTomato on Artix:
make, gcc, which, autoconf, automake, pkgconf, patch, bison, flex, cmake, rpcsvc-proto, gperf, python, intltool, re2c and gtk-doc

The precompiled 32-bit host-tools of FT need also following packages: lib32-glibc, lib32-gcc-libs and lib32-zlib
(Therefore, don't forget to uncomment the lines of the "Multilib" and the "lib32" section in /etc/pacman.conf).

For generating/editing Artix-specific patches installing of package diffutils should be helpful. If you are working with Artix or Arch Linux 
on wsl2/Windows then you should also install the nano package.

(Makefile_arm_alternate.patch: Instead of removing the *.la-files in router/Makefile, same effect can be reached by amending the *.la-files instead with an amended LIB-path. This is done by using Makefile_arm_alternate.patch on Makefile)

BR

st-ty1/\_st_ty/st_ty_
