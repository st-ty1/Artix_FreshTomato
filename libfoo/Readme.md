To get the perl script "libfoo.pl" included in FT-arm repo working, the following step are needed:
1. In /release/src-rt-6.x.4708/router/Makefile the usage of libfoo.pl has to be reactivated (done by "Makefile_libfoo.patch") 
2. All shared libaries intended for shrinkage have to be renamed in their \*-install targets in /release/src-rt-6.x.4708/router/Makefile to their SONAMEs. Also, all commands in the \*-install targets creating supplementary symlinks with the alternate library filenames in the $INSTALL-directory have to be commented (done by "Makefile_lib_so.patch"; not yet included).
3. The perl script "libfoo.pl" needs the following changes (integrated in libfoo_arm2.pl, which is included in this repo) 
	- The filename of readelf in the subroutine "load" has to be corrected.
	- Some of the library filenames in the "genSO" command (in the main part of the perl script) and in the subroutine "fixDyn" have to be changed to their real SONAMEs.
	- Some new libs for shrinkage (i.e. the shared libraries of samba, gnutls and libtirpc and some new shared libs from Freshtomato source code) have to be added with "genSO" commands in the main part of the perl script. 
	- The exit command in subroutine "fillGaps" has to be uncommented. Only this ensures a stop of the script with an error code in case of a symbol can't be resolved. 
	- In the command "fixDynDep("minidlna", "libstdc.so.6")" in the subroutine "fixDyn" libstdc.so.6 has to be changed into libstdc++.so.6.

A build script taking care of step 1.-3. is included in this repo.
