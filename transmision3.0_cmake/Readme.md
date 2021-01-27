transmission has given up support to autotools (autoconf/automake/libtool/intltool) configuring system and supports only cmake building system.
On Artix/Arch Linux, autoconf 2.70 has been introduced at end of 12/20, cooperating with older autotools (like transmission of FT has) only with obstacles.
This is a patch for the Makefile of freshtomato-arm, using cmake as building system of trasmission 3.0 sources. Additionally a file is missing in transmission
sources of FT repo, so it has to be added into the transmission folder, for make cmake working. As this file has not been needed for the autotools configuration
system, no one has missed it up to now.
BR
st-ty1
