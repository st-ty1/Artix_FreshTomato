mipsel-uClibc-toolchain with buildroot vers. 2011.02 (tested only on Artix/Arch Linux; not tested on Debian/Ubuntu, but should also work).

Here,  an alternate way to build the mips-toolchain with gcc-4.2.4 and uClibc-0.9.30 is provided, based on buildroot software. (There exists some other ways to build this mips-toolchain: by an openwrt-based version, available under https://github.com/wl500g/toolchain or by crosstools-ng. But some of the patches listed have to be inserted).

Shell script build_ft-mips-2011.02_RT-AC.sh shows a way, how to integrate this mips-toolchain into the sources of FT (for use with sources of asuswrt-Merlin/John's fork the paths in the script have to be amended respectively), as some patches are also needed.

Up to now, the patch of the php5 target within the Makefile.patch was one of the most beastly ones to find. The make process of the target of php5 has a libtool compile and a libtool relink command enclosed in only one make command, so all other ways known to me, like to prevent an involvement of libtool or the deletion/amendment of libtool's *.la-files, don't work here anymore. But unclear yet, why this patch of the php5 target in Makefile is not needed by other mips-toolchains with higher gcc-/binutils-/uClibc-versions.

BR st-ty1\/_st_ty\/st_ty_
