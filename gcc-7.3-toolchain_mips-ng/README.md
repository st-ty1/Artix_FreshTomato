toolchain with gcc-7.3, binutils-2.28.1, uclibc-ng 1.0.28 and kernel headers of FT-sources:

Start with build_ft-mips-2016_02_RT-AC.sh script. (Paths in this script can be changed to your needs; script only available for RT-AC routers, yet.) Checked with Asus RT-N66U: working (i.e. no reboot-loop and no errors in syslog), only tested basic functions.

changes to toolchain with uclicb-0.9.32.1: 
- no portmap support anymore, need to change to litirpc/rpcbind.  
- amended patch for libfoo.pl as amount of uClibc libraries shrinked to only one.
- amended patch for router/Makefile as amount of uClibc libraries shrinked to only one.
- patch for dhcpv6/timer.c needed

BR
st-ty1
