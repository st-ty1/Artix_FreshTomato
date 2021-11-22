Modification of build process by building needed host files instead of copying them as a compressed package into the folder of mysql sources (Autotools- and CMake-versions;  starting with mysql version 5.1 CMake files are included in sources, but relevant "import_executables" parts in CMake files (to make cross-compiling much easier) are only included with mariadb >=5.5 (see mysql_mariadb_cmake_autotools.txt), so it is recommended to use CMake for build process only with mariadb >=5.5):
How to use:
 1.) Generate mysql-folder in HOME directory and extract source files into this folder.(only needed for CMake version) 
 2.) Start build script (build_ft-arm_mysql_cmake.sh, build_ft-arm_mysql.sh or build_ft-mips_mysql.sh available). 

rem.: 
- Autotools version of Makefile patch is created for mysql-5.1.73. 
- version with mariadb/CMake will follow (up to those mariadb-versions, where support of libatomic in gcc-compiler is mandantory. The compilers of both arm- and mipsel-toolchain don't supply this support).

BR
st-ty1
