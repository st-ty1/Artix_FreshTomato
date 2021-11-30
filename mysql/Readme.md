Modification needed by using CMake for configuring mysql sources (CMake files are included in sources of mysql >=5.1). 

How to use: (actually mysql 5.5.62 is working. Newer version (e.g. 5.6.51) don't work now, because they need some minor but yet unresolved mods.)

 1.) Generate mysql-folder in HOME directory and extract source files into this folder.
 
 2.) Start build script build_ft-arm_mysql_CMake.sh. 

mariadb:
"import_executables" parts in CMake files (which should make cross-compiling much easier) are only included with mariadb (>=5.5; see mysql_mariadb_cmake_autotools.txt). Build scripts files and patches for mariadb will follow (up to those mariadb-versions, where support of libatomic in gcc-compiler is mandantory. The compilers of both arm- and mipsel-toolchain don't supply this support).

BR
st-ty1
