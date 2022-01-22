Will come soon, with binutils 2.23/2.25 and patches for kernel 2.6.22.19 and userland progs to build FreshTomato-mips. Currently running on an Asus RT-N66U, in router mode. All userland progs of AIO-version can be compiled; worst was kernel (patch needed for compiling with gcc >= 4.7 https://patchwork.linux-mips.org/project/linux-mips/patch/1337891904-24093-1-git-send-email-sjhill@mips.com does not work as expected with old kernel 2.6.22.19 x like it works with linux 3.x).
Nginx can be build without libatomics_ops (tested), because gcc 5.3 has its own libatomics part.

BR

st-ty1
