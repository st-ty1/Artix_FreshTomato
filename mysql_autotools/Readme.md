Modification of build process by buiklding needed host files instead of copying them as a compressed package in the mysql source folder.
Autotool- and Cmake-version. Cmake ois nly available with mysql >= 5.5 (and and all mariadb-Version); generate folder in HOME directory (e.g. $HOME/mysql-5.5.62) and copy source files of mysql-5.5.62 in this folder.
Version with mariadb (up to those mariadb-versions, where support of libatomic in gcc-compiler is mandantory. The compilers of both arm- and mipsel-toolchain don't supply this support) will follow.
