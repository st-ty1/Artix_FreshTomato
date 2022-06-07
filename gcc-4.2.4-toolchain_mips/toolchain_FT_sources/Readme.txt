HowTo: Build the mips-toolchain by source code included in FT sources

1. Replace following files:
	 - <your FT-source folder>/toolchain/include/depends.mk by depends.mk of this repo
 	-  <your FT-source folder>/toolchain/rules.mk by rules.mk of this repo
	-  <your FT-source folder>/toolchain/tools/Makefile by Makefile_tools of this repo
	-  <your FT-source folder>/toolchain/scripts/config/lex.zconf.c_shipped by lex.zconf.c_shipped of this repo
	- <your FT-source folder>/toolchain/toolchain/gcc/Makefile by Makefile_gcc of this repo
	- <your FT-source folder>/toolchain/scripts/config/Makefile by Makefile_config_scripts  of this repo
	- <your FT-source folder>/toolchain/build26.sh by build26.sh of this repo

2. Insert 020-fcommon-gcc10-binutils.patch of this repo in folder<your FT-source folder>/toolchain/toolchain/binutils/patches/2.20.1 .
3. Insert 1030_gcc_inline_functions.patch of this repo in folder <your FT-source folder>/toolchain/toolchain//gcc/patches/4.2.4 .

4. Goto <your FT-source folder>/toolchain and start build process with script file build.sh .
