!!!!!!!!!!!!!!!!!!!!!!!!

The new toolchain is only tested with Asus RT-N6U (with VPN version). Asus routers are nearly unbrickable in cases this compiled firmware is not working, so that you can switch backto "standard" firmware again. But other routers do not have a CFE mini server to do so.
So with other routers than Asus, you are on your own to risk testing this modified compiled firmware.

!!!!!!!!!!!!!!!!!!!!!!!!

With binutils 2.23 (I'm working on binutils 2.25.1, but need kernel patched) and patches for linux kernel 2.6.22.19 and for userland progs to build FreshTomato-mips. 
Use build_ft-mips-2016_02.sh to build FT-mips. Configs, patches and readme needed for building toolchain by yourself are available in subfolder of this repo or use the already compiled toolchain, enclosed as compressed file in this repo.
Toolchain and patches are only optimized for MIPSR2 routers yet (I don't have any MIPSR1-router for testing firmware; compiling of compressing step of kernel and generation of firmware loader (loader.gz) works, but can't test running on a router.). 
Currently, firmware (VPN-version) is running on an Asus RT-N66U, in router mode (DHCP on wan side; 2g-/5g-wifi on lan side ok). 

All userland progs of the AIO-version can be compiled; worst was kernel (patch needed for compiling with gcc >= 4.7 https://patchwork.linux-mips.org/project/linux-mips/patch/1337891904-24093-1-git-send-email-sjhill@mips.com does not work as expected with old kernel 2.6.22.19, like it works with linux kernels 3.x).
Nginx can be build without libatomics_ops (tested), because gcc 5.3 has its own libatomics part.
With gcc-5.3, there are opportunitues with go source code (currently, cross-toolchain is not created with a go cross-compiler, but it can be configured to be built with.)

BR

st-ty1

Next steps planned:
<<<<<<< HEAD
- get rebuild and shrinked of libptread.so by libfoo.pl working
=======
>>>>>>> ffc7d02 (libpthread working with libfoo.pl)
- switch to binutils 2.25 (same as arm toolchain)
