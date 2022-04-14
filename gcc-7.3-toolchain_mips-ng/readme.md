toolchain with gcc-7.3, binutils-2.28.1, uclibc-ng 1.0.28 and kernel headers of FT-sources:

working on Asus RT-N66U (basic functions tested yet, no reboot-loop, no errors in syslog)

patches will be uploaded soon; 

change to toolchain with uclicb-0.9.32.1: 
- no portmap support anymore, need to change to litirpc/rpcbind.  
- amended patch for libfoo.pl as amount of uClibc libraries shrinked to only one.
- amended patch for router/Makefile as amount of uClibc libraries shrinked to only one.
- patch for dhcpv6/timer.c needed

BR
st-ty1
