The perl script "libfoo.pl" in FT sources can be used to reduce the file size of libs and bins in FT firmware as much as possible, by removing in these files all symbols that are not used by any of the other libs or bins. Currently, in FT-arm sources the perl script "libfoo.pl" is not working, but as it is not really needed (arm routers have enough size of memory, they don't really need super-shrinked files), it is deactivated in the source code.

To get the perl script "libfoo.pl" included in FT-arm repo working, the following steps are needed:
1. In /release/src-rt-6.x.4708/router/Makefile the usage of libfoo.pl has to be reactivated (done by "Makefile_libfoo.patch") 
2. The perl script "libfoo.pl" needs the following changes (included in libfoo_arm.pl in this repo): 
	- The filename of readelf in the subroutine "load" has to be corrected.
	- Some new libs have to be added with "genSO" commands in the main part of the perl script and with new "fixDynDep" subroutines in the subroutine "fixDyn". Some of the "fixDynDep" subroutines in subroutine "fixDyn" are not needed anymore.

A build script taking care of both step is included in this repo.
