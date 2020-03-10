# Artix_FreshTomato
HowTo: Build FreshTomato-mips/-arm with Artix host system:

WARNING: Don't start this, if you are not familiar with both - Arch Linux/Artix and the standard building process of FreshTomato!!

1. The packages needed for the building process of FreshTomato (FT) on Artix are listed in needed_packages_on_Artix.txt.
   Most of them can be obtained from Artix repos, some need Arch user repos (AUR). So be familiar with installing progs from AUR.
2. Also some of the files of both FT-repos need some small minor modifications. These mods are listed in attached file
   modification_FT_sources.txt.
3. Best practice:
   - Copy repo (patches and shell scripts) into a subfolder of your home directory. 
   - Make the shell scripts executable.
   - Please have a look into shell scripts, as they expect complete path to your local FT-repo (e.g. for FT-mips: $HOME/freshtomato-mips/). Change it to your own needs.
   - Start your needed shell script (depending on architecture of CPU of router). Applying the shell script is only needed, if you are working with "git clean -dxf" (e.g. 1st build after cloning repo, after updating repo, ...) for cleaning sources.  Cleaning sources only with "make clean" the script is not needed anymore. 

BR
st-ty1

