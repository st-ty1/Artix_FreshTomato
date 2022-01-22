Will come soon, with binutils 2.23/2.25 and patches for kernel 2.6.22.19 and for userland progs to build FreshTomato-mips. Optimized only for MIPSR2 (I don't have any  MIPSR1-router for testing.). Currently, firmware running on an Asus RT-N66U, in router mode (DHCP on wan side). All userland progs of AIO-version can be compiled; worst was kernel (patch needed for compiling with gcc >= 4.7 https://patchwork.linux-mips.org/project/linux-mips/patch/1337891904-24093-1-git-send-email-sjhill@mips.com does not work as expected with old kernel 2.6.22.19, like it works with linux kernels 3.x).
Nginx can be build without libatomics_ops (tested), because gcc 5.3 has its own libatomics part.
With gcc-5.3 there are opportunitues with go (currently, cross-toolchain is not created with a go cross-compiler, but it can be configured to be built with.)

BR

st-ty1
