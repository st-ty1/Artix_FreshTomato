New toolchain for FT-arm with gcc-5.3.0 and binutils-2.25.1

All patches for FT-arm sources are enclosed in this repo. The patches are needed as the new toolchain is more sensitive to "inaccuracy" in source code.
Start with shell script build_ft-arm-2016_02_patch.sh.
Tested with Asus RT-AC56U, but only in router mode yet; works for several days without any issues (including wifi 2.4G/5G). 
This toolchain is built with uclibc 0.9.32.1, i.e. yet without NPTL, but seems no issue to replace this uclibc version also by a newer version (0.9.33).
gcc-5.3 can be build with a go-compiler (currently included only C-, C++  - and Fortran-compiler.)

BR
st-ty1/st_ty_
