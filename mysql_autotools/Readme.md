Modification of build process by building needed host files instead of copying them as a compressed package into the folder of mysql sources (Autotools- and CMake-versions;  CMake files are included with mysql versions >=5.1, but relevant import_executables parts (to make cross-compiling much easier) are only included starting with mysql >= 5.5 and with mariadb >=5.5 (see mysql_mariadb_cmake_autotools.txt), so it is recommended to use CMake for build process only with versions >=5.5):
Only for CMake version: Generate mysql-folder in HOME directory and extract source files into this folder. 
CMake and autotools version: Start build script (build_ft-arm_mysql_cmake.sh, build_ft-arm_mysql.sh or build_ft-mips_mysql.sh available). 

rem.: version with mariadb/CMake will follow (up to those mariadb-versions, where support of libatomic in gcc-compiler is mandantory. The compilers of both arm- and mipsel-toolchain don't supply this support).
