working on it (gcc-7.3, binutils-2.28.1, uclibc 0.93.2.1 , kernel headers kf FT sources). 
carelessly build 1st toolchain with locale support of uClibc, so build process break at libfoo.pl (as expected), as some of the bcrm bin blobs (nas, wl) are not compiled with uclibc and locale support.
Now, 2nd trial, toolchain without locale suport of uclibc is built.
Only one addiktional patch needed (compared to gcc-5.3-toolchain). Need some time to check, if firmware is working.

BR
st_ty_
