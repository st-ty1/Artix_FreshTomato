# Artix_FreshTomato
HowTo: Build FreshTomato-mips/-arm on Artix host system 
 
 --- Freshtomato-arm: checked with with commit a2755bb/0975bfe (2020.4.078)
 --- Freshtomato-mips: checked with with commit 34be7de (2020.4.078)

WARNING: Don't start this, if you are not familiar with both - Arch Linux/Artix and the standard building process of FreshTomato!!

1. The packages needed for the building process of FreshTomato (FT) on Artix are listed in needed_packages_on_Artix.txt.
   Most of them can be obtained from Artix repos, some need Arch user repos (AUR). So be familiar with installing progs from AUR.
2. Also some of the files of both FT-repos need some small minor modifications. These mods are listed in attached files
   modification_FT_sources_arm.txt and modification_FT_sources_mips.txt (Mods will be rechecked fortnightly.)
   These modifications are needed as, e.g.:
   - Arch Linux/Artix use more recent versions of applications, needed for building process (still valid for Debian 10; 
     level more comparable with Ubuntu groovy and Debian 11).
   - Arch Linux/Artix based systems depends much more on shared libraries than Debian/Ubuntu sytems does, so building tools
     like libtool and pkgconfig are more likely misdirected by presence of shared libs of host-OS and will fail.
   - Arch linux/Artix uses bash as non-interactive shell, whereas Debian/Ubuntu uses dash:
   
      + echo commands of both shells use different flags and escape sequences 
      
      + with CD_COMPLAINS option is set within bash (default in bash >=4.4), multiple directory arguments to cd command will cause error messages. 
   
3. Best practice:
   - Copy repo (patches and shell scripts) into a subfolder of your home directory. 
   - Make the shell scripts executable.
   - Please have a look into shell scripts, as they expect complete path to your local FT-repo (e.g. for FT-mips: $HOME/freshtomato-mips/). Change it to your own needs.
   - Start your needed shell script (depending on architecture of CPU of router). Applying the shell script is only needed, if you are working with "git clean -dxf" (e.g. 1st build after cloning repo, after updating repo, ...) for cleaning sources.  Cleaning sources only with "make clean" the script is not needed anymore. 

BR

st-ty1/_st_ty/st_ty_
