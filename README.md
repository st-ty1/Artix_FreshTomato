# Artix_FreshTomato
HowTo: Build FreshTomato-mips/-arm with Artix host system:

WARNING: Don't start this, if you are not familiar with both - Arch Linux/Artix and the standard building process of FreshTomato!!

1. The packages needed for the building process of FreshTomato (FT) on Artix are listed in needed_packages_on_Artix.txt.
   Most of them can be obtained from Artix repos, some need Arch user repos (AUR). So be familiar with installing progs from AUR.
2. Also some of the files of both FT-repos need some small minor modifications. These mods are listed in attached file
   modification_FT_sources.txt.
3. Best practice:
   - Copy patches and shell script into "documents" subfolder of your home directory and complete shell script with your username.
   - Make shell script executable.
   - Please have a look into shell script, where it expects your local FT-repo (e.g. for FT-mips: $HOME/freshtomato-mips/). You can change the path to your own needs.
   - Start shell script. 
BR
st-ty1

