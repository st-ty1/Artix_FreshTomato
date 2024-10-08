# Artix_FreshTomato
HowTo: Build FreshTomato-mips/-arm on Artix host system 

For actual issues, please look at ToDos.txt.

Following packages are needed for building FreshTomato on Artix:
make, gcc, which, autoconf, automake, pkgconf, patch, bison, flex, cmake, rpcsvc-proto, gperf, python, intltool, re2c, gtk-doc, wget, git and ninja.

The precompiled 32-bit host-tools of FT need also following packages: lib32-glibc, lib32-gcc-libs and lib32-zlib
(Therefore, don't forget to uncomment the lines of the "lib32" section in /etc/pacman.conf).

If you are working with Artix or Arch Linux 
on wsl2/Windows then you should also install the nano package or you can use a smart editor on Windows (like Notepad++).

It is recommended to use Artix on wsl2/Windows or as a VM  (for both approaches there is a manual in this repo) without (!) any desktop environment or unneeded packages, to keep the number of needed patches as low as possible. 
Any additional package, like graphical environments, can require additional patches (e.g. have a look at build_ft-mips-RT-AC.sh),
 as executables on Artix/Arch Linux are build with shared libs, which can mislead the building tools used by FT sources, at worst.

At the moment, only Makefile.patch is needed for compiling FT sources on Artix/Arch Linux.
You can apply patch to directly to .../router/Makefile before starting building process or use one of the supplied scripts of this repo after cloning it locally. Please check if path in the script file to your local FT repo is correct.

Best practice:
   - Copy or clone this repo into a subfolder of your home directory. 
   - Make the shell script executable you need for your router model (depending on architecture of CPU of router) .
   - Please have a look into the shell script, as the path to your local FT-repo is defined in FT_REPO_DIR and the path to your local copy/repo of Artix_FreshTomato is defined in FT_PATCHES_DIR. You should change them to your own needs.
   - Start the shell script. Applying of the shell script is only needed, if you are working with "git clean -dxf" (e.g. 1st build after cloning repo, after updating repo, ...) for cleaning sources. If cleaning of sources is done only by "make clean", the start script and patches are not needed anymore. 

BR

st-ty1/\_st_ty/st_ty_
