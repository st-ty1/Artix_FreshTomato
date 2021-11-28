Modification of build process by building needed host files instead of copying them as a compressed package into the folder of mysql sources (Autotools- and CMake-versions;  starting with mysql version 5.1 CMake files are included in sources, but relevant "import_executables" parts in CMake files (to make cross-compiling much easier) are only included with mariadb >=5.5 (see mysql_mariadb_cmake_autotools.txt), so I recommend to use CMake for build process only with mariadb >=5.5):


How to use:

 1.) Generate mysql-folder in HOME directory and extract source files into this folder. (only needed for CMake version) 
 
 2.) Start build script (build_ft-arm_mysql_CMake.sh, build_ft-arm_mysql_autotools.sh or build_ft-mips_mysql_autotools.sh available). 

rem.: 
- build_ft-arm_mysql_autotools.sh/build_ft-mips_mysql_autotools.sh are made for using with mysql version 5.1.73. 
  Newer versions of mysql/mariadb may need some minor modifications. 
- build_ft-arm_mysql_CMake.sh is made for mysql 5.5.62. Newer version (5.6.51) actually don't work and need some minor modifications.
- CMake version with mariadb will follow (up to those mariadb-versions, where support of libatomic in gcc-compiler is mandantory. The compilers of both arm- and mipsel-toolchain don't supply this support).

BR
st-ty1
