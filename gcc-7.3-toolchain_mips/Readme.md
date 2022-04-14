toolchain with gcc-7.3, binutils-2.28.1, uclibc 0.9.32.1 and kernel headers of FT-sources:
 
Only two additional patches needed (compared to gcc-5.3-toolchain). 

Start with build_ft-mips-2016_02_RT-AC.sh script. 
(Paths in this script can be changed to your needs; script only available for RT-AC routers, yet.)
Checked with Asus RT-N66U: working (i.e. no reboot-loop and no errors in syslog), only tested basic functions.

BR

st_ty_
