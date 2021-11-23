
Follow these steps:
1. Copy content of this folder to a directory you have write access (e.g. home directory) and  change into this directory.

2. This step has to be executed only once: An initial docker image is build with all needed packages for building FT sources and a cloned FT-repo of bitbucket.   
    Choose one of the dockerfileaccording to your router's CPU architecture: 
    
    for MIPS-routers:

		docker build -r artixlinux/ft-mips_init -f artix_ft-mips_init .
    
    for ARM-routers:

		docker build -r artixlinux/ft-arm_init -f artix_ft-arm_init .

2. Build an add-on image, based on init-image of step 1., with updating Archlinux packages and cloning Artix_Freshtomato repo.
   Choose one of the dockerfiles according to the CPU architecture and the supported SDK version of your router
   
    - for MIPS-routers and RT-N-image:
	
	      docker build -r artixlinux/ft-mips-rt-n -f artix_ft-mips-rt-n .
   
    - for MIPS-routers and RT-AC-image:
	
	      docker build -r artixlinux/ft-mips-rt-ac -f artix_ft-mips-rt-ac .
   
    - for MIPS-routers and RT-image:
	
	      docker build -r artixlinux/ft-mips-rt -f artix_ft-mips-rt .
   
    - for ARM-routers and SDK6-image:
	
	      docker build -r artixlinux/ft-arm -f artix_ft-mips-arm .
   
    - for ARM-routers and SDK7-image:
	
	      docker build -r artixlinux/ft-arm7 -f artix_ft-mips-arm7 .
   
3. For starting the build process of FT, you have to append the firmware type you want to build at the nd of the "docker build" command, and you should also insert the TZ database name of your preferred time zone as environment variable in the "docker build" command (preset time zone: Europe/Berlin). "-v $HOME:/image" is needed to copy the firmware from inside docker container to host of container.
  
    E.g. to get the AIO-version of Asus RT-AC66U:

          docker run -e TZ=XXX/YYY -v $HOME:/image artixlinux/ft-arm ac68e
	  
    The resulting firmware image is located in your $HOME directory.
