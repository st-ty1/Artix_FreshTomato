If you are not familiar with the building process of FreshTomato on Artix, read the Readme.md in top directory of this repo, first, and check if you have already installed the packages mentioned there. Do not start building process within a fully featured desktop environment: This will most likely result in additional errors and build process will break. Look at How-to_Artix_on_VM.txt or How-to_Artix_on_wsl2.txt how to use Artix Linux most suitable.

Following packages of Artix have to be installed additionally: 
xxd, bc, rsync, gdisk and inetutils

Some information, which mods and why they are needed, are inserted in build_ft-arm-ax.sh.
Start with build_ft-arm-ax.sh. If you are working with "make clean" (instead of working with "git clean -fdxq && git reset --hard"), 
use of build_ft-arm-ax.sh is needed only for the first time.

BR 
st-ty1
