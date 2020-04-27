# Artix_FreshTomato
HowTo: Build FreshTomato-mips/-arm on Artix host system 

WARNING: Don't start this, if you are not familiar with both - Arch Linux/Artix and the standard building process of FreshTomato!!

(tested with state of source code: 

  freshtomato-mips: commit eae6210, 23/04/20 

freshtomato-arm: commit 5af1533; 27/04/20)

1. The packages needed for the building process of FreshTomato (FT) on Artix are listed in needed_packages_on_Artix.txt.
   Most of them can be obtained from Artix repos, some need Arch user repos (AUR). So be familiar with installing progs from AUR.
2. Also some of the files of both FT-repos need some small minor modifications. These mods are listed in attached file
   modification_FT_sources.txt. Some of the mods are only needed for arm- or for mips-builds, some of them are needed for both. (will be rechecked fortnightly)
   These modifications are needed as:
   - Arch Linux/Artix based systems depends much more on shared libraries than Debian/Ubuntu sytems does, so building tools like libtool and pkgconfig are rather misdirected by presence of host shared libs and will fail.
   - Arch linux/Artix uses bash as non-interactive shell, whereas Debian/Ubuntu uses dash:
      o echo commands of both shells use different flags and escape sequences 
      o with CD_COMPLAINS option is set within bash (default in bash >=4.4), multiple directory arguments to `cd' will cause error messages. 
   
3. Best practice:
   - Copy repo (patches and shell scripts) into a subfolder of your home directory. 
   - Make the shell scripts executable.
   - Please have a look into shell scripts, as they expect complete path to your local FT-repo (e.g. for FT-mips: $HOME/freshtomato-mips/). Change it to your own needs.
   - Start your needed shell script (depending on architecture of CPU of router). Applying the shell script is only needed, if you are working with "git clean -dxf" (e.g. 1st build after cloning repo, after updating repo, ...) for cleaning sources.  Cleaning sources only with "make clean" the script is not needed anymore. 

BR

st-ty1/_st_ty/st_ty_
