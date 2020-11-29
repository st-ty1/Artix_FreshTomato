# Artix_FreshTomato
HowTo: Build FreshTomato-mips/-arm on Artix host system 

!!!! Artix with Freshtomato-arm: working with status of source code commit 3de14151f (20/10/2020)

!!!! Artix with Freshtomato-mips: working with status of source code status commit 2a315a0 (06/11/2020)

WARNING: Don't start this, if you are not familiar with both - Arch Linux/Artix and the standard building process of FreshTomato!!

1. The packages needed for the building process of FreshTomato (FT) on Artix are listed in "needed_packages_on_Artix.txt".

2. Also some of the files of both FT-repos need some small minor modifications. These mods are listed in attached files
   "modification_FT_sources_arm.txt" and "modification_FT_sources_mips.txt" (I'm trying to rechecked the mods fortnightly.)
   Appropriate patches for these mods are located in this repo.
   These modifications are needed as, e.g.:
   - Arch Linux/Artix use more recent versions of applications which are needed for building process.
   - Arch Linux/Artix based systems depends much more on shared libraries than Debian/Ubuntu systems does, so building tools
     like libtool and pkgconfig are more likely misdirected by presence of shared libs of host-OS and will fail.
   - Arch linux/Artix uses bash as non-interactive shell, whereas Debian/Ubuntu uses dash (echo commands of both shells use 
     different flags and escape sequences) 

3. Best practice:
   - Copy or clone this repo into a subfolder of your home directory. 
   - Make the shell script executable you need for your router model (depending on architecture of CPU of router) .
   - Please have a look into the shell script, as the path to your local FT-repo is defined in FT_REPO_DIR and the path to your local copy/repo of Artix_FreshTomato is defined in FT_PATCHES_DIR. You should change them to your own needs.
   - Start the shell script. Applying of the shell script is only needed, if you are working with "git clean -dxf" (e.g. 1st build after cloning repo, after updating repo, ...) for cleaning sources. If cleaning of sources is done only by "make clean", the start script and patches are not needed anymore. 

BR

st-ty1/\_st_ty/st_ty_
