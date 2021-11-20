# Broadcom Linux Router Makefile
#
# Copyright 2005, Broadcom Corporation
# All Rights Reserved.
#
# THIS SOFTWARE IS OFFERED "AS IS", AND BROADCOM GRANTS NO WARRANTIES OF ANY
# KIND, EXPRESS OR IMPLIED, BY STATUTE, COMMUNICATION OR OTHERWISE. BROADCOM
# SPECIFICALLY DISCLAIMS ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A SPECIFIC PURPOSE OR NONINFRINGEMENT CONCERNING THIS SOFTWARE.
#
#

include common.mak

#TOMATO_EXPERIMENTAL=0

export PARALLEL_BUILD := -j$(shell grep -c '^processor' /proc/cpuinfo)
export HAVE_TOMATO := y


define patch_files
 find patches/$(1) -maxdepth 1 -type f -name '*.patch' | sort -t '\0' -n | while read FILE; do \
  ( if patch -p0 -N -s --dry-run < $$FILE 2>/dev/null; then \
   patch -p0 -N -r - --no-backup-if-mismatch < $$FILE; \
  fi ) \
 done
endef

define unpatch_files
 find patches/$(1) -maxdepth 1 -type f -name '*.patch' | sort -t '\0' -n -r | while read FILE; do \
  ( if patch -p0 -Rf --dry-run --silent < $$FILE 2>/dev/null; then \
   patch -p0 -R -N -E -r - --no-backup-if-mismatch < $$FILE; \
  fi ) \
 done
endef

define CMAKE_CrossOptions
 ( \
  echo "SET(CMAKE_CROSSCOMPILING \"TRUE\")" >>$(1); \
  echo "SET(TOP $(TOP))" >>$(1); \
  echo "SET(CMAKE_SYSTEM_NAME Linux)" >>$(1); \
  echo "SET(CMAKE_SYSTEM_VERSION $(LINUX_KERNEL))" >>$(1); \
  echo "SET(CMAKE_SYSTEM $(PLATFORM))" >>$(1); \
  echo "SET(CMAKE_SYSTEM_PROCESSOR $(ARCH))" >>$(1); \
  echo "SET(CMAKE_C_COMPILER $(CC))" >>$(1); \
  echo "SET(CMAKE_CXX_COMPILER $(CXX))" >>$(1); \
  echo "SET(CMAKE_AR $(AR))" >>$(1); \
  echo "SET(CMAKE_LINKER $(LD))" >>$(1); \
  echo "SET(CMAKE_NM $(NM))" >>$(1); \
  echo "SET(CMAKE_OBJCOPY $(OBJCOPY))" >>$(1); \
  echo "SET(CMAKE_OBJDUMP $(OBJDUMP))" >>$(1); \
  echo "SET(CMAKE_RANLIB $(RANLIB))" >>$(1); \
  echo "SET(CMAKE_STRIP $(STRIP))" >>$(1); \
  echo "SET(CMAKE_FIND_ROOT_PATH $(TOOLCHAIN))" >>$(1); \
  echo "SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >>$(1); \
  echo "SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >>$(1); \
  echo "SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >>$(1); \
 )
endef


#
#
#
SEP=`$(eval progress=$(shell echo $$(($(progress)+1))))` \
printf "\n\033[41;1m   $@ ${progress}$\/${totalSteps} \033[0m\033]2;Building $@ ${progress}$\/${totalSteps}\007\n"


ifeq ($(TCONFIG_OPTIMIZE_SIZE),y)
OPTSIZE_FLAG :=
else
export OPTSIZE_FLAG := -DNO_OPTSIZE
endif

ifeq ($(TCONFIG_OPTIMIZE_SIZE_MORE),y)
OPTSIZE_MORE_FLAG :=
else
export OPTSIZE_MORE_FLAG := -DNO_OPTSIZE
endif


#
# standard packages
#
obj-y += minidlna
obj-y += lzma-loader
obj-y += shared
obj-y += nvram
obj-y += et
obj-y += libbcmcrypto
obj-y += wlconf
obj-y += prebuilt
obj-y += igmpproxy
obj-y += rc
obj-y += iptables
obj-y += iproute2
obj-y += rom
obj-y += others
obj-y += busybox
obj-y += httpd
obj-y += www
obj-y += bridge
obj-y += dnsmasq
obj-y += etc
obj-y += pppd
obj-y += rp-pppoe
obj-y += utils
obj-y += rstats
obj-y += cstats
obj-y += udpxy
ifeq ($(TCONFIG_IPERF),y)
obj-y += iperf
endif

ifneq ($(TCONFIG_TOR)$(TCONFIG_MEDIA_SERVER)$(TCONFIG_BBT),)
obj-y += zlib
endif

obj-$(TCONFIG_BBT) += libcurl
obj-$(TCONFIG_BBT) += transmission

ifneq ($(TCONFIG_HTTPS),)
ifeq ($(TCONFIG_OPENSSL11),y)
obj-y += openssl-1.1
export OPENSSLDIR = openssl-1.1
else
obj-y += openssl
export OPENSSLDIR = openssl
endif
else
obj-y += cyassl
endif

DNSSEC_BACKEND :=
DNSSEC_OPENSSL :=
DNSSEC_NETTLE :=
ifeq ($(TCONFIG_DNSSEC),y)
ifneq ($(TCONFIG_HTTPS),)
ifneq ($(TCONFIG_OPENSSL11),)
DNSSEC_BACKEND := $(OPENSSLDIR)
DNSSEC_OPENSSL := y
else
obj-y += nettle
DNSSEC_BACKEND := nettle
DNSSEC_NETTLE := y
endif
endif
endif

ifneq ($(TCONFIG_TOR)$(TCONFIG_NFS)$(TCONFIG_BBT),)
obj-y += libevent
endif
ifneq ($(TCONFIG_MEDIA_SERVER)$(TCONFIG_NGINX),)
obj-y += sqlite
endif
ifneq ($(TCONFIG_NGINX)$(TCONFIG_NANO),)
obj-y += libncurses
endif

obj-$(TCONFIG_TOR) += tor
obj-$(TCONFIG_DNSCRYPT) += libsodium
obj-$(TCONFIG_DNSCRYPT) += dnscrypt
obj-$(TCONFIG_STUBBY) += libyaml
obj-$(TCONFIG_STUBBY) += getdns
obj-$(TCONFIG_SNMP) += snmp
obj-$(TCONFIG_SDHC) += mmc

obj-y += mssl
obj-y += mdu
obj-$(TCONFIG_RAID) += mdadm

ifneq ($(TCONFIG_USB)$(TCONFIG_NFS),)
obj-y += e2fsprogs
endif
obj-$(TCONFIG_NFS) += portmap
obj-$(TCONFIG_NFS) += libnfsidmap
obj-$(TCONFIG_NFS) += nfs-utils

#Roadkill
obj-$(TCONFIG_NOCAT) += glib
obj-$(TCONFIG_NOCAT) += nocat

# !!TB
obj-$(TCONFIG_USB) += p910nd
obj-$(TCONFIG_USB) += comgt
obj-$(TCONFIG_USB) += uqmi
obj-$(TCONFIG_USB) += pdureader
obj-$(TCONFIG_USB) += sd-idle

obj-$(TCONFIG_UPS) += apcupsd

obj-y += libusb10
obj-y += usbmodeswitch
obj-$(TCONFIG_FTP) += vsftpd

ifeq ($(TCONFIG_USB_EXTRAS),y)
NEED_EX_USB = y
endif
ifeq ($(TCONFIG_MICROSD),y)
NEED_SD_MODULES = y
endif

ifeq ($(TCONFIG_IPV6),y)
export TCONFIG_IPV6 := y
else
TCONFIG_IPV6 :=
endif

ifeq ($(TCONFIG_IPSEC),y)
export TCONFIG_IPSEC := y
else
TCONFIG_IPSEC :=
endif

ifeq ($(TCONFIG_RAID),y)
export TCONFIG_RAID := y
else
TCONFIG_RAID :=
endif

ifeq ($(TCONFIG_AIO),y)
export CFLAG_OPTIMIZE = -O3
else
export CFLAG_OPTIMIZE = -Os
endif

obj-$(TCONFIG_SAMBASRV) += samba3
obj-$(TCONFIG_SAMBASRV) += wsdd2

ifeq ($(CONFIG_BCMWL6),y)
ifeq ($(TCONFIG_UFSD),y)
obj-$(TCONFIG_NTFS) += ufsd
else
obj-$(TCONFIG_NTFS) += ntfs-3g
endif
else
obj-$(TCONFIG_NTFS) += ntfs-3g
endif

obj-$(TCONFIG_EBTABLES) += ebtables
obj-$(TCONFIG_IPV6) += dhcpv6

obj-$(TCONFIG_MEDIA_SERVER) += ffmpeg
#obj-$(TCONFIG_MEDIA_SERVER) += libiconv
obj-$(TCONFIG_MEDIA_SERVER) += libogg
obj-$(TCONFIG_MEDIA_SERVER) += flac
obj-$(TCONFIG_MEDIA_SERVER) += jpeg
obj-$(TCONFIG_MEDIA_SERVER) += libexif
obj-$(TCONFIG_MEDIA_SERVER) += libid3tag
obj-$(TCONFIG_MEDIA_SERVER) += libvorbis
obj-$(TCONFIG_MEDIA_SERVER) += minidlna
MEDIA_SERVER_STATIC=y
INSTALL_ZLIB := $(if $(or $(TCONFIG_BBT)$(TCONFIG_TOR)$(TCONFIG_NGINX),$(if $(MEDIA_SERVER_STATIC),,y)),y,)

#obj-y += libnfnetlink
obj-y += miniupnpd
obj-y += ipset


#
# configurable packages
#
obj-$(TCONFIG_L2TP) += xl2tpd
obj-$(TCONFIG_PPTP) += accel-pptp
obj-$(TCONFIG_PPTPD) += pptpd
obj-$(TCONFIG_SSH) += dropbear
obj-$(TCONFIG_ZEBRA) += zebra
obj-$(TCONFIG_LZO) += lzo
ifeq ($(TCONFIG_OPTIMIZE_SIZE_MORE),y)
obj-$(TCONFIG_OPENVPN) += openvpn-2.4
else
obj-$(TCONFIG_OPENVPN) += openvpn
endif
obj-$(TCONFIG_OPENVPN) += openvpn_plugin_auth_nvram
obj-$(TCONFIG_TINC) += tinc
obj-$(TCONFIG_EMF) += emf
obj-$(TCONFIG_EMF) += igs

# Tomato RAF
# additional modules for nginx
ifeq (obj-$(TCONFIG_NGINX),y)
ifndef ($(ADDITIONAL_MODULES))
ADDITIONAL_MODULES:=
else
ifeq ($(TCONFIG_IPV6),y)
ADDITIONAL_MODULES += --with-ipv6
endif
endif
endif
obj-$(TCONFIG_NGINX) += mysql
obj-$(TCONFIG_NGINX) += spawn-fcgi
obj-$(TCONFIG_NGINX) += pcre
obj-$(TCONFIG_NGINX) += libatomic_ops
obj-$(TCONFIG_NGINX) += libiconv
obj-$(TCONFIG_NGINX) += libxml2
obj-$(TCONFIG_NGINX) += libpng
obj-$(TCONFIG_NGINX) += jpeg
obj-$(TCONFIG_NGINX) += php
obj-$(TCONFIG_NGINX) += nginx

obj-$(TCONFIG_NANO) += nano

obj-y += hotplug2
obj-y += udevtrigger
obj-y += wanuptime

obj-clean := $(foreach obj, $(obj-y) $(obj-n) $(obj-), $(obj)-clean)
obj-install := $(foreach obj,$(obj-y),$(obj)-install)


#
# Basic rules
#

all: countSteps clean-build libc $(obj-y) kernel

countSteps:
	@totalSteps=0
	@progress=0
	$(foreach n, $(obj-y) $(obj-n) $(obj-), $(eval totalSteps=$(shell echo $$(($(totalSteps)+1)))))
	@echo ${totalSteps}

kernel: $(LINUXDIR)/.config
	@$(SEP)

	@if ! grep -q "CONFIG_EMBEDDED_RAMDISK=y" $(LINUXDIR)/.config ; then \
	    $(MAKE) -C $(LINUXDIR) zImage CC=$(KERNELCC) $(PARALLEL_BUILD); \
	fi
	if grep -q "CONFIG_MODULES=y" $(LINUXDIR)/.config ; then \
	    $(MAKE) -C $(LINUXDIR) modules CC=$(KERNELCC) $(PARALLEL_BUILD); \
	fi
	$(MAKE) -C $(LINUXDIR)/arch/mips/brcm-boards/bcm947xx/compressed srctree=$(LINUXDIR) TCONFIG_MIPSR2=$(TCONFIG_MIPSR2) $(PARALLEL_BUILD)

lzma-loader:
	@$(SEP)
	$(MAKE) -C $(SRCBASE)/lzma-loader CROSS_COMPILE=$(CROSS_COMPILE) TCONFIG_MIPSR2=$(TCONFIG_MIPSR2) $(PARALLEL_BUILD)

lzma-loader-install:

kmod: dummy
	@$(SEP)
	$(MAKE) -C $(LINUXDIR) modules CC=$(KERNELCC) $(PARALLEL_BUILD)

testfind:
	cd $(TARGETDIR)/lib/modules/* && find -name "*.o" -exec mv -i {} . \; || true
	cd $(TARGETDIR)/lib/modules/* && find -type d -delete || true

countInstallSteps:
	@totalSteps=0
	@progress=0
	$(foreach n, $(obj-install), $(eval totalSteps=$(shell echo $$(($(totalSteps)+1)))))
	@echo ${totalSteps}

install package: countInstallSteps $(obj-install) $(LINUXDIR)/.config
	@printf "\n\033[41;1m   Installing \033[0m\033]2;Installing\007\n"
	install -d $(TARGETDIR)


# kernel modules
	$(MAKE) -C $(LINUXDIR) modules_install \
	INSTALL_MOD_STRIP="--strip-debug -x -R .comment -R .note -R .pdr -R .mdebug.abi32 -R .note.gnu.build-id -R .gnu.attributes -R .reginfo" \
	DEPMOD=/bin/true INSTALL_MOD_PATH=$(TARGETDIR)

# nice and clean
ifneq ($(TCONFIG_USBAP),y)
	-cd $(TARGETDIR)/lib/modules/*/kernel/drivers/net && mv diag/* . && rm -rf diag
	-cd $(TARGETDIR)/lib/modules/*/kernel/drivers/net && mv et.4702/* . && rm -rf et.4702 || true
	-cd $(TARGETDIR)/lib/modules/*/kernel/drivers/net && mv usb/* . && rm -rf usb
endif
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/net && mv et/* . && rm -rf et
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/net && mv wl/* . && rm -rf wl
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv cifs/* . && rm -rf cifs
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv jffs2/* . && rm -rf jffs2 || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv jffs/* . && rm -rf jffs || true
	cd $(TARGETDIR)/lib/modules/*/kernel/lib && mv zlib_inflate/* . && rm -rf zlib_inflate || true
	cd $(TARGETDIR)/lib/modules/*/kernel/lib && mv zlib_deflate/* . && rm -rf zlib_deflate || true
	cd $(TARGETDIR)/lib/modules/*/kernel/lib && mv lzo/* . && rm -rf lzo || true
	rm -rf $(TARGETDIR)/lib/modules/*/pcmcia

##!!TB
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv ext2/* . && rm -rf ext2 || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv ext3/* . && rm -rf ext3 || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv jbd/* . && rm -rf jbd || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv fat/* . && rm -rf fat || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv jfs/* . && rm -rf jfs || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv vfat/* . && rm -rf vfat || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv msdos/* . && rm -rf msdos || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv fuse/* . && rm -rf fuse || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv ntfs/* . && rm -rf ntfs || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv smbfs/* . && rm -rf smbfs || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv reiserfs/* . && rm -rf reiserfs || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv hfs/* . && rm -rf hfs || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv hfsplus/* . && rm -rf hfsplus || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv lockd/* . && rm -rf lockd || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv nfsd/* . && rm -rf nfsd || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv nfs/* . && rm -rf nfs || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv xfs/* . && rm -rf xfs || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv nls/* . && rm -rf nls || true
	cd $(TARGETDIR)/lib/modules/*/kernel/fs && mv exportfs/* . && rm -rf exportfs || true
	cd $(TARGETDIR)/lib/modules/*/kernel/net && mv sunrpc/* . && rm -rf sunrpc || true
	cd $(TARGETDIR)/lib/modules/*/kernel/net && mv auth_gss/* . && rm -rf auth_gss || true
	cd $(TARGETDIR)/lib/modules/*/kernel/sound/core && mv oss/* . && rm -rf oss || true
	cd $(TARGETDIR)/lib/modules/*/kernel/sound/core && mv seq/* . && rm -rf seq || true
	cd $(TARGETDIR)/lib/modules/*/kernel/sound && mv core/* . && rm -rf core || true
	cd $(TARGETDIR)/lib/modules/*/kernel/sound && mv usb/* . && rm -rf usb || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/usb && mv hcd/* . && rm -rf hcd || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/usb && mv host/* . && rm -rf host || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/usb && mv storage/* . && rm -rf storage || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/usb && mv serial/* . && rm -rf serial || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/usb && mv core/* . && rm -rf core || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/usb && mv class/* . && rm -rf class || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/usb && mv misc/* . && rm -rf misc || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/usb && mv usbip/* . && rm -rf usbip || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/mmc && mv core/* . && rm -rf core || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/mmc && mv card/* . && rm -rf card || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/mmc && mv host/* . && rm -rf host || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/hid && mv usbhid/* . && rm -rf usbhid || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/input && mv joystick/* . && rm -rf joystick || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/input && mv keyboard/* . && rm -rf keyboard || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/input && mv misc/* . && rm -rf misc || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/input && mv mouse/* . && rm -rf mouse || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/media/video && mv uvc/* . && rm -rf uvc || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/media/video && mv pwc/* . && rm -rf pwc || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/media/video/gspca && mv gl860/* . && rm -rf gl860 || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/media/video/gspca && mv m5602/* . && rm -rf m5602 || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/media/video/gspca && mv stv06xx/* . && rm -rf stv06xx || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/media/video && mv gspca/* . && rm -rf gspca || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/media && mv video/* . && rm -rf video || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/net && mv bcm57xx/* . && rm -rf bcm57xx || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/net && mv emf/* . && rm -rf emf || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/net && mv igs/* . && rm -rf igs || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/net && mv ctf/* . && rm -rf ctf || true
	cd $(TARGETDIR)/lib/modules/*/kernel/drivers/net && mv usb/* . && rm -rf usb || true
	cd $(TARGETDIR)/lib/modules && rm -f */source || true

# misc
	for dir in $(wildcard $(patsubst %,$(INSTALLDIR)/%,$(obj-y))) ; do \
	    (cd $${dir} && tar cpf - .) | (cd $(TARGETDIR) && tar xpf -) \
	done

ifneq ($(TCONFIG_L7),y)
	rm -f $(TARGETDIR)/usr/lib/iptables/libipt_layer7.so
endif

# uClibc
	install $(LIBDIR)/ld-uClibc.so.0 $(TARGETDIR)/lib/
	install $(LIBDIR)/libcrypt.so.0 $(TARGETDIR)/lib/
	install $(LIBDIR)/libpthread.so.0 $(TARGETDIR)/lib/
	install $(LIBDIR)/libgcc_s.so.1 $(TARGETDIR)/lib/
	$(STRIP) $(TARGETDIR)/lib/libgcc_s.so.1
	install $(LIBDIR)/libc.so.0 $(TARGETDIR)/lib/
	install $(LIBDIR)/libdl.so.0 $(TARGETDIR)/lib/
	install $(LIBDIR)/libm.so.0 $(TARGETDIR)/lib/
	install $(LIBDIR)/libnsl.so.0 $(TARGETDIR)/lib/
ifeq ($(TCONFIG_SSH),y)
	install $(LIBDIR)/libutil.so.0 $(TARGETDIR)/lib/
endif
ifeq ($(TCONFIG_USB),y)
	install $(LIBDIR)/librt-0.9.30.1.so $(TARGETDIR)/lib/librt.so.0
endif
ifneq ($(TCONFIG_NGINX)$(TCONFIG_NANO),)
	install $(LIBDIR)/libstdc++.so.6 $(TARGETDIR)/lib/libstdc++.so.6
	cd $(TARGETDIR)/lib && ln -sf libstdc++.so.6 libstdc++.so
	$(STRIP) $(TARGETDIR)/lib/libstdc++.so.6
endif
ifneq ($(TCONFIG_OPTIMIZE_SHARED_LIBS),y)
	install $(LIBDIR)/libresolv.so.0 $(TARGETDIR)/lib/
	$(STRIP) $(TARGETDIR)/lib/*.so.0
endif

	@cd $(TARGETDIR) && $(TOP)/others/rootprep.sh

ifneq ($(TCONFIG_BBT)$(TCONFIG_SAMBASRV),yy)
	@cd $(TARGETDIR) && $(TOP)/others/rootprep.sh ln_usr_share
else
ifeq ($(TCONFIG_TOR),y)
	@cd $(TARGETDIR) && $(TOP)/others/rootprep.sh ln_tor_geoip
endif
endif

	@echo ---

ifeq ($(TCONFIG_OPTIMIZE_SHARED_LIBS),y)
	@$(SRCBASE)/btools/libfoo.pl
else
	@$(SRCBASE)/btools/libfoo.pl --noopt
endif
	@chmod 0555 $(TARGETDIR)/lib/*.so*
	@chmod 0555 $(TARGETDIR)/usr/lib/*.so*

# !!TB - moved to run after libfoo.pl - to make sure shared libs include all symbols needed by extras
# separated/copied extra stuff
	@rm -rf $(PLATFORMDIR)/extras
	@mkdir $(PLATFORMDIR)/extras
	@mkdir $(PLATFORMDIR)/extras/ipsec
	@mkdir $(PLATFORMDIR)/extras/raid
	@mv $(TARGETDIR)/lib/modules/*/kernel/net/ipv4/ip_gre.*o $(PLATFORMDIR)/extras/ || true
#	$(if $(TCONFIG_IPSEC),@cp -f,@mv) $(TARGETDIR)/usr/lib/iptables/libipt_policy.*o $(PLATFORMDIR)/extras/ipsec/ || true

	$(if $(TCONFIG_OPENVPN),@cp -f,$(if $(TCONFIG_USB_EXTRAS),@cp -f,$(if $(TCONFIG_IPV6),@cp -f,@mv))) $(TARGETDIR)/lib/modules/*/kernel/drivers/net/tun.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_EBTABLES),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/bridge/netfilter/ebt*.*o $(PLATFORMDIR)/extras/ || true

	$(if $(TCONFIG_RAID),@cp -f,@mv) $(TARGETDIR)/usr/sbin/mdadm $(PLATFORMDIR)/extras/raid/ || true
	$(if $(TCONFIG_RAID),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/md/*.ko $(PLATFORMDIR)/extras/raid/ || true
	$(if $(TCONFIG_RAID),@ls,@rm -rf) $(TARGETDIR)/lib/modules/*/kernel/drivers/md || true

	@cp $(TARGETDIR)/lib/modules/*/kernel/net/ipv4/netfilter/ip_set*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/net/ifb.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/net/sched/sch_red.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/fs/ntfs.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/fs/smbfs.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/fs/reiserfs.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/fs/jfs.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_NFS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/nfs.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_NFS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/nfsd.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_NFS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/lockd.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_NFS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/exportfs.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_NFS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/sunrpc.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/net/auth_rpcgss.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/net/rpcsec_gss_krb5.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/fs/xfs.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/scsi/sr_mod.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/scanner.*o $(PLATFORMDIR)/extras/ || true

	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/usbserial.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/option.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/sierra.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/cdc-acm.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/net/mii.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/net/cdc_*.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/net/usbnet.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/net/huawei_ether.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/net/rndis_host.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/cdc-wdm.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/net/qmi_wwan.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/ftdi_sio.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/pl2303.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_SD_MODULES),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/mmc/*.*o $(PLATFORMDIR)/extras/ || true
	$(if $(NEED_SD_MODULES),@ls,@rm -rf) $(TARGETDIR)/lib/modules/*/kernel/drivers/mmc || true

	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/ch341.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/usbip*.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/ipw.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/audio.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/ov51*.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/pwc*.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/emi*.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/hid/usbkbd.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/hid/usbmouse.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/net/cdc_subset.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/net/ipheth.*o $(PLATFORMDIR)/extras/ || true
	@rm -rf $(TARGETDIR)/lib/modules/*/kernel/drivers/net/usb || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/media/* $(PLATFORMDIR)/extras/ || true
	@rm -rf $(TARGETDIR)/lib/modules/*/kernel/drivers/media || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/sound/* $(PLATFORMDIR)/extras/ || true
	@rm -rf $(TARGETDIR)/lib/modules/*/kernel/drivers/sound || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/sound/* $(PLATFORMDIR)/extras/ || true
	@rm -rf $(TARGETDIR)/lib/modules/*/kernel/sound || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/input/evdev.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_UPS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/input/* $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_UPS),@ls,@rm -rf) $(TARGETDIR)/lib/modules/*/kernel/drivers/input || true
	$(if $(TCONFIG_UPS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/hid/* $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_UPS),@ls,@rm -rf) $(TARGETDIR)/lib/modules/*/kernel/drivers/hid || true
	@cp -f $(TARGETDIR)/lib/modules/*/kernel/drivers/net/bcm57*.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_CTF),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/net/ctf*.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_PPTP),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/net/pptp.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_L2TP),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/net/pppol2tp.*o $(PLATFORMDIR)/extras/ || true
	@mv $(TARGETDIR)/lib/modules/*/kernel/drivers/net/ppp_deflate.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_IPSEC),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/crypto/*.ko $(PLATFORMDIR)/extras/ipsec/ || true
	$(if $(TCONFIG_IPSEC),@ls,@rm -rf) $(TARGETDIR)/lib/modules/*/kernel/crypto || true
	$(if $(TCONFIG_IPSEC),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/xfrm/*.ko $(PLATFORMDIR)/extras/ipsec/ || true
	$(if $(TCONFIG_IPSEC),@ls,@rm -rf) $(TARGETDIR)/lib/modules/*/kernel/net/xfrm || true
	$(if $(TCONFIG_IPSEC),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/key/*.ko $(PLATFORMDIR)/extras/ipsec/ || true
	$(if $(TCONFIG_IPSEC),@ls,@rm -rf) $(TARGETDIR)/lib/modules/*/kernel/net/key || true
	$(if $(TCONFIG_IPSEC),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/ipv*/xfrm*.ko $(PLATFORMDIR)/extras/ipsec/ || true
#	$(if $(TCONFIG_IPSEC),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/ipv*/tunnel*.ko $(PLATFORMDIR)/extras/ipsec/ || true
	$(if $(TCONFIG_IPSEC),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/ipv*/ah*.ko $(PLATFORMDIR)/extras/ipsec/ || true
	$(if $(TCONFIG_IPSEC),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/ipv*/esp*.ko $(PLATFORMDIR)/extras/ipsec/ || true
	$(if $(TCONFIG_IPSEC),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/ipv*/ipcomp*.ko $(PLATFORMDIR)/extras/ipsec/ || true
#	$(if $(TCONFIG_IPSEC),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/netfilter/xt_policy.ko $(PLATFORMDIR)/extras/ipsec/ || true

	$(if $(TCONFIG_SAMBASRV),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/nls_cp9*.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_SAMBASRV),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/nls_cp1251.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_SAMBASRV),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/nls_euc-jp.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_SAMBASRV),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/nls_sjis.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_SAMBASRV),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/nls_gb2312.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_SAMBASRV),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/nls_euc-kr.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_SAMBASRV),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/nls_big5.*o $(PLATFORMDIR)/extras/ || true

	$(if $(TCONFIG_USB),@cp -f,$(if $(TCONFIG_SDHC),@cp -f,@mv)) $(TARGETDIR)/lib/modules/*/kernel/fs/nls_*.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/usb/*.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/scsi/*.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/leds/*.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,$(if $(TCONFIG_SDHC),@cp -f,@mv)) $(TARGETDIR)/lib/modules/*/kernel/fs/ext2.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/ext3.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,$(if $(TCONFIG_SDHC),@cp -f,@mv)) $(TARGETDIR)/lib/modules/*/kernel/fs/jbd.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/mbcache.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,$(if $(TCONFIG_SDHC),@cp -f,@mv)) $(TARGETDIR)/lib/modules/*/kernel/fs/fat.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,$(if $(TCONFIG_SDHC),@cp -f,@mv)) $(TARGETDIR)/lib/modules/*/kernel/fs/vfat.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/msdos.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/fuse.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_HFS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/hfs.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_HFS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/hfsplus.*o $(PLATFORMDIR)/extras/ || true

ifneq ($(TCONFIG_USB),y)
	@rm -rf $(TARGETDIR)/lib/modules/*/kernel/drivers/usb || true
	@rm -rf $(TARGETDIR)/lib/modules/*/kernel/drivers/scsi || true
	@rm -rf $(TARGETDIR)/lib/modules/*/kernel/drivers/leds || true
endif

	$(if $(TCONFIG_USB_EXTRAS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/connector/cn.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_USB_EXTRAS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/drivers/block/loop.*o $(PLATFORMDIR)/extras/ || true
ifneq ($(TCONFIG_USB_EXTRAS),y)
	@rm -rf $(TARGETDIR)/lib/modules/*/kernel/drivers/connector || true
	@rm -rf $(TARGETDIR)/lib/modules/*/kernel/drivers/block || true
endif
	$(if $(TCONFIG_CIFS),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/cifs.*o $(PLATFORMDIR)/extras/ || true
	$(if $(or $(TCONFIG_BRCM_NAND_JFFS2),$(TCONFIG_JFFS2)),$(if $(TCONFIG_JFFSV1),@mv,@cp -f),@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/jffs2.*o $(PLATFORMDIR)/extras/ || true
	$(if $(or $(TCONFIG_BRCM_NAND_JFFS2),$(TCONFIG_JFFS2)),$(if $(TCONFIG_JFFSV1),@mv,@cp -f),@mv) $(TARGETDIR)/lib/modules/*/kernel/lib/zlib_*.*o $(PLATFORMDIR)/extras/ || true
	$(if $(or $(TCONFIG_BRCM_NAND_JFFS2),$(TCONFIG_JFFS2)),$(if $(TCONFIG_JFFSV1),@cp -f,@mv),@mv) $(TARGETDIR)/lib/modules/*/kernel/fs/jffs.*o $(PLATFORMDIR)/extras/ || true
	[ ! -f $(TARGETDIR)/lib/modules/*/kernel/lib/* ] && rm -rf $(TARGETDIR)/lib/modules/*/kernel/lib || true
	$(if $(TCONFIG_L7),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/ipv4/netfilter/ipt_layer7.*o $(PLATFORMDIR)/extras/ || true
	$(if $(TCONFIG_L7),@cp -f,@mv) $(TARGETDIR)/lib/modules/*/kernel/net/netfilter/xt_layer7.*o $(PLATFORMDIR)/extras/ || true

	@mkdir -p $(PLATFORMDIR)/extras/apps
	@mkdir -p $(PLATFORMDIR)/extras/lib

	@mv $(TARGETDIR)/usr/sbin/ttcp $(PLATFORMDIR)/extras/apps/ || true
	@mv $(TARGETDIR)/usr/sbin/mii-tool $(PLATFORMDIR)/extras/apps/ || true
	@cp -r $(TARGETDIR)/usr/sbin/robocfg $(PLATFORMDIR)/extras/apps/ || true

	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/usr/lib/libusb* $(PLATFORMDIR)/extras/lib/ || true
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/usr/sbin/usb_modeswitch $(PLATFORMDIR)/extras/apps/ || true
	@cp usbmodeswitch/usb_modeswitch.conf $(PLATFORMDIR)/extras/apps/usb_modeswitch.conf || true
	@mkdir -p $(PLATFORMDIR)/extras/apps/usb_modeswitch.d
	@cp -f usbmodeswitch/data/usb_modeswitch.d/* $(PLATFORMDIR)/extras/apps/usb_modeswitch.d || true
ifneq ($(NEED_EX_USB),y)
	@rm -rf $(TARGETDIR)/rom/etc/usb_modeswitch.d || true
	@rm -f  $(TARGETDIR)/rom/etc/usb_modeswitch.conf || true
endif
	$(if $(NEED_EX_USB),@cp -f,@mv) $(TARGETDIR)/usr/sbin/chat $(PLATFORMDIR)/extras/apps/ || true

	@mkdir -p $(TARGETDIR)/rom/etc/l7-protocols
ifeq ($(TCONFIG_L7PAT),y)
	@cd layer7 && ./squish.sh
	cp layer7/squished/*.pat $(TARGETDIR)/rom/etc/l7-protocols
endif

	busybox/examples/depmod.pl -k $(LINUXDIR)/vmlinux -b $(TARGETDIR)/lib/modules/*/
#	@mv $(TARGETDIR)/lib/modules/*/modules.dep $(TARGETDIR)/lib/modules/
	@echo ---

	@rm -f $(TARGETDIR)/lib/modules/*/build

	@$(MAKE) -C $(LINUXDIR)/scripts/squashfs mksquashfs-lzma
	@$(LINUXDIR)/scripts/squashfs/mksquashfs-lzma $(TARGETDIR) $(PLATFORMDIR)/target.image -all-root -noappend -no-duplicates | tee target.info

#	Package kernel and filesystem
#	if grep -q "CONFIG_EMBEDDED_RAMDISK=y" $(LINUXDIR)/.config ; then \
#	    cp $(PLATFORMDIR)/target.image $(LINUXDIR)/arch/mips/ramdisk/$${CONFIG_EMBEDDED_RAMDISK_IMAGE} ; \
#	    $(MAKE) -C $(LINUXDIR) zImage ; \
#	else \
#	    cp $(LINUXDIR)/arch/mips/brcm-boards/bcm947xx/compressed/vmlinuz $(PLATFORMDIR)/ ; \
#	    trx -o $(PLATFORMDIR)/linux.trx $(PLATFORMDIR)/vmlinuz $(PLATFORMDIR)/target.image ; \
#	fi

# 	Pad self-booting Linux to a 64 KB boundary
#	cp $(LINUXDIR)/arch/mips/brcm-boards/bcm947xx/compressed/zImage $(PLATFORMDIR)/
#	dd conv=sync bs=64k < $(PLATFORMDIR)/zImage > $(PLATFORMDIR)/linux.bin
# 	Append filesystem to self-booting Linux
#	cat $(PLATFORMDIR)/target.image >> $(PLATFORMDIR)/linux.bin


libc:	$(LIBDIR)/ld-uClibc.so.0
#	$(MAKE) -C ../../../tools-src/uClibc all
#	$(MAKE) -C ../../../tools-src/uClibc install


#
# cleaners
#

clean: clean-build $(obj-clean)
	rm -rf layer7/squished
	rm -f .ipv6-y .ipv6-n
	make -C config clean

clean-build: dummy
	rm -rf $(TARGETDIR)
	rm -rf $(INSTALLDIR)
	rm -f $(PLATFORMDIR)/linux.trx $(PLATFORMDIR)/vmlinuz $(PLATFORMDIR)/target.image
	rm -rf $(PLATFORMDIR)/extras

distclean: clean
ifneq ($(INSIDE_MAK),1)
	$(MAKE) -C $(SRCBASE) $@ INSIDE_MAK=1
endif
#	-rm -f $(LIBDIR)/*.so.0  $(LIBDIR)/*.so

#
# configuration
#

CONFIG_IN := config/config.in

config/conf config/mconf:
	@$(MAKE) -C config

rconf: config/conf
	@config/conf $(CONFIG_IN)

rmconf: config/mconf
	@config/mconf $(CONFIG_IN)

roldconf: config/conf
	@config/conf -o $(CONFIG_IN)
	@$(MAKE) shared-clean rc-clean nvram-clean httpd-clean prebuilt-clean libbcmcrypto-clean dhcpv6-clean

kconf:
	@$(MAKE) -C $(LINUXDIR) config

kmconf:
	@$(MAKE) -C $(LINUXDIR) menuconfig

koldconf:
	@$(MAKE) -C $(LINUXDIR) oldconfig
	@$(MAKE) -C $(LINUXDIR) include/linux/version.h

bboldconf:
	@$(MAKE) -C busybox oldconfig

config conf: rconf kconf

menuconfig mconf: rmconf kmconf

.ipv6-y .ipv6-n:
	@rm -f .ipv6-y .ipv6-n
	@$(MAKE) iptables-clean ebtables-clean pppd-clean zebra-clean dnsmasq-clean iproute2-clean
	@touch $@

dependconf: .ipv6-$(if $(TCONFIG_IPV6),y,n)

oldconfig oldconf: koldconf roldconf dependconf bboldconf


#
# overrides and extra dependencies
#

busybox: dummy
	@$(SEP)
	$(call patch_files,busybox)
	@$(MAKE) -C busybox EXTRA_CFLAGS="-fPIC $(EXTRACFLAGS)" $(PARALLEL_BUILD)

busybox-install:
	rm -rf $(INSTALLDIR)/busybox
	$(MAKE) -C busybox install EXTRA_CFLAGS="-fPIC $(EXTRACFLAGS)" CONFIG_PREFIX=$(INSTALLDIR)/busybox

busybox-config:
	$(MAKE) -C busybox menuconfig

busybox-clean:
	-@$(MAKE) -C busybox distclean
	$(call unpatch_files,busybox)

httpd: shared nvram $(if $(TCONFIG_HTTPS),mssl,)
	@$(SEP)
	@$(MAKE) -C httpd

www-install:
	@$(MAKE) -C www install INSTALLDIR=$(INSTALLDIR)/www TOMATO_EXPERIMENTAL=$(TOMATO_EXPERIMENTAL)

cyassl/stamp-h1:
	cd cyassl && autoreconf -fsi && \
	CFLAGS="$(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC -DNO_MD4 -DNO_ERROR_STRINGS -DNO_HC128 -DNO_RABBIT -DNO_PSK -DNO_DSA -DNO_DH -DNO_PWDBASED" \
	CXXFLAGS="-Os -Wall -fPIC" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
	PTHREAD_LIBS="-lpthread" \
	$(CONFIGURE)
	@touch $@

cyassl: cyassl/stamp-h1
	@$(SEP)
	@$(MAKE) -C cyassl

cyassl-install:
	@true

cyassl-clean:
	-@$(MAKE) -C cyassl clean
	@rm -f cyassl/stamp-h1

ifeq ($(TCONFIG_KEYGEN),)
ifeq ($(TCONFIG_OPENSSL11),y)
OPENSSL_CIPHERS := no-camellia no-idea no-rc2 no-cast no-seed no-gost no-md4 no-mdc2 no-rmd160 no-cms no-engine no-ocsp no-srp no-ts no-afalgeng no-ocb \
                   no-tests no-unit-test no-ui-console no-whirlpool no-blake2 no-cmac no-multiblock no-nextprotoneg no-comp no-ct no-scrypt no-sctp no-siphash no-ubsan \
                   no-rc5 no-rdrand no-capieng no-rfc3779 no-hw no-zlib no-sse2 no-ssl-trace no-dtls1 no-psk no-md2 no-devcryptoeng no-dgram no-dtls
else
OPENSSL_CIPHERS := no-sha0 no-smime no-camellia no-krb5 no-rmd160 no-ripemd no-seed no-capieng no-gms no-gmp no-rfc3779 no-hw no-jpake no-zlib no-engines no-sse2 no-libunbound no-ssl-trace no-dtls1 no-store no-psk no-md2 no-mdc2 no-ts
endif
endif

openssl/stamp-h1:
ifeq ($(TCONFIG_KEYGEN),y)
	mv patches/openssl/102-tomato-mips-specific.patch patches/openssl/102-tomato-mips-specific.patch.tmp || true
else
	mv patches/openssl/102-tomato-mips-specific.patch.tmp patches/openssl/102-tomato-mips-specific.patch || true
endif
	$(call patch_files,openssl)
	cd openssl && \
	CC=$(CC:$(CROSS_COMPILE)%=%) \
	AR=$(AR:$(CROSS_COMPILE)%=%) \
	NM=$(NM:$(CROSS_COMPILE)%=%) \
	RANLIB=$(RANLIB:$(CROSS_COMPILE)%=%) \
	./Configure $(HOSTCONFIG) -Os -DOPENSSL_NO_BUF_FREELISTS --openssldir=/etc/ssl \
	-ffunction-sections -fdata-sections -Wl,--gc-sections -fomit-frame-pointer \
	shared $(OPENSSL_CIPHERS) enable-rc5 no-ssl2 no-ssl3 no-err $(if $(TCONFIG_BBT),,no-rc4)
ifeq ($(TCONFIG_KEYGEN),)
	cd openssl && mkdir -p include/openssl && \
	ln -sf ../../crypto/camellia/camellia.h include/openssl/camellia.h && \
	ln -sf ../../crypto/krb5/krb5_asn.h include/openssl/krb5_asn.h && \
	ln -sf ../../crypto/mdc2/mdc2.h include/openssl/mdc2.h && \
	ln -sf ../../crypto/ripemd/ripemd.h include/openssl/ripemd.h && \
	ln -sf ../../crypto/seed/seed.h include/openssl/seed.h && \
	ln -sf ../../crypto/ts/ts.h include/openssl/ts.h && \
	ln -sf ../../crypto/engine/engine.h include/openssl/engine.h && \
	ln -sf ../../crypto/rsa/rsa.h include/openssl/rsa.h && \
	ln -sf ../../crypto/dh/dh.h include/openssl/dh.h && \
	ln -sf ../../crypto/idea/idea.h include/openssl/idea.h && \
	ln -sf ../../crypto/rc2/rc2.h include/openssl/rc2.h && \
	ln -sf ../../crypto/cast/cast.h include/openssl/cast.h
else
	cd openssl && mkdir -p include/openssl && \
	ln -sf ../../crypto/krb5/krb5_asn.h include/openssl/krb5_asn.h
endif
	@$(MAKE) -C openssl depend clean
	@touch $@

openssl: openssl/stamp-h1
	@$(SEP)
	@$(MAKE) -C openssl $(PARALLEL_BUILD)

openssl-clean:
	-@$(MAKE) -C openssl clean
	@rm -f openssl/stamp-h1
	@rm -fr openssl/include
	$(call unpatch_files,openssl)

openssl-install:
	install -D openssl/libcrypto.so.1.0.0 $(INSTALLDIR)/openssl/usr/lib/libcrypto.so.1.0.0
	install -D openssl/libssl.so.1.0.0 $(INSTALLDIR)/openssl/usr/lib/libssl.so.1.0.0
	$(STRIP) $(INSTALLDIR)/openssl/usr/lib/libcrypto.so.1.0.0
	$(STRIP) $(INSTALLDIR)/openssl/usr/lib/libssl.so.1.0.0
	cd $(INSTALLDIR)/openssl/usr/lib && ln -sf libcrypto.so.1.0.0 libcrypto.so
	cd $(INSTALLDIR)/openssl/usr/lib && ln -sf libssl.so.1.0.0 libssl.so
	install -D openssl/apps/openssl $(INSTALLDIR)/openssl/usr/sbin/openssl
	$(STRIP) $(INSTALLDIR)/openssl/usr/sbin/openssl
	chmod 0500 $(INSTALLDIR)/openssl/usr/sbin/openssl
	install -D -m 0500 httpd/gencert.sh $(INSTALLDIR)/openssl/usr/sbin/gencert.sh

openssl-1.1/stamp-h1:
ifeq ($(TCONFIG_KEYGEN),y)
	mv patches/openssl-1.1/104-reduce-size-for-smaller-targets.patch patches/openssl-1.1/104-reduce-size-for-smaller-targets.patch.tmp || true
else
	mv patches/openssl-1.1/104-reduce-size-for-smaller-targets.patch.tmp patches/openssl-1.1/104-reduce-size-for-smaller-targets.patch || true
endif
	$(call patch_files,openssl-1.1)
	cd openssl-1.1 && \
	CC=$(CC:$(CROSS_COMPILE)%=%) \
	AR=$(AR:$(CROSS_COMPILE)%=%) \
	NM=$(NM:$(CROSS_COMPILE)%=%) \
	RANLIB=$(RANLIB:$(CROSS_COMPILE)%=%) \
	./Configure $(HOSTCONFIG) --prefix=/usr --openssldir=/etc/ssl \
	$(CFLAG_OPTIMIZE) -ffunction-sections -fdata-sections -Wl,--gc-sections -fomit-frame-pointer \
	shared $(OPENSSL_CIPHERS) no-ssl3 no-err no-async --api=1.0.0 \
	no-aria no-sm2 no-sm3 no-sm4 $(if $(TCONFIG_BBT),,no-rc4) \
	-DOPENSSL_PREFER_CHACHA_OVER_GCM
	-@$(MAKE) -C openssl-1.1 depend clean
	@touch $@

openssl-1.1: openssl-1.1/stamp-h1
	$(SEP)
	$(MAKE) -C openssl-1.1 $(PARALLEL_BUILD)

openssl-1.1-clean:
	[ ! -f openssl-1.1/stamp-h1 ] || $(MAKE) -C openssl-1.1 clean
	@rm -f openssl-1.1/stamp-h1
	$(call unpatch_files,openssl-1.1)

openssl-1.1-install:
	if [ -f openssl-1.1/stamp-h1 ] ; then \
		install -D openssl-1.1/libcrypto.so.1.1 $(INSTALLDIR)/openssl-1.1/usr/lib/libcrypto.so.1.1 ; \
		install -D openssl-1.1/libssl.so.1.1 $(INSTALLDIR)/openssl-1.1/usr/lib/libssl.so.1.1 ; \
		$(STRIP) $(INSTALLDIR)/openssl-1.1/usr/lib/libssl.so.1.1 ; \
		$(STRIP) $(INSTALLDIR)/openssl-1.1/usr/lib/libcrypto.so.1.1 ; \
		install -D openssl-1.1/apps/openssl $(INSTALLDIR)/openssl-1.1/usr/sbin/openssl11 ; \
		$(STRIP) $(INSTALLDIR)/openssl-1.1/usr/sbin/openssl11 ; \
		chmod 0500 $(INSTALLDIR)/openssl-1.1/usr/sbin/openssl11 ; \
		install -D -m 0500 httpd/gencert.sh $(INSTALLDIR)/openssl-1.1/usr/sbin/gencert.sh ; \
		cd $(INSTALLDIR)/openssl-1.1/usr/sbin && ln -sf openssl11 openssl ; \
	fi
	@true

mssl: $(if $(TCONFIG_HTTPS),$(OPENSSLDIR),cyassl)

ifneq ($(TCONFIG_BBT)$(TCONFIG_NGINX),)
mdu: shared
else
mdu: shared mssl
endif

rc: nvram shared

bridge/Makefile:
	cd bridge && autoreconf -fsi && CFLAGS="-Os -g $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
	$(CONFIGURE) --prefix="" --with-linux-headers=$(LINUXDIR)/include

bridge: bridge/Makefile
	@$(SEP)
	@$(MAKE) -C bridge

bridge-install:
	install -D bridge/brctl/brctl $(INSTALLDIR)/bridge/usr/sbin/brctl
	$(STRIP) $(INSTALLDIR)/bridge/usr/sbin/brctl

bridge-clean:
	-@$(MAKE) -C bridge clean
	@rm -f bridge/Makefile

dnsmasq: $(DNSSEC_BACKEND)
	@$(SEP)
	$(call patch_files,dnsmasq)
	$(MAKE) -C dnsmasq $(PARALLEL_BUILD) \
	COPTS="-DHAVE_BROKEN_RTC -DHAVE_TOMATO -DNO_DUMPFILE -DNO_ID -DNO_GMP $(if $(TCONFIG_OPTIMIZE_SIZE_MORE),-DNO_LOOP,) -DNO_INOTIFY -DUSE_IPSET -DEDNS_PKTSZ=1280 \
		$(if $(TCONFIG_USB_EXTRAS),,-DNO_TFTP -DNO_SCRIPT -DNO_AUTH) \
		$(if $(DNSSEC_OPENSSL),-I$(TOP)/$(OPENSSLDIR)/include -DHAVE_DNSSEC,) \
		$(if $(DNSSEC_NETTLE),-I$(TOP)/nettle/include -I$(TOP)/gmp -DHAVE_DNSSEC -DHAVE_DNSSEC_STATIC -DNO_GOST,) \
		$(if $(TCONFIG_IPV6),-DUSE_IPV6,-DNO_IPV6)" \
	CFLAGS="-Os -Wall -ffunction-sections -fdata-sections $(EXTRACFLAGS) $(OPTSIZE_MORE_FLAG)" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections \
		$(if $(DNSSEC_OPENSSL),-pthread -L$(TOP)/$(OPENSSLDIR),) \
		$(if $(DNSSEC_NETTLE),-L$(TOP)/nettle/lib -L$(TOP)/gmp/.libs,)" \
	$(if $(DNSSEC_OPENSSL),PKG_CONFIG_PATH="$(TOP)/$(OPENSSLDIR)" CRYPTO=openssl,) \
	$(if $(DNSSEC_NETTLE),PKG_CONFIG_PATH="$(TOP)/nettle/lib/pkgconfig",)

dnsmasq-install:
	install -D dnsmasq/src/dnsmasq $(INSTALLDIR)/dnsmasq/usr/sbin/dnsmasq
	$(STRIP) $(INSTALLDIR)/dnsmasq/usr/sbin/dnsmasq

dnsmasq-clean:
	-@$(MAKE) -C dnsmasq clean
	$(call unpatch_files,dnsmasq)

nettle/stamp-h1: gmp
	$(call patch_files,nettle)
	cd nettle && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC" \
	CPPFLAGS="-I$(TOP)/gmp -fPIC" \
	LDFLAGS="-L$(TOP)/gmp/.libs -ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
	$(CONFIGURE) prefix=$(TOP)/nettle --enable-mini-gmp --disable-documentation --disable-shared --disable-openssl
	@touch $@

nettle: nettle/stamp-h1
	@$(SEP)
	@$(MAKE) -C nettle
	@$(MAKE) -C nettle install

nettle-clean:
	-@$(MAKE) -C nettle clean
	@rm -f nettle/stamp-h1
	@rm -rf nettle/include nettle/lib nettle/bin nettle/share
	$(call unpatch_files,nettle)

gmp/stamp-h1:
	$(call patch_files,gmp)
	cd gmp && autoreconf -fsi && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
	$(CONFIGURE)
	@touch $@

gmp: gmp/stamp-h1
	@$(SEP)
	@$(MAKE) -C gmp $(PARALLEL_BUILD)

gmp-clean:
	@$(MAKE) -C gmp clean
	@rm -f gmp/stamp-h1
	$(call unpatch_files,gmp)

iptables:
	@$(SEP)
	$(call patch_files,iptables)
	cp -f iptables/extensions/libipt_ipp2p_K26.c iptables/extensions/libipt_ipp2p.c
	$(MAKE) -C iptables BINDIR=/usr/sbin LIBDIR=/usr/lib KERNEL_DIR=$(LINUXDIR) COPT_FLAGS="-Os $(EXTRACFLAGS) -U CONFIG_NVRAM_SIZE $(OPTSIZE_FLAG)"

iptables-install:
	install -D iptables/iptables $(INSTALLDIR)/iptables/usr/sbin/iptables
	cd $(INSTALLDIR)/iptables/usr/sbin && ln -sf iptables iptables-restore && ln -sf iptables iptables-save
	install -d $(INSTALLDIR)/iptables/usr/lib/iptables
	install -D iptables/extensions/*.so $(INSTALLDIR)/iptables/usr/lib/iptables/
	install -D iptables/libiptc.so $(INSTALLDIR)/iptables/usr/lib/libiptc.so
	$(STRIP) $(INSTALLDIR)/iptables/usr/sbin/iptables
	$(STRIP) $(INSTALLDIR)/iptables/usr/lib/iptables/*.so
	$(STRIP) $(INSTALLDIR)/iptables/usr/lib/libiptc.so
ifeq ($(TCONFIG_IPV6),y)
	install iptables/ip6tables $(INSTALLDIR)/iptables/usr/sbin/ip6tables
	$(STRIP) $(INSTALLDIR)/iptables/usr/sbin/ip6tables
	cd $(INSTALLDIR)/iptables/usr/sbin && \
		ln -sf ip6tables ip6tables-restore && \
		ln -sf ip6tables ip6tables-save
endif

iptables-clean:
	-@$(MAKE) -C iptables KERNEL_DIR=$(LINUXDIR) clean
	$(call unpatch_files,iptables)

ppp:
	@$(SEP)
	$(MAKE) -C ppp/pppoecd $* INSTALLDIR=$(INSTALLDIR)/ppp $(if $(TCONFIG_IPV6),HAVE_INET6=y,) $(PARALLEL_BUILD)
#	$(MAKE) -C ppp/pppoecd $* INSTALLDIR=$(INSTALLDIR)/ppp DFLAGS="-DDEBUG -DDEBUGALL"

ppp-%:
	$(MAKE) -C ppp/pppoecd $* INSTALLDIR=$(INSTALLDIR)/ppp $(if $(TCONFIG_IPV6),HAVE_INET6=y,)

rp-pppoe/src/stamp-h1: rp-pppoe/src/Makefile.in
	$(call patch_files,rp-pppoe)
	cd rp-pppoe/src && \
		CFLAGS="-g -Os $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
		CPPFLAGS="-Os -ffunction-sections -fdata-sections" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
		$(CONFIGURE) --prefix=/usr --enable-plugin=$(TOP)/pppd --disable-debugging  \
			ac_cv_linux_kernel_pppoe=yes rpppoe_cv_pack_bitfields=rev ac_cv_path_PPPD=$(TOP)/pppd
	@touch $@

rp-pppoe: pppd rp-pppoe/src/stamp-h1
	@$(SEP)
	$(MAKE) -C rp-pppoe/src pppoe-relay rp-pppoe.so $(PARALLEL_BUILD)

rp-pppoe-clean:
	-@$(MAKE) -C rp-pppoe/src clean
	@rm -f rp-pppoe/src/pppoe-relay
	@rm -f rp-pppoe/src/stamp-h1
	$(call unpatch_files,rp-pppoe)

rp-pppoe-install:
	install -D rp-pppoe/src/rp-pppoe.so $(INSTALLDIR)/rp-pppoe/usr/lib/pppd/rp-pppoe.so
	$(STRIP) $(INSTALLDIR)/rp-pppoe/usr/lib/pppd/*.so
#	install -D rp-pppoe/src/pppoe-relay $(INSTALLDIR)/rp-pppoe/usr/sbin/pppoe-relay
#	$(STRIP) $(INSTALLDIR)/rp-pppoe/usr/sbin/pppoe-relay

libnfnetlink/stamp-h1:
	cd libnfnetlink && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
		$(CONFIGURE) --prefix=/usr --enable-shared --enable-static
	@touch $@

libnfnetlink: libnfnetlink/stamp-h1
	@$(SEP)
	$(MAKE) -C libnfnetlink $(PARALLEL_BUILD)

libnfnetlink-install:
	install -D libnfnetlink/src/.libs/libnfnetlink.so.0.2.0 $(INSTALLDIR)/libnfnetlink/usr/lib/libnfnetlink.so.0.2.0
	$(STRIP) -s $(INSTALLDIR)/libnfnetlink/usr/lib/libnfnetlink.so.0.2.0
	cd $(INSTALLDIR)/libnfnetlink/usr/lib/ && \
		ln -sf libnfnetlink.so.0.2.0 libnfnetlink.so.0 && \
		ln -sf libnfnetlink.so.0.2.0 libnfnetlink.so

libnfnetlink-clean:
	-@$(MAKE) -C libnfnetlink distclean
	@rm -f libnfnetlink/stamp-h1

miniupnpd/stamp-h1:
	$(call patch_files,miniupnpd)
	cd miniupnpd && \
		./configure --leasefile --vendorcfg --portinuse $(if $(TCONFIG_IPV6),--ipv6,) --iptablespath=$(if $(TCONFIG_BCMARM),$(TOP)/iptables-1.8.x,$(TOP)/iptables)
	@touch $@

miniupnpd: $(IPTABLES_TARGET) miniupnpd/stamp-h1
	@$(SEP)
	$(MAKE) -C miniupnpd $(PARALLEL_BUILD) \
		EXTRACFLAGS="-Os $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -Wl,--as-needed $(if $(TCONFIG_HTTPS),-L$(TOP)/$(OPENSSLDIR) -pthread) -Wl,--allow-multiple-definition"

miniupnpd-install:
	install -D miniupnpd/miniupnpd $(INSTALLDIR)/miniupnpd/usr/sbin/miniupnpd
	$(STRIP) $(INSTALLDIR)/miniupnpd/usr/sbin/miniupnpd

miniupnpd-clean:
	-@$(MAKE) -C miniupnpd clean
	@rm -f miniupnpd/config.h
	@rm -f miniupnpd/stamp-h1
	$(call unpatch_files,miniupnpd)

shared: busybox

vsftpd: $(if $(TCONFIG_FTP_SSL),$(OPENSSLDIR),)
	@$(SEP)
	$(call patch_files,vsftpd)
	$(MAKE) -C vsftpd $(PARALLEL_BUILD)

vsftpd-install:
	install -D vsftpd/vsftpd $(INSTALLDIR)/vsftpd/usr/sbin/vsftpd
	$(STRIP) -s $(INSTALLDIR)/vsftpd/usr/sbin/vsftpd

vsftpd-clean:
	$(call unpatch_files,vsftpd)

ufsd: kernel_header kernel
	@$(MAKE) -C ufsd all

ufsd-install: ufsd
	@$(MAKE) -C ufsd install INSTALLDIR=$(INSTALLDIR)/ufsd

ntfs-3g/Makefile:
	$(call patch_files,ntfs-3g)
	cd ntfs-3g && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC $(OPTSIZE_FLAG)" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
		$(CONFIGURE) --enable-shared=no --enable-static=no \
		--disable-library --disable-ldconfig --disable-mount-helper --with-fuse=internal \
		--disable-ntfsprogs --disable-crypto --without-uuid \
		--disable-posix-acls --disable-nfconv --disable-dependency-tracking

ntfs-3g: ntfs-3g/Makefile
	@$(SEP)
	@$(MAKE) -C ntfs-3g $(PARALLEL_BUILD)

ntfs-3g-clean:
	-@$(MAKE) -C ntfs-3g clean
	@rm -f ntfs-3g/Makefile
	$(call unpatch_files,ntfs-3g)

ntfs-3g-install:
	install -D ntfs-3g/src/ntfs-3g $(INSTALLDIR)/ntfs-3g/bin/ntfs-3g
	$(STRIP) -s $(INSTALLDIR)/ntfs-3g/bin/ntfs-3g
	install -d $(INSTALLDIR)/ntfs-3g/sbin && cd $(INSTALLDIR)/ntfs-3g/sbin && \
		ln -sf ../bin/ntfs-3g mount.ntfs-3g && \
		ln -sf ../bin/ntfs-3g mount.ntfs

libusb10/Makefile: libusb10/Makefile.in
	cd libusb10 && autoreconf -fsi && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
	LIBS="-lpthread" \
	$(CONFIGURE) --disable-udev --prefix=/usr ac_cv_lib_rt_clock_gettime=no

libusb10: libusb10/Makefile
	@$(SEP)
	$(MAKE) -C $@

libusb10-install:
	install -D libusb10/libusb/.libs/libusb-1.0.so $(INSTALLDIR)/libusb10/usr/lib/libusb-1.0.so
	$(STRIP) $(INSTALLDIR)/libusb10/usr/lib/*.so
	cd $(INSTALLDIR)/libusb10/usr/lib && ln -sf libusb-1.0.so libusb-1.0.so.0

libusb10-clean:
	-@$(MAKE) -C $@ clean
	@rm -rf libusb10/Makefile

usbmodeswitch: libusb10
	@$(SEP)
	$(MAKE) -C $@ \
	CFLAGS="-Os $(EXTRACFLAGS) -DLIBUSB10 -Wl,-R/lib:/usr/lib:/opt/usr/lib -I$(TOP)/libusb10/libusb" \
	LDFLAGS="-L$(TOP)/libusb10/libusb/.libs" \
	LIBS="-lpthread -lusb-1.0"

usbmodeswitchdb-install:
	@mkdir -p $(TARGETDIR)/rom/etc/usb_modeswitch.d
	# compress whitespace
	@for D in $(wildcard $(TOP)/usbmodeswitch/data/usb_modeswitch.d/*); do \
		F=`basename $$D`; \
		sed 's/###.*//g;s/[ \t]\+/ /g;s/^[ \t]*//;s/[ \t]*$$//;/^$$/d' < $$D > $(TARGETDIR)/rom/etc/usb_modeswitch.d/$$F; \
	done

usbmodeswitch-install: usbmodeswitch usbmodeswitchdb-install
	install -D usbmodeswitch/usb_modeswitch $(INSTALLDIR)/usbmodeswitch/usr/sbin/usb_modeswitch
	$(STRIP) -s $(INSTALLDIR)/usbmodeswitch/usr/sbin/usb_modeswitch
	@mkdir -p $(TARGETDIR)/rom/etc
	@sed 's/#.*//g;s/[ \t]\+/ /g;s/^[ \t]*//;s/[ \t]*$$//;/^$$/d' < $(TOP)/usbmodeswitch/usb_modeswitch.conf > $(TARGETDIR)/rom/etc/usb_modeswitch.conf

dhcpv6/stamp-h1:
	@cd dhcpv6 && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -D_GNU_SOURCE -ffunction-sections -fdata-sections -fPIC -I$(SRCBASE)/include -DTOMATO" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC $(if $(TCONFIG_BCMARM),-L$(TOP)/nvram${BCMEX} -lnvram,-L$(TOP)/nvram -lnvram -L$(TOP)/shared -lshared)" \
	ac_cv_func_setpgrp_void=yes \
	$(CONFIGURE) --prefix= --with-localdbdir=/var
	@$(MAKE) -C dhcpv6 clean
	@touch $@

dhcpv6: dhcpv6/stamp-h1
	@$(SEP)
	@$(MAKE) -C dhcpv6 dhcp6c $(PARALLEL_BUILD)

dhcpv6-install:
	install -D dhcpv6/dhcp6c $(INSTALLDIR)/dhcpv6/usr/sbin/dhcp6c
	$(STRIP) $(INSTALLDIR)/dhcpv6/usr/sbin/dhcp6c

dhcpv6-clean:
	-@$(MAKE) -C dhcpv6 clean
	@rm -f dhcpv6/Makefile dhcpv6/stamp-h1

wsdd2: shared
	$(call patch_files,wsdd2)
	@$(SEP)
	@$(MAKE) CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -DTOMATO -I$(TOP)/shared" LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" -C $@

wsdd2-install:
	install -D wsdd2/wsdd2 $(INSTALLDIR)/wsdd2/usr/sbin/wsdd2
	$(STRIP) $(INSTALLDIR)/wsdd2/usr/sbin/wsdd2

wsdd2-clean:
	@$(MAKE) -C wsdd2 clean
	$(call unpatch_files,wsdd2)

p910nd:

samba3: $(if $(TCONFIG_NGINX),libiconv,)

nvram: shared

prebuilt: shared libbcmcrypto

accel-pptp/Makefile: accel-pptp/Makefile.in $(LINUXDIR)/include/linux/version.h
	$(call patch_files,accel-pptp)
	cd accel-pptp && \
		CFLAGS="-g -O2 $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
		CPPFLAGS="-O2 -ffunction-sections -fdata-sections" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
		$(CONFIGURE) --prefix=/usr KDIR=$(LINUXDIR) PPPDIR=$(TOP)/pppd

accel-pptp: pppd accel-pptp/Makefile
	@$(SEP)
	@$(MAKE) -C accel-pptp

accel-pptp-install:
	install -D accel-pptp/src/.libs/pptp.so $(INSTALLDIR)/accel-pptp/usr/lib/pppd/pptp.so
	$(STRIP) $(INSTALLDIR)/accel-pptp/usr/lib/pppd/pptp.so

accel-pptp-clean:
	-@$(MAKE) -C accel-pptp clean
	@rm -f accel-pptp/Makefile
	$(call unpatch_files,accel-pptp)

pptpd/stamp-h1:
	$(call patch_files,pptpd)
	ln -sf ../../pppd/pppd/ pptpd/plugins/pppd
	cd $(TOP)/pptpd && $(CONFIGURE) --prefix=$(INSTALLDIR)/pptpd --enable-bcrelay
	touch $@

pptpd: pptpd/stamp-h1
	@$(SEP)
	@$(MAKE) -C pptpd

pptpd-install:
	@install -D pptpd/pptpd $(INSTALLDIR)/pptpd/usr/sbin/pptpd
	@install -D pptpd/bcrelay $(INSTALLDIR)/pptpd/usr/sbin/bcrelay
	@install -D pptpd/pptpctrl $(INSTALLDIR)/pptpd/usr/sbin/pptpctrl
	@$(STRIP) $(INSTALLDIR)/pptpd/usr/sbin/*

pptpd-clean:
	-@$(MAKE) -C pptpd clean
	rm -rf pptpd/stamp-h1 pptpd/.deps
	rm -f pptpd/plugins/pppd
	$(call unpatch_files,pptpd)

pppd/Makefile: pppd/linux/Makefile.top
	$(call patch_files,pppd)
	cd pppd && $(CONFIGURE) --prefix=/usr --sysconfdir=/tmp

pppd: pppd/Makefile
	@$(SEP)
	@$(MAKE) -C pppd MFLAGS='$(if $(TCONFIG_IPV6),HAVE_INET6=y,) $(if $(TCONFIG_HTTPS),,USE_CRYPT=y) EXTRACFLAGS="$(EXTRACFLAGS) $(OPTSIZE_MORE_FLAG)"'

pppd-install:
	install -D pppd/pppd/pppd $(INSTALLDIR)/pppd/usr/sbin/pppd
	$(STRIP) $(INSTALLDIR)/pppd/usr/sbin/pppd
	install -D pppd/chat/chat $(INSTALLDIR)/pppd/usr/sbin/chat
	$(STRIP) $(INSTALLDIR)/pppd/usr/sbin/chat
ifeq ($(TCONFIG_L2TP),y)
	install -D pppd/pppd/plugins/pppol2tp/pppol2tp.so $(INSTALLDIR)/pppd/usr/lib/pppd/pppol2tp.so
	$(STRIP) $(INSTALLDIR)/pppd/usr/lib/pppd/*.so
endif

pppd-clean:
	-@$(MAKE) -C pppd clean
	@rm -f pppd/Makefile
	$(call unpatch_files,pppd)

zebra/stamp-h1:
	@cd $(TOP)/zebra && rm -f config.cache && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
	$(CONFIGURE) --sysconfdir=/etc --enable-netlink $(if $(TCONFIG_IPV6),--enable-ipv6,--disable-ipv6) --disable-ripngd \
		--disable-ospfd --disable-ospf6d --disable-bgpd --disable-bgp-announce --disable-dependency-tracking
	@touch $@

zebra: zebra/stamp-h1
	@$(SEP)
	@$(MAKE) -C zebra

zebra-clean:
	-@$(MAKE) -C zebra clean
	@rm -f zebra/stamp-h1

zebra-install:
	install -D zebra/zebra/zebra $(INSTALLDIR)/zebra/usr/sbin/zebra
	install -D zebra/ripd/ripd $(INSTALLDIR)/zebra/usr/sbin/ripd
	install -D zebra/lib/libzebra.so $(INSTALLDIR)/zebra/usr/lib/libzebra.so
	$(STRIP) $(INSTALLDIR)/zebra/usr/sbin/zebra
	$(STRIP) $(INSTALLDIR)/zebra/usr/sbin/ripd
	$(STRIP) $(INSTALLDIR)/zebra/usr/lib/libzebra.so

xl2tpd: pppd
	@$(SEP)
	$(call patch_files,xl2tpd)
	CFLAGS="-Os -g $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC $(OPTSIZE_FLAG)" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
	$(MAKE) -C $@ PREFIX=/usr xl2tpd $(PARALLEL_BUILD)

xl2tpd-install:
	install -D xl2tpd/xl2tpd $(INSTALLDIR)/xl2tpd/usr/sbin/xl2tpd
	$(STRIP) $(INSTALLDIR)/xl2tpd/usr/sbin/xl2tpd

xl2tpd-clean:
	-@$(MAKE) -C xl2tpd clean
	$(call unpatch_files,xl2tpd)

bpalogin-install:
	install -D bpalogin/bpalogin $(INSTALLDIR)/bpalogin/usr/sbin/bpalogin
	$(STRIP) $(INSTALLDIR)/bpalogin/usr/sbin/bpalogin

libbcm:
	@$(SEP)
	@[ ! -f libbcm/Makefile ] || $(MAKE) -C libbcm

libbcm-install:
	install -D libbcm/libbcm.so $(INSTALLDIR)/libbcm/usr/lib/libbcm.so
	$(STRIP) $(INSTALLDIR)/libbcm/usr/lib/libbcm.so

iproute2:
	@$(SEP)
	$(call patch_files,iproute2)
	@$(MAKE) -C $@ KERNEL_INCLUDE=$(LINUXDIR)/include \
		EXTRACFLAGS="$(EXTRACFLAGS) -ffunction-sections -fdata-sections $(if $(TCONFIG_IPV6),-DUSE_IPV6,-DNO_IPV6) $(OPTSIZE_FLAG)" \
		PKG_CONFIG_PATH="$(PKG_CONFIG_PATH):$(TOP)/iptables/iptables" \
		$(PARALLEL_BUILD)

iproute2-install:
	install -D iproute2/tc/tc $(INSTALLDIR)/iproute2/usr/sbin/tc
	$(STRIP) $(INSTALLDIR)/iproute2/usr/sbin/tc
	install -D iproute2/ip/ip $(INSTALLDIR)/iproute2/usr/sbin/ip
	$(STRIP) $(INSTALLDIR)/iproute2/usr/sbin/ip

iproute2-clean:
	-@$(MAKE) -C iproute2 clean
	$(call unpatch_files,iproute2)

dropbear/config.h:
	$(call patch_files,dropbear)
	cd dropbear && autoreconf -fsi && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -DARGTYPE=3 -ffunction-sections -fdata-sections $(OPTSIZE_FLAG)" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
		ac_cv_func_logout=no ac_cv_func_logwtmp=no \
		$(CONFIGURE) --disable-zlib --enable-syslog --disable-lastlog --disable-utmp \
			--disable-utmpx --disable-wtmp --disable-wtmpx --disable-pututline --disable-pututxline \
			--disable-loginfunc --disable-pam --enable-openpty --enable-bundled-libtom
	@$(MAKE) -C dropbear clean

dropbear: dropbear/config.h
	@$(SEP)
ifeq ($(TCONFIG_ZEBRA),y)
	@$(MAKE) -C dropbear PROGRAMS="dropbear dbclient dropbearkey scp" MULTI=1 $(PARALLEL_BUILD)
else
	@$(MAKE) -C dropbear PROGRAMS="dropbear dropbearkey $(if $(TCONFIG_OPTIMIZE_SIZE),,scp)" MULTI=1 $(PARALLEL_BUILD)
endif

dropbear-install:
	install -D dropbear/dropbearmulti $(INSTALLDIR)/dropbear/usr/bin/dropbearmulti
	$(STRIP) $(INSTALLDIR)/dropbear/usr/bin/dropbearmulti
	cd $(INSTALLDIR)/dropbear/usr/bin && \
	ln -sf dropbearmulti dropbear && \
	ln -sf dropbearmulti dropbearkey && \
	ln -sf dropbearmulti dbclient && \
	ln -sf dropbearmulti ssh && \
	ln -sf dropbearmulti scp

dropbear-clean:
	-@$(MAKE) -C dropbear clean
	@rm -f dropbear/config.h
	$(call unpatch_files,dropbear)

sqlite/stamp-h1:
	cd sqlite && \
	autoreconf -fsi && \
	CC=$(CC) CFLAGS="-Os $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
		$(CONFIGURE) --prefix=/usr --enable-shared --enable-static \
		--disable-readline --disable-dynamic-extensions --enable-threadsafe
	@touch $@

sqlite: sqlite/stamp-h1
	@$(SEP)
	@$(MAKE) -C sqlite all $(PARALLEL_BUILD)

sqlite-clean:
	-@$(MAKE) -C sqlite clean
	@rm -f sqlite/stamp-h1

sqlite-install:
ifeq ($(TCONFIG_NGINX),y)
	install -D sqlite/.libs/libsqlite3.so.0.8.6 $(INSTALLDIR)/sqlite/usr/lib/libsqlite3.so.0.8.6
	$(STRIP) $(INSTALLDIR)/sqlite/usr/lib/libsqlite3.so.0.8.6
	cd $(INSTALLDIR)/sqlite/usr/lib/ && \
		ln -sf libsqlite3.so.0.8.6 libsqlite3.so.0 && \
		ln -sf libsqlite3.so.0.8.6 libsqlite3.so
endif
	@true

FFMPEG_FILTER_CONFIG= $(foreach c, $(2), --$(1)="$(c)")

FFMPEG_DEMUXERS:=aac ac3 avi flac h264 matroska mov mp3 mpegvideo vc1
FFMPEG_PARSERS:=aac ac3 h264 mpeg4video mpegaudio mpegvideo
FFMPEG_DECODERS:=aac ac3 flac h264 jpegls mp3 mpeg1video mpeg2video mpeg4 mpegvideo png wmav1 wmav2
FFMPEG_PROTOCOLS:=file

ifneq ($(TCONFIG_OPTIMIZE_SIZE),y)
FFMPEG_DEMUXERS+=aea aiff anm asf au avs bink caf cavsvideo cdg dts dv ea ea_cdata eac3 filmstrip flic flv fourxm h261 h263 iss iv8 m4v mjpeg mlp mpc mpc8 mpegps \
		 mpegts mpegtsraw mvi nc nuv ogg pcm_alaw pcm_f32be pcm_f32le pcm_f64be pcm_f64le pcm_mulaw pcm_s16be pcm_s16le pcm_s24be pcm_s24le pcm_s32be pcm_s32le \
		 pcm_s8 pcm_u16be pcm_u16le pcm_u24be pcm_u24le pcm_u32be pcm_u32le pcm_u8 qcp r3d rm sox swf tmv truehd vc1t vqf w64 wav wv yop
FFMPEG_PARSERS+=h261 h263 mjpeg mlp
FFMPEG_DECODERS+=atrac3 h261 h263
endif

FFMPEG_CONFIGURE_DEMUXERS:=$(call FFMPEG_FILTER_CONFIG,enable-demuxer,$(FFMPEG_DEMUXERS))
FFMPEG_CONFIGURE_PARSERS:=$(call FFMPEG_FILTER_CONFIG,enable-parser,$(FFMPEG_PARSERS))
FFMPEG_CONFIGURE_DECODERS:=$(call FFMPEG_FILTER_CONFIG,enable-decoder,$(FFMPEG_DECODERS))
FFMPEG_CONFIGURE_PROTOCOLS:=$(call FFMPEG_FILTER_CONFIG,enable-protocol,$(FFMPEG_PROTOCOLS))

ffmpeg/stamp-h1: zlib
	$(call patch_files,ffmpeg)
	cd $(TOP)/ffmpeg && symver_asm_label=no symver_gnu_asm=no symver=no \
		./configure --enable-cross-compile --arch=$(ARCH) --target_os=linux --prefix='' \
		--cross-prefix=$(CROSS_COMPILE) --enable-shared --enable-gpl --enable-small --enable-pthreads \
		--disable-doc --disable-avdevice --disable-avfilter --disable-swscale --disable-postproc \
		--disable-dxva2 --disable-ffmpeg --disable-ffplay --disable-ffprobe --disable-ffserver \
		--disable-altivec --disable-mpegaudio-hp --disable-network --disable-everything \
		$(FFMPEG_CONFIGURE_DEMUXERS) \
		$(FFMPEG_CONFIGURE_PARSERS) \
		$(FFMPEG_CONFIGURE_DECODERS) \
		$(FFMPEG_CONFIGURE_PROTOCOLS) \
		--extra-cflags="-Os $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC -I$(TOP)/zlib $(OPTSIZE_FLAG)" \
		--extra-ldflags="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
		--extra-libs="-L$(TOP)/zlib -lz" \
		--enable-zlib --disable-debug
	@touch $@

ffmpeg: ffmpeg/stamp-h1 zlib
	@$(SEP)
	@$(MAKE) -C ffmpeg all $(PARALLEL_BUILD)

ffmpeg-clean:
	-@$(MAKE) -C ffmpeg clean
	@rm -f ffmpeg/stamp-h1 ffmpeg/config.h ffmpeg/config.mak
	$(call unpatch_files,ffmpeg)

ffmpeg-install:
ifneq ($(MEDIA_SERVER_STATIC),y)
	install -D ffmpeg/libavformat/libavformat.so.52 $(INSTALLDIR)/ffmpeg/usr/lib/libavformat.so.52
	install -D ffmpeg/libavcodec/libavcodec.so.52 $(INSTALLDIR)/ffmpeg/usr/lib/libavcodec.so.52
	install -D ffmpeg/libavutil/libavutil.so.50 $(INSTALLDIR)/ffmpeg/usr/lib/libavutil.so.50
	$(STRIP) $(INSTALLDIR)/ffmpeg/usr/lib/libavformat.so.52
	$(STRIP) $(INSTALLDIR)/ffmpeg/usr/lib/libavcodec.so.52
	$(STRIP) $(INSTALLDIR)/ffmpeg/usr/lib/libavutil.so.50
endif
	@true

libogg/stamp-h1:
	cd libogg && \
	autoreconf -fsi && \
	CFLAGS="-Os $(EXTRACFLAGS) -fPIC -ffunction-sections -fdata-sections" \
	LDFLAGS="-fPIC -ffunction-sections -fdata-sections -Wl,--gc-sections" \
	$(CONFIGURE) --enable-shared --enable-static --prefix=''
	@touch $@

libogg: libogg/stamp-h1
	@$(SEP)
	@$(MAKE) -C libogg all $(PARALLEL_BUILD)

libogg-clean:
	-@$(MAKE) -C libogg clean
	@rm -f libogg/stamp-h1

libogg-install:
ifneq ($(MEDIA_SERVER_STATIC),y)
	install -D libogg/src/.libs/libogg.so.0 $(INSTALLDIR)/libogg/usr/lib/libogg.so.0
	$(STRIP) $(INSTALLDIR)/libogg/usr/lib/libogg.so.0
endif
	@true

flac/stamp-h1: libogg
	$(call patch_files,flac)
	cd $(TOP)/flac && autoreconf -fsi && \
	CFLAGS="-Os $(EXTRACFLAGS) -fPIC -ffunction-sections -fdata-sections" \
	CPPFLAGS="-I$(TOP)/libogg/include -I$(LINUXDIR)/include -fPIC" \
	LDFLAGS="-L$(TOP)/libogg/src/.libs -fPIC -ffunction-sections -fdata-sections -Wl,--gc-sections" \
	$(CONFIGURE) --enable-shared --enable-static --prefix='' --disable-rpath \
		--disable-doxygen-docs --disable-xmms-plugin --disable-cpplibs --disable-thorough-tests \
		--without-libiconv-prefix --disable-altivec --disable-sse --disable-dependency-tracking \
		--with-ogg=$(TOP)/libogg/src/.libs
	@touch $@

flac: flac/stamp-h1 libogg
	@$(SEP)
	@$(MAKE) -C flac/src/libFLAC all $(PARALLEL_BUILD)

flac-clean:
	-@$(MAKE) -C flac clean
	@rm -f flac/stamp-h1
	$(call unpatch_files,flac)

flac-install:
ifneq ($(MEDIA_SERVER_STATIC),y)
	install -D flac/src/libFLAC/.libs/libFLAC.so.8 $(INSTALLDIR)/flac/usr/lib/libFLAC.so.8
	$(STRIP) $(INSTALLDIR)/flac/usr/lib/libFLAC.so.8
endif
	@true

jpeg/stamp-h1:
	cd jpeg && \
	CFLAGS="-Os $(EXTRACFLAGS) -fPIC -ffunction-sections -fdata-sections" \
	LDFLAGS="-fPIC -ffunction-sections -fdata-sections" \
	AR2="touch" \
	$(CONFIGURE) --enable-shared --enable-static --prefix=''
	@touch $@

jpeg: jpeg/stamp-h1
	@$(SEP)
	@$(MAKE) -C jpeg LIBTOOL="" O=o A=a CC=$(CC) AR2="touch" libjpeg.a libjpeg.so $(PARALLEL_BUILD)
	install -d $(TOP)/jpeg/staged/include
	install -d $(TOP)/jpeg/staged/lib
	install -d $(TOP)/jpeg/staged/bin
	install -d $(TOP)/jpeg/staged/man/man1
	@$(MAKE) -C jpeg LIBTOOL="" prefix=$(TOP)/jpeg/staged install
	install -D jpeg/libjpeg.so $(TOP)/jpeg/staged/lib/libjpeg.so
	rm -f $(TOP)/jpeg/staged/lib/libjpeg.la

jpeg-clean:
	-@$(MAKE) -C jpeg clean
	@rm -f jpeg/stamp-h1 jpeg/Makefile
	@rm -rf jpeg/staged

jpeg-install:
ifneq ($(MEDIA_SERVER_STATIC),y)
	install -D jpeg/libjpeg.so $(INSTALLDIR)/jpeg/usr/lib/libjpeg.so
	$(STRIP) $(INSTALLDIR)/jpeg/usr/lib/libjpeg.so
endif
ifeq ($(TCONFIG_NGINX),y)
	install -D jpeg/libjpeg.so $(INSTALLDIR)/jpeg/usr/lib/libjpeg.so
	$(STRIP) $(INSTALLDIR)/jpeg/usr/lib/libjpeg.so
endif
	@true

libexif/stamp-h1:
	cd libexif && autoreconf -fsi && CFLAGS="-Os -Wall $(EXTRACFLAGS) -fPIC -ffunction-sections -fdata-sections" \
	LDFLAGS="-fPIC -ffunction-sections -fdata-sections -Wl,--gc-sections" \
	$(CONFIGURE) --enable-shared --enable-static --prefix='' \
		--disable-docs --disable-rpath --disable-nls --without-libiconv-prefix --without-libintl-prefix
	@touch $@

libexif: libexif/stamp-h1
	@$(SEP)
	@$(MAKE) -C libexif all

libexif-clean:
	-@$(MAKE) -C libexif clean
	@rm -f libexif/stamp-h1

libexif-install:
ifneq ($(MEDIA_SERVER_STATIC),y)
	install -D libexif/libexif/.libs/libexif.so.12 $(INSTALLDIR)/libexif/usr/lib/libexif.so.12
	$(STRIP) $(INSTALLDIR)/libexif/usr/lib/libexif.so.12
endif
	@true

zlib/stamp-h1:
	cd zlib && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -fPIC -ffunction-sections -fdata-sections" \
	CPPLAGS="-Os -Wall -fPIC -ffunction-sections -fdata-sections" \
	LDFLAGS="-fPIC -ffunction-sections -fdata-sections -Wl,--gc-sections" \
	LDSHAREDLIBC="$(EXTRALDFLAGS)" \
	./configure --shared --prefix=/usr --libdir=/usr/lib
	@touch $@

zlib: zlib/stamp-h1
	@$(SEP)
	@$(MAKE) -C zlib all
	@$(MAKE) -C zlib DESTDIR=$(TOP)/zlib/staged install

zlib-clean:
	-@$(MAKE) -C zlib clean
	@rm -f zlib/stamp-h1 zlib/Makefile zlib/zconf.h zlib/zlib.pc
	@rm -rf zlib/staged

zlib-install:
ifeq ($(INSTALL_ZLIB),y)
	install -d $(INSTALLDIR)/zlib/usr/lib
	install -D zlib/libz.so.1 $(INSTALLDIR)/zlib/usr/lib/
	$(STRIP) $(INSTALLDIR)/zlib/usr/lib/libz.so.1
endif
	@true

libid3tag/stamp-h1: zlib
	$(call patch_files,libid3tag)
	cd libid3tag && autoreconf -fsi && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC" \
	CPPFLAGS="-Os -Wall -ffunction-sections -fdata-sections -fPIC -I$(TOP)/zlib" \
	LDFLAGS="-L$(TOP)/zlib -fPIC -ffunction-sections -fdata-sections -Wl,--gc-sections" \
	$(CONFIGURE) --enable-shared --enable-static --prefix='' \
		--disable-debugging --disable-profiling --disable-dependency-tracking
	@touch $@

libid3tag: libid3tag/stamp-h1 zlib
	@$(SEP)
	@$(MAKE) -C libid3tag all $(PARALLEL_BUILD)

libid3tag-clean:
	-@$(MAKE) -C libid3tag clean
	@rm -f libid3tag/stamp-h1
	$(call unpatch_files,libid3tag)

libid3tag-install:
ifneq ($(MEDIA_SERVER_STATIC),y)
	install -D libid3tag/.libs/libid3tag.so.0 $(INSTALLDIR)/libid3tag/usr/lib/libid3tag.so.0
	$(STRIP) $(INSTALLDIR)/libid3tag/usr/lib/libid3tag.so.0
endif
	@true

libvorbis/stamp-h1: libogg
	cd libvorbis && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -fPIC -ffunction-sections -fdata-sections" \
	CPPFLAGS="-I$(TOP)/libogg/include -fPIC" \
	LDFLAGS="-L$(TOP)/libogg/src/.libs -fPIC -ffunction-sections -fdata-sections -Wl,--gc-sections" \
	$(CONFIGURE) --enable-shared --enable-static --prefix='' --disable-oggtest \
		--with-ogg-includes="$(TOP)/libogg/include" \
		--with-ogg-libraries="$(TOP)/libogg/src/.libs"
	@touch $@

libvorbis: libvorbis/stamp-h1
	@$(SEP)
	@$(MAKE) -C libvorbis/lib all $(PARALLEL_BUILD)

libvorbis-clean:
	-@$(MAKE) -C libvorbis clean
	@rm -f libvorbis/stamp-h1

libvorbis-install:
ifneq ($(MEDIA_SERVER_STATIC),y)
	install -D libvorbis/lib/.libs/libvorbis.so.0 $(INSTALLDIR)/libvorbis/usr/lib/libvorbis.so.0
	$(STRIP) $(INSTALLDIR)/libvorbis/usr/lib/libvorbis.so.0
endif
	@true

minidlna/stamp-h1: zlib sqlite ffmpeg libogg flac jpeg libexif libid3tag libvorbis
	$(call patch_files,minidlna)
	cd minidlna &&  \
	./autogen.sh && \
	CFLAGS="-Wall -Os $(EXTRACFLAGS) -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 -ffunction-sections -fdata-sections \
	-I$(TOP)/ffmpeg \
	-I$(TOP)/flac/include -I$(TOP)/sqlite -I$(TOP)/jpeg \
	-I$(TOP)/libexif -I$(TOP)/libid3tag -I$(TOP)/libogg/include \
	-I$(TOP)/libvorbis/include" \
	CPPFLAGS="-I$(TOP)/libogg/include -fPIC" \
	LDFLAGS="-L$(TOP)/jpeg -L$(TOP)/libid3tag/.libs -lid3tag -L$(TOP)/libexif/libexif/.libs -L$(TOP)/zlib -fPIC -ffunction-sections -fdata-sections -Wl,--gc-sections" \
	LIBS="-L$(TOP)/libid3tag/.libs -lpthread -lm -lid3tag -lz" \
	$(CONFIGURE) --prefix=/usr
	
minidlna: minidlna/stamp-h1
	@$(SEP)
	@$(MAKE) -C minidlna CC=$(CC) $(if $(MEDIA_SERVER_STATIC),STATIC=1,) minidlna $(PARALLEL_BUILD)

minidlna-clean:
	-@$(MAKE) -C minidlna clean
	@rm -f minidlna/stamp-h1
	$(call unpatch_files,minidlna)

minidlna-install:
	install -D minidlna/minidlna $(INSTALLDIR)/minidlna/usr/sbin/minidlna
	$(STRIP) $(INSTALLDIR)/minidlna/usr/sbin/minidlna

igmpproxy/src/Makefile: igmpproxy/src/Makefile.in
	$(call patch_files,igmpproxy)
	cd igmpproxy && \
	autoreconf -fsi && \
	$(CONFIGURE) --prefix=/usr

igmpproxy: igmpproxy/src/Makefile
	@$(SEP)
	@$(MAKE) -C igmpproxy/src \
	CFLAGS="-Os -g -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections $(OPTSIZE_FLAG) -std=gnu99" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
	$(PARALLEL_BUILD)

igmpproxy-install:
	install -D igmpproxy/src/igmpproxy $(INSTALLDIR)/igmpproxy/usr/sbin/igmpproxy
	$(STRIP) $(INSTALLDIR)/igmpproxy/usr/sbin/igmpproxy

igmpproxy-clean:
	-@$(MAKE) -C igmpproxy/src clean
	@rm -f igmpproxy/src/Makefile
	$(call unpatch_files,igmpproxy)

hotplug2:
	@$(SEP)
	$(MAKE) -C $@ \
		EXTRACFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections"

hotplug2-install:
	$(MAKE) -C hotplug2 install PREFIX=$(INSTALLDIR)/hotplug2 SUBDIRS=""
	$(MAKE) -C hotplug2/examples install PREFIX=$(INSTALLDIR)/hotplug2/rom KERNELVER=$(LINUX_KERNEL)

emf:
	$(MAKE) -C $(SRCBASE)/emf/emfconf CROSS=$(CROSS_COMPILE) EXTRACFLAGS="$(EXTRACFLAGS)"

emf-install:
	$(MAKE) -C $(SRCBASE)/emf/emfconf INSTALLDIR=$(INSTALLDIR) install

igs:
	$(MAKE) -C $(SRCBASE)/emf/igsconf CROSS=$(CROSS_COMPILE) EXTRACFLAGS="$(EXTRACFLAGS)"

igs-install: igs
	$(MAKE) -C $(SRCBASE)/emf/igsconf INSTALLDIR=$(INSTALLDIR) install

wanuptime: nvram shared
	@$(SEP)
	@$(MAKE) -C wanuptime

wanuptime-clean:
	-@$(MAKE) -C wanuptime clean

wanuptime-install:
	install -D wanuptime/wanuptime $(INSTALLDIR)/wanuptime/usr/sbin/wanuptime
	$(STRIP) $(INSTALLDIR)/wanuptime/usr/sbin/wanuptime

ebtables/stamp-h1: dummy
ifeq ($(TCONFIG_IPV6),y)
	mv patches/ebtables/104-do-not-build-ipv6-extension.patch patches/ebtables/104-do-not-build-ipv6-extension.patch.tmp || true
else
	mv patches/ebtables/104-do-not-build-ipv6-extension.patch.tmp patches/ebtables/104-do-not-build-ipv6-extension.patch || true
endif
	$(call patch_files,ebtables)
	cd $(TOP)/ebtables && ./autogen.sh && \
	$(CONFIGURE) --prefix=/usr --bindir=/usr/sbin --sysconfdir=/etc --libdir=/usr/lib \
		CFLAGS="-Os $(EXTRACFLAGS) -DEBT_MIN_ALIGN=4 -D_GNU_SOURCE -ffunction-sections -fdata-sections -fPIC $(OPTSIZE_FLAG)" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
		LOCKFILE="/var/lock/ebtables"
	@touch $@

ebtables: ebtables/stamp-h1
	@$(SEP)
	@$(MAKE) -C ebtables

ebtables-install:
	@mkdir -p $(TARGETDIR)/rom/etc
	@sed 's/#.*//g;s/[ \t]\+/ /g;s/^[ \t]*//;s/[ \t]*$$//;/^$$/d' < $(TOP)/ebtables/ethertypes > $(TARGETDIR)/rom/etc/ethertypes
	chmod 0644 $(TARGETDIR)/rom/etc/ethertypes
	install -D ebtables/.libs/ebtables-legacy $(INSTALLDIR)/ebtables/usr/sbin/ebtables-legacy
	install -D ebtables/.libs/libebtc.so.0.0.0 $(INSTALLDIR)/ebtables/usr/lib/libebtc.so.0.0.0
	$(STRIP) $(INSTALLDIR)/ebtables/usr/sbin/ebtables-legacy
	$(STRIP) $(INSTALLDIR)/ebtables/usr/lib/libebtc.so.0.0.0
	cd $(INSTALLDIR)/ebtables/usr/sbin/ && ln -sf ebtables-legacy ebtables
	cd $(INSTALLDIR)/ebtables/usr/lib/ && ln -sf libebtc.so.0.0.0 libebtc.so && ln -sf libebtc.so.0.0.0 libebtc.so.0

ebtables-clean:
	-@$(MAKE) -C ebtables clean
	rm -f ebtables/stamp-h1
	$(call unpatch_files,ebtables)

spawn-fcgi/stamp-h1:
	$(call patch_files,spawn-fcgi)
	cd spawn-fcgi && autoreconf -fsi && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
	ac_cv_func_malloc_0_nonnull=yes \
	$(CONFIGURE) --prefix=/usr
	@touch $@

spawn-fcgi: spawn-fcgi/stamp-h1
	@$(SEP)
	@$(MAKE) -C spawn-fcgi

spawn-fcgi-clean:
	-@$(MAKE) -C spawn-fcgi clean
	rm -f spawn-fcgi/stamp-h1
	$(call unpatch_files,spawn-fcgi)

spawn-fcgi-install:
	install -d $(INSTALLDIR)/spawn-fcgi/usr/bin
	install spawn-fcgi/src/spawn-fcgi $(INSTALLDIR)/spawn-fcgi/usr/bin/spawn-fcgi
	$(STRIP) -s $(INSTALLDIR)/spawn-fcgi/usr/bin/spawn-fcgi

glib/stamp-h1:
	$(call patch_files,glib)
	@cd glib && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC $(OPTSIZE_FLAG)" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
	$(CONFIGURE) --prefix=/usr glib_cv_prog_cc_ansi_proto=no glib_cv_has__inline=yes glib_cv_has__inline__=yes glib_cv_hasinline=yes \
		glib_cv_sane_realloc=yes glib_cv_va_copy=no glib_cv___va_copy=yes glib_cv_va_val_copy=yes glib_cv_rtldglobal_broken=no \
		glib_cv_uscore=no glib_cv_func_pthread_mutex_trylock_posix=yes glib_cv_func_pthread_cond_timedwait_posix=yes glib_cv_sizeof_gmutex=24 \
		glib_cv_byte_contents_gmutex="0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0" glib_cv_sys_pthread_getspecific_posix=yes \
		glib_cv_sys_pthread_mutex_trylock_posix=yes glib_cv_sys_pthread_cond_timedwait_posix=yes ac_cv_func_getpwuid_r=yes ac_cv_func_getpwuid_r_posix=yes
	@$(MAKE) -C glib
	@touch $@

glib: glib/stamp-h1
	@$(SEP)
	@$(MAKE) -C glib $(PARALLEL_BUILD)

glib-clean:
	-@$(MAKE) -C glib clean
	rm -f glib/stamp-h1
	$(call unpatch_files,glib)

glib-install: glib
	@$(MAKE) -C glib DESTDIR=$(INSTALLDIR)/glib install

nocat/stamp-h1: glib-install
	@cd nocat && \
	NC_CONF_PATH="/" \
	CFLAGS="-Os -Wall $(EXTRACFLAGS)" \
	$(CONFIGURE) --with-firewall=iptables --with-glib-prefix="$(INSTALLDIR)/glib/usr" --localstatedir=/var --sysconfdir=/etc
	@$(MAKE) -C nocat

	echo *** integrate glib to nocat installdir
	install -d $(INSTALLDIR)/nocat/usr/lib
	install -D glib/.libs/libglib-1.2.so.0.0.10 $(INSTALLDIR)/nocat/usr/lib/libglib-1.2.so.0.0.10
	cd $(INSTALLDIR)/nocat/usr/lib && ln -s libglib-1.2.so.0.0.10 libglib-1.2.so.0
	$(STRIP) $(INSTALLDIR)/nocat/usr/lib/libglib-1.2.so.0.0.10
	@touch $@

nocat: nocat/stamp-h1
	@$(SEP)
	@$(MAKE) -C nocat $(PARALLEL_BUILD)

nocat-clean:
	-@$(MAKE) -C nocat clean
	rm -f nocat/stamp-h1

nocat-install:
	install -D nocat/src/splashd $(INSTALLDIR)/nocat/usr/sbin/splashd
	$(STRIP) $(INSTALLDIR)/nocat/usr/sbin/splashd
	mkdir -p $(INSTALLDIR)/nocat/usr/libexec/nocat
	install -D nocat/libexec/iptables/* $(INSTALLDIR)/nocat/usr/libexec/nocat
	rm -rf $(INSTALLDIR)/glib/*

pcre/stamp-h1:
	$(call patch_files,pcre)
	cd pcre && autoreconf -fsi && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS)" \
		$(CONFIGURE) --prefix=/usr --disable-dependency-tracking --enable-utf8 --enable-unicode-properties --disable-cpp
	[ -d pcre/m4 ] || mkdir pcre/m4
	@touch $@

pcre: pcre/stamp-h1
	@$(SEP)
	@$(MAKE) -C pcre

pcre-install:
	install -D pcre/.libs/libpcre.so.1 $(INSTALLDIR)/pcre/usr/lib/libpcre.so.1.2.12
	$(STRIP) -s $(INSTALLDIR)/pcre/usr/lib/libpcre.so.1.2.12
	cd $(INSTALLDIR)/pcre/usr/lib/ && \
		ln -sf libpcre.so.1.2.12 libpcre.so.1
#unused at the moment - shibby
#	install -D pcre/.libs/libpcreposix.so.0.0.7 $(INSTALLDIR)/pcre/usr/lib/libpcreposix.so.0.0.7
#	$(STRIP) -s $(INSTALLDIR)/pcre/usr/lib/libpcreposix.so.0.0.7
#	cd $(INSTALLDIR)/pcre/usr/lib/ && \
#		ln -sf libpcreposix.so.0.0.7 libpcreposix.so.0

pcre-clean:
	( if [ -f pcre/Makefile ]; then \
		$(MAKE) -C pcre clean; \
		rm -rf pcre/stamp-h1; \
	fi )
	$(call unpatch_files,pcre)

libxml2/stamp-h1:
	cd libxml2 && autoreconf -fsi && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -fPIC" \
		$(CONFIGURE) --prefix=/usr --without-python --enable-static --enable-shared --with-zlib="$(TOP)/zlib/staged/usr" \
			--includedir="$(TOP)/libxml2/include" --without-lzma --disable-dependency-tracking
	@touch $@

libxml2: libxml2/stamp-h1
	@$(SEP)
	@$(MAKE) -C libxml2 all $(PARALLEL_BUILD)
	@$(MAKE) -C libxml2 DESTDIR=$(TOP)/libxml2/staged install

libxml2-install:
	install -D libxml2/.libs/libxml2.so.2.9.12 $(INSTALLDIR)/libxml2/usr/lib/libxml2.so.2.9.12
	$(STRIP) $(INSTALLDIR)/libxml2/usr/lib/libxml2.so.2.9.12
	cd $(INSTALLDIR)/libxml2/usr/lib && \
		ln -sf libxml2.so.2.9.12 libxml2.so.2 && \
		ln -sf libxml2.so.2.9.12 libxml2.so

libxml2-clean:
	-@$(MAKE) -C libxml2 clean
	@rm -f libxml2/stamp-h1
	@rm -rf libxml2/staged

libpng/stamp-h1:
	cd libpng && \
		CFLAGS="-Os -Wall -I$(TOP)/zlib $(EXTRACFLAGS)" \
		LDFLAGS="-L$(TOP)/zlib" \
		$(CONFIGURE) --prefix=/usr --enable-static --enable-shared
	@touch $@

libpng: libpng/stamp-h1
	@$(SEP)
	@$(MAKE) -C libpng all $(PARALLEL_BUILD)
	@$(MAKE) -C libpng DESTDIR=$(TOP)/libpng/staged install
	@rm -f $(TOP)/libpng/staged/usr/lib/libpng.la
	@rm -f $(TOP)/libpng/staged/usr/lib/libpng12.la

libpng-install:
	install -D libpng/.libs/libpng.so.3.59.0 $(INSTALLDIR)/libpng/usr/lib/libpng.so.3.59.0
	$(STRIP) $(INSTALLDIR)/libpng/usr/lib/libpng.so.3.59.0
	cd $(INSTALLDIR)/libpng/usr/lib && \
		ln -sf libpng.so.3.59.0 libpng.so && \
		ln -sf libpng.so.3.59.0 libpng.so.3
	install -D libpng/.libs/libpng12.so.0.59.0 $(INSTALLDIR)/libpng/usr/lib/libpng12.so.0.59.0
	$(STRIP) $(INSTALLDIR)/libpng/usr/lib/libpng12.so.0.59.0
	cd $(INSTALLDIR)/libpng/usr/lib && \
		ln -sf libpng12.so.0.59.0 libpng12.so && \
		ln -sf libpng12.so.0.59.0 libpng12.so.0

libpng-clean:
	-@$(MAKE) -C libpng clean
	@rm -f libpng/stamp-h1
	@rm -rf libpng/staged

libatomic_ops/stamp-h1:
	cd libatomic_ops && ./autogen.sh && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS)" \
		$(CONFIGURE) --prefix=/usr --enable-static --enable-shared
	@touch $@

libatomic_ops: libatomic_ops/stamp-h1
	@$(SEP)
	@$(MAKE) -C libatomic_ops $(PARALLEL_BUILD)

libatomic_ops-install: libatomic_ops
	install -D libatomic_ops/src/.libs/libatomic_ops.so.1.0.3 $(INSTALLDIR)/libatomic_ops/usr/lib/libatomic_ops.so.1.0.3
	$(STRIP) $(INSTALLDIR)/libatomic_ops/usr/lib/libatomic_ops.so.1.0.3

libatomic_ops-clean:
	-@$(MAKE) -C libatomic_ops clean
	@rm -f libatomic_ops/stamp-h1

php/stamp-h1: pcre zlib libiconv sqlite libxml2 libpng jpeg libcurl
	$(call patch_files,php)
	cd php && \
	CFLAGS="-Os -Wall -I$(TOP)/zlib -I$(TOP)/libxml2/include/libxml -I$(TOP)/libxml2/include -I$(TOP)/pcre -I$(TOP)/libiconv/include \
		-I$(TOP)/libpng/staged/usr/include -I$(TOP)/libcurl/staged/usr/include" \
	LDFLAGS="-L$(TOP)/pcre/.libs -L$(TOP)/sqlite/.libs -L$(TOP)/zlib -L$(TOP)/libxml2/.libs -L$(TOP)/libiconv/lib/.libs \
		-L$(TOP)/libpng/.libs -L$(TOP)/libcurl/staged/usr/lib -Wl,-rpath,$(TOP)/$(OPENSSLDIR)" \
	CPPFLAGS="-L$(TOP)/pcre/.libs -L$(TOP)/sqlite/.libs -L$(TOP)/zlib -L$(TOP)/libxml2/.libs -L$(TOP)/libiconv/lib/.libs -L$(TOP)/libpng/.libs" \
	LIBS="-L$(TOP)/pcre/.libs -L$(TOP)/sqlite/.libs -L$(TOP)/zlib -L$(TOP)/libxml2/.libs -L$(TOP)/libiconv/lib/.libs -L$(TOP)/libpng/.libs -L$(TOP)/libcurl/lib/.libs -L$(TOP)/$(OPENSSLDIR) \
		-lz -lsqlite3 -ldl -lpthread -liconv -lxml2 -lstdc++ -lcurl -lcrypto -lssl" \
	PHP_FCGI_LIBXML_DIR="$(TOP)/libxml2/staged/usr" \
	ac_cv_func_memcmp_working=yes \
	cv_php_mbstring_stdarg=yes \
	$(CONFIGURE) --prefix=/usr \
	--enable-shared \
	--disable-static \
	--disable-rpath \
	--disable-debug \
	--without-pear \
	--with-config-file-path=/etc \
	--with-config-file-scan-dir=/etc/php5 \
	--disable-short-tags \
	--with-zlib \
	--with-zlib-dir="$(TOP)/zlib/staged/usr" \
	--disable-phar \
	--enable-cli \
	--enable-cgi \
	--disable-calendar \
	--enable-ctype \
	--with-curl="$(TOP)/libcurl/staged/usr" \
	--enable-fileinfo \
	--without-gettext \
	--enable-dom \
	--enable-exif \
	--disable-ftp \
	--without-gmp \
	--with-gd \
	--with-png-dir="$(TOP)/libpng/staged/usr" \
	--with-jpeg-dir="$(TOP)/jpeg/staged" \
	--enable-hash \
	--with-iconv="$(TOP)/libiconv/staged/usr" \
	--with-iconv-dir="$(TOP)/libiconv/staged/usr" \
	--enable-json \
	--without-ldap \
	--enable-mbstring \
	--without-openssl \
	--disable-pcntl \
	--with-mysqli \
	--with-mysql-sock="/var/run/mysqld.sock" \
	--with-pdo-mysql \
	--without-pdo-pgsql \
	--with-pdo-sqlite \
	--enable-pdo \
	--without-pgsql \
	--enable-session \
	--disable-shmop \
	--enable-simplexml \
	--disable-soap \
	--disable-sockets \
	--with-sqlite3 \
	--disable-sysvmsg \
	--disable-sysvsem \
	--disable-sysvshm \
	--disable-tokenizer \
	--enable-xml \
	--enable-xmlreader \
	--enable-xmlwriter \
	--enable-zip \
	--without-valgrind \
	--with-libxml-dir="$(TOP)/libxml2/staged/usr"
	@touch $@

php: php/stamp-h1
	@$(SEP)
	@$(MAKE) -C php

php-clean:
	-@$(MAKE) -C php clean
	-@rm php/stamp-h1
	$(call unpatch_files,php)

php-install:
	install -d $(INSTALLDIR)/php/usr/sbin
	install -D php/sapi/cli/.libs/php $(INSTALLDIR)/php/usr/sbin/php-cli && chmod 0755 $(INSTALLDIR)/php/usr/sbin/php-cli
	$(STRIP) $(INSTALLDIR)/php/usr/sbin/php-cli
	install -D php/sapi/cgi/.libs/php-cgi $(INSTALLDIR)/php/usr/sbin/php-cgi && chmod 0755 $(INSTALLDIR)/php/usr/sbin/php-cgi
	cd $(INSTALLDIR)/php/usr/sbin && ln -sf php-cgi php-fcgi
	$(STRIP) $(INSTALLDIR)/php/usr/sbin/php-cgi

nginx/stamp-h1: $(OPENSSLDIR) zlib pcre libatomic_ops
	$(call patch_files,nginx)
	cd nginx && \
	./configure --crossbuild=Linux::$(ARCH) \
		--with-cc="$(CC)" \
		--with-cc-opt="-Os -Wall $(EXTRACFLAGS) -I$(TOP)/$(OPENSSLDIR)/include -I$(TOP)/pcre -I$(TOP)/zlib -I$(TOP)/libatomic_ops/src/.libs" \
		--with-ld-opt="-L$(TOP)/pcre/.libs -L$(TOP)/zlib -L$(TOP)/$(OPENSSLDIR) -L$(TOP)/libatomic_ops/src" \
		--prefix=/usr \
		--sbin-path=/usr/sbin \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/tmp/var/log/nginx/error.log \
		--http-log-path=/tmp/var/log/nginx/access.log \
		--pid-path=/tmp/var/run/nginx.pid \
		--lock-path=/tmp/var/run/nginx.lock.accept \
		--http-client-body-temp-path=/tmp/var/lib/nginx/client \
		--http-fastcgi-temp-path=/tmp/var/lib/nginx/fastcgi \
		--http-uwsgi-temp-path=/tmp/var/lib/nginx/uwsgi \
		--http-scgi-temp-path=/tmp/var/lib/nginx/scgi \
		--http-proxy-temp-path=/tmp/var/lib/nginx/proxy \
		--with-http_flv_module \
		--with-http_ssl_module \
		--with-http_gzip_static_module \
		--with-http_v2_module \
		--with-libatomic="$(TOP)/libatomic_ops" \
		$(ADDITIONAL_MODULES)
	@touch $@

nginx: nginx/stamp-h1
	@$(SEP)
	@$(MAKE) -C nginx

nginx-clean:
	-@$(MAKE) -C nginx clean
	-@rm -f nginx/stamp-h1
	$(call unpatch_files,nginx)

nginx-install:
	install -D nginx/objs/nginx $(INSTALLDIR)/nginx/usr/sbin/nginx && chmod 0755 $(INSTALLDIR)/nginx/usr/sbin/nginx
	$(STRIP) $(INSTALLDIR)/nginx/usr/sbin/nginx

libncurses/stamp-h1:
	cd libncurses && \
	CFLAGS="-Os -Wall -ffunction-sections -fdata-sections -fPIC" \
	CPPFLAGS="$(EXTRACFLAGS) -Os -fPIC" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
	LIBS="-lstdc++" \
	$(CONFIGURE) --prefix=/usr --with-shared --with-normal --disable-debug --without-ada --without-manpages --without-progs \
		--without-tests --without-cxx --without-cxx-bindings --with-build-cppflags=-D_GNU_SOURCE
	@touch $@

libncurses: libncurses/stamp-h1
	@$(SEP)
	$(MAKE) -C libncurses $(PARALLEL_BUILD)
	$(MAKE) -C libncurses DESTDIR=$(TOP)/libncurses/staged install

libncurses-clean:
	-@$(MAKE) -C libncurses clean
	@rm -f libncurses/stamp-h1 libncurses/Makefile
	@rm -rf libncurses/staged

libncurses-install:
	install -d $(INSTALLDIR)/libncurses/usr/lib
	install -d $(INSTALLDIR)/libncurses/usr/share/terminfo
	install -d $(INSTALLDIR)/libncurses/usr/share/terminfo/l
	install -d $(INSTALLDIR)/libncurses/usr/share/terminfo/v
	install -d $(INSTALLDIR)/libncurses/usr/share/terminfo/x
	install -D -m 0644 libncurses/staged/usr/share/terminfo/l/linux $(INSTALLDIR)/libncurses/usr/share/terminfo/l
	install -D -m 0644 libncurses/staged/usr/share/terminfo/v/vt100 $(INSTALLDIR)/libncurses/usr/share/terminfo/v
	install -D -m 0644 libncurses/staged/usr/share/terminfo/v/vt220 $(INSTALLDIR)/libncurses/usr/share/terminfo/v
	install -D -m 0644 libncurses/staged/usr/share/terminfo/x/xterm $(INSTALLDIR)/libncurses/usr/share/terminfo/x
	install -D -m 0644 libncurses/staged/usr/share/terminfo/x/xterm-256color $(INSTALLDIR)/libncurses/usr/share/terminfo/x
	cd $(INSTALLDIR)/libncurses/usr/lib && ln -sf ../share/terminfo terminfo
	install libncurses/lib/libncurses.so.6.2 $(INSTALLDIR)/libncurses/usr/lib/libncurses.so.6
	$(STRIP) $(INSTALLDIR)/libncurses/usr/lib/libncurses.so.6
	install libncurses/lib/libpanel.so.6.2 $(INSTALLDIR)/libncurses/usr/lib/libpanel.so.6
	$(STRIP) $(INSTALLDIR)/libncurses/usr/lib/libpanel.so.6
	install libncurses/lib/libform.so.6.2 $(INSTALLDIR)/libncurses/usr/lib/libform.so.6
	$(STRIP) $(INSTALLDIR)/libncurses/usr/lib/libform.so.6
	install libncurses/lib/libmenu.so.6.2 $(INSTALLDIR)/libncurses/usr/lib/libmenu.so.6
	$(STRIP) $(INSTALLDIR)/libncurses/usr/lib/libmenu.so.6
	cd $(INSTALLDIR)/libncurses/usr/lib/ && \
		ln -sf libncurses.so.6 libncurses.so && \
		ln -sf libpanel.so.6 libpanel.so && \
		ln -sf libform.so.6 libform.so && \
		ln -sf libmenu.so.6 libmenu.so

mysql/stamp-h1: $(OPENSSLDIR) zlib libncurses
	@cp -f $(TOP)/patches/mysql/.host.tgz $(TOP)/mysql/ || true
	$(call patch_files,mysql)
	cd mysql && \
	CFLAGS="-Os -Wall -fno-delete-null-pointer-checks -funit-at-a-time --param large-function-growth=800 \
		--param max-inline-insns-single=3000 -ffunction-sections -fdata-sections -fPIC -I$(TOP)/zlib \
		-I$(TOP)/$(OPENSSLDIR)/include -I$(TOP)/libncurses/include" \
	CPPFLAGS="-Os -Wall -fno-delete-null-pointer-checks -funit-at-a-time --param large-function-growth=800 \
		--param max-inline-insns-single=3000 -ffunction-sections -fdata-sections -fPIC -I$(TOP)/zlib \
		-I$(TOP)/$(OPENSSLDIR)/include -I$(TOP)/libncurses/include" \
	LDFLAGS="-L$(TOP)/$(OPENSSLDIR) -L$(TOP)/zlib/staged/usr/lib -L$(TOP)/libncurses/lib -fPIC -EL" \
	LIBS="-lcrypt -lz -lstdc++ -lssl -lcrypto -lncurses -lpthread" \
	$(CONFIGURE) --prefix=/usr \
		--without-debug --without-docs --without-man --with-charset=utf8 --with-extra-charsets=ascii,latin1,gb2312,gbk \
		--enable-shared --disable-static \
		--without-mysqlmanager \
		--with-pthread \
		--with-ssl \
		--without-docs \
		--with-geometry \
		--with-low-memory \
		--enable-assembler \
		--with-zlib-dir="$(TOP)/zlib/staged/usr" \
		ac_cv_c_stack_direction=-1
	cd mysql && tar xvfz .host.tgz
	@touch $@

mysql: mysql/stamp-h1
	@$(SEP)
	@$(MAKE) -C mysql
	@$(MAKE) -C mysql DESTDIR=$(TOP)/mysql/staged install

mysql-clean:
	-@$(MAKE) -C mysql clean
	-@rm -f mysql/stamp-h1
	-@rm -rf mysql/staged mysql/host
	-@rm -f mysql/.host.tgz
	$(call unpatch_files,mysql)

mysql-install:
	install -d $(INSTALLDIR)/mysql/usr/bin
	install -d $(INSTALLDIR)/mysql/usr/lib
	install -d $(INSTALLDIR)/mysql/usr/libexec
	install -d $(INSTALLDIR)/mysql/usr/lib/mysql
	install -d $(INSTALLDIR)/mysql/usr/lib/mysql/plugin
	install -d $(INSTALLDIR)/mysql/usr/share
	install -d $(INSTALLDIR)/mysql/usr/share/mysql
	install -D -m 755 mysql/staged/usr/bin/my_print_defaults $(INSTALLDIR)/mysql/usr/bin
	$(STRIP) $(INSTALLDIR)/mysql/usr/bin/my_print_defaults
	install -D -m 755 mysql/staged/usr/bin/myisamchk $(INSTALLDIR)/mysql/usr/bin
	$(STRIP) $(INSTALLDIR)/mysql/usr/bin/myisamchk
	install -D -m 755 mysql/staged/usr/bin/mysql $(INSTALLDIR)/mysql/usr/bin
	$(STRIP) $(INSTALLDIR)/mysql/usr/bin/mysql
	install -D -m 755 mysql/staged/usr/bin/mysql_install_db $(INSTALLDIR)/mysql/usr/bin
	install -D -m 755 mysql/staged/usr/bin/mysqladmin $(INSTALLDIR)/mysql/usr/bin
	$(STRIP) $(INSTALLDIR)/mysql/usr/bin/mysqladmin
	install -D -m 755 mysql/staged/usr/bin/mysqldump $(INSTALLDIR)/mysql/usr/bin
	$(STRIP) $(INSTALLDIR)/mysql/usr/bin/mysqldump
	install -D -m 755 mysql/staged/usr/libexec/mysqld $(INSTALLDIR)/mysql/usr/libexec
	$(STRIP) $(INSTALLDIR)/mysql/usr/libexec/mysqld
	cd $(INSTALLDIR)/mysql/usr/bin && ln -sf ../libexec/mysqld mysqld
#	install -D -m 755 mysql/staged/usr/bin/mysqld_safe $(INSTALLDIR)/mysql/usr/bin
	install -D -m 755 mysql/staged/usr/lib/mysql/libmysqlclient.so.16.0.0 $(INSTALLDIR)/mysql/usr/lib/mysql
	$(STRIP) $(INSTALLDIR)/mysql/usr/lib/mysql/libmysqlclient.so.16.0.0
	-@cd $(INSTALLDIR)/mysql/usr/lib/mysql && \
		ln -sf libmysqlclient.so.16.0.0 libmysqlclient.so.16 && \
		ln -sf libmysqlclient.so.16.0.0 libmysqlclient.so
	install -D -m 755 mysql/staged/usr/lib/mysql/libmysqlclient_r.so.16.0.0 $(INSTALLDIR)/mysql/usr/lib/mysql
	$(STRIP) $(INSTALLDIR)/mysql/usr/lib/mysql/libmysqlclient_r.so.16.0.0
	-@cd $(INSTALLDIR)/mysql/usr/lib/mysql && \
		ln -sf libmysqlclient_r.so.16.0.0 libmysqlclient_r.so.16 && \
		ln -sf libmysqlclient_r.so.16.0.0 libmysqlclient_r.so
#	-@cd $(INSTALLDIR)/mysql/usr/lib/mysql/plugin && cp -arfpu $(TOP)/mysql/staged/usr/lib/mysql/plugin/* . && \
#	rm -f *.la *.a && \
#	$(STRIP) *.so.*
	-@cd $(INSTALLDIR)/mysql/usr/share/mysql && \
	cp -arfpu $(TOP)/mysql/staged/usr/share/mysql/english . && \
	cp -arfpu $(TOP)/mysql/staged/usr/share/mysql/fill_help_tables.sql . && \
	cp -arfpu $(TOP)/mysql/staged/usr/share/mysql/mysql_system_tables.sql . && \
	cp -arfpu $(TOP)/mysql/staged/usr/share/mysql/mysql_system_tables_data.sql .

lzo/stamp-h1:
	cd lzo && \
	CFLAGS="$(CFLAG_OPTIMIZE) -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC" \
	CPPFLAGS="$(CFLAG_OPTIMIZE) -Wall -ffunction-sections -fdata-sections -fPIC" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
	$(CONFIGURE) --enable-shared --enable-static
	@touch $@

lzo: lzo/stamp-h1
	@$(SEP)
	@$(MAKE) -C lzo $(PARALLEL_BUILD)

lzo-clean:
	-@$(MAKE) -C lzo clean
	@rm -f lzo/stamp-h1

lzo-install:
	install -D lzo/src/.libs/liblzo2.so $(INSTALLDIR)/lzo/usr/lib/liblzo2.so.2.0.0
	$(STRIP) $(INSTALLDIR)/lzo/usr/lib/liblzo2.so.2.0.0
	cd $(INSTALLDIR)/lzo/usr/lib && \
		ln -sf liblzo2.so.2.0.0 liblzo2.so.2 && \
		ln -sf liblzo2.so.2.0.0 liblzo2.so

openvpn-2.4/Makefile:
	$(call patch_files,openvpn-2.4)
	cd openvpn-2.4 && autoreconf -fsi && \
	OPENSSL_CFLAGS="-I$(TOP)/$(OPENSSLDIR)/include" \
	OPENSSL_LIBS="-L$(TOP)/$(OPENSSLDIR) -lcrypto -lssl" \
	CFLAGS="$(CFLAG_OPTIMIZE) -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
	LDFLAGS="-L$(TOP)/$(OPENSSLDIR) $(if $(INSTALL_ZLIB),-L$(TOP)/zlib -lz,) -lpthread -ldl -L$(TOP)/lzo/src/.libs -ffunction-sections -fdata-sections -Wl,--gc-sections" \
	CPPFLAGS="-I$(TOP)/lzo/include -I$(TOP)/$(OPENSSLDIR)/include" \
	PLUGINDIR="/lib" IPROUTE="/usr/sbin/ip" \
	$(CONFIGURE) --prefix=/usr --bindir=/usr/sbin --libdir=/usr/lib \
		--enable-management --disable-debug --disable-plugin-auth-pam --disable-plugin-down-root --disable-dependency-tracking \
		--disable-lz4 --enable-small --disable-server --enable-iproute2 ac_cv_lib_resolv_gethostbyname=no
	@touch openvpn-2.4/.conf

openvpn-2.4: $(OPENSSLDIR) lzo $(if $(INSTALL_ZLIB),zlib,) openvpn-2.4/Makefile
	@$(SEP)
	@$(MAKE) -C openvpn-2.4 $(PARALLEL_BUILD)

openvpn-2.4-clean:
	[ ! -f openvpn-2.4/Makefile ] || $(MAKE) -C openvpn-2.4 clean
	@rm -f openvpn-2.4/Makefile
	$(call unpatch_files,openvpn-2.4)

openvpn-2.4-install:
	install -D openvpn-2.4/src/openvpn/.libs/openvpn $(INSTALLDIR)/openvpn-2.4/usr/sbin/openvpn
	$(STRIP) -s $(INSTALLDIR)/openvpn-2.4/usr/sbin/openvpn
	chmod 0500 $(INSTALLDIR)/openvpn-2.4/usr/sbin/openvpn

openvpn/Makefile:
	$(call patch_files,openvpn)
	cd openvpn && autoreconf -fsi && \
	OPENSSL_CFLAGS="-I$(TOP)/$(OPENSSLDIR)/include" \
	OPENSSL_LIBS="-L$(TOP)/$(OPENSSLDIR) -lcrypto -lssl" \
	CFLAGS="$(CFLAG_OPTIMIZE) -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
	LDFLAGS="-L$(TOP)/$(OPENSSLDIR) $(if $(INSTALL_ZLIB),-L$(TOP)/zlib -lz,) -lpthread -ldl -L$(TOP)/lzo/src/.libs -ffunction-sections -fdata-sections -Wl,--gc-sections" \
	CPPFLAGS="-I$(TOP)/lzo/include -I$(TOP)/$(OPENSSLDIR)/include" \
	PLUGINDIR="/lib" IPROUTE="/usr/sbin/ip" \
	$(CONFIGURE) --prefix=/usr --bindir=/usr/sbin --libdir=/usr/lib \
		--enable-management --disable-debug --disable-plugin-auth-pam --disable-plugin-down-root --disable-dependency-tracking \
		--enable-iproute2 ac_cv_lib_resolv_gethostbyname=no
	@touch openvpn/.conf

openvpn: $(OPENSSLDIR) lzo $(if $(INSTALL_ZLIB),zlib,) openvpn/Makefile
	@$(SEP)
	@$(MAKE) -C openvpn $(PARALLEL_BUILD)

openvpn-clean:
	[ ! -f openvpn/Makefile ] || $(MAKE) -C openvpn clean
	@rm -f openvpn/Makefile
	$(call unpatch_files,openvpn)

openvpn-install:
	install -D openvpn/src/openvpn/.libs/openvpn $(INSTALLDIR)/openvpn/usr/sbin/openvpn
	$(STRIP) -s $(INSTALLDIR)/openvpn/usr/sbin/openvpn
	chmod 0500 $(INSTALLDIR)/openvpn/usr/sbin/openvpn

openvpn_plugin_auth_nvram: nvram

nano/stamp-h1: libncurses
	cd nano && autoreconf -fsi && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -I$(TOP)/libncurses/staged/usr/include -ffunction-sections -fdata-sections -fPIC -std=gnu99" \
		CPPFLAGS="-Os -Wall $(EXTRACFLAGS) -I$(TOP)/libncurses/staged/usr/include -ffunction-sections -fdata-sections -fPIC" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -L$(TOP)/libncurses/staged/usr/lib -fPIC" \
		NCURSES_LIBS="-lncurses" \
		ac_cv_lib_ncursesw_get_wch=no \
		$(CONFIGURE) --prefix=/usr --disable-nls --enable-tiny --without-libiconv-prefix --disable-utf8
	@touch $@

nano: nano/stamp-h1
	@$(SEP)
	@$(MAKE) -C nano $(PARALLEL_BUILD)

nano-clean:
	-@$(MAKE) -C nano clean
	@rm -f nano/stamp-h1 nano/Makefile nano/src/Makefile

nano-install:
	install -d $(INSTALLDIR)/nano/usr/sbin
	install -D nano/src/nano $(INSTALLDIR)/nano/usr/sbin/nano
	$(STRIP) -s $(INSTALLDIR)/nano/usr/sbin/nano

ifeq ($(TCONFIG_STUBBY),y)
CACERT:=--with-ca-fallback
else
CACERT:=
endif

libcurl/stamp-h1: zlib $(OPENSSLDIR)
	$(call patch_files,libcurl)
	cd libcurl && ./buildconf && \
		CFLAGS="-Os -Wall -pipe -funit-at-a-time -Wno-pointer-sign $(if $(TCONFIG_MIPSR2),-march=mips32r2 -mips32r2 -mtune=mips32r2,-march=mips32 -mips32 -mtune=mips32) -ffunction-sections -fdata-sections -fPIC" \
		CPPFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC -I$(TOP)/$(OPENSSLDIR)/include" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC -L$(TOP)/$(OPENSSLDIR) -Wl,-rpath,$(TOP)/$(OPENSSLDIR)" \
		LIBS="-lpthread" \
		$(CONFIGURE) --prefix=/usr --bindir=/usr/sbin --libdir=/usr/lib \
			--enable-shared --enable-static --enable-cookies --enable-crypto-auth \
			--enable-nonblocking --enable-file --enable-ftp --enable-http --enable-tftp \
			$(if $(TCONFIG_IPV6),--enable-ipv6,) \
			--with-random="/dev/urandom" --with-ssl="$(TOP)/$(OPENSSLDIR)" --with-zlib="$(TOP)/zlib/staged/usr" \
			--disable-nls --disable-dict --disable-debug --disable-gopher --disable-threaded-resolver \
			--disable-ldap --disable-manual --disable-telnet --disable-verbose \
			--without-gnutls --without-krb4 --without-libidn2 --without-libpsl --disable-tls-srp \
			--with-linux-headers=$(LINUXDIR)/include $(CACERT)
	@touch $@

libcurl: libcurl/stamp-h1
	@$(SEP)
	@$(MAKE) -C libcurl $(PARALLEL_BUILD)
	@$(MAKE) -C libcurl DESTDIR=$(TOP)/libcurl/staged install
	@rm -f libcurl/staged/usr/lib/libcurl.la

libcurl-install:
	install -D libcurl/lib/.libs/libcurl.so.4.7.0 $(INSTALLDIR)/libcurl/usr/lib/libcurl.so.4.7.0
	$(STRIP) -s $(INSTALLDIR)/libcurl/usr/lib/libcurl.so.4.7.0
	cd $(INSTALLDIR)/libcurl/usr/lib/ && ln -sf libcurl.so.4.7.0 libcurl.so && ln -sf libcurl.so.4.7.0 libcurl.so.4
	install -D libcurl/src/.libs/curl $(INSTALLDIR)/libcurl/usr/sbin/curl
	$(STRIP) -s $(INSTALLDIR)/libcurl/usr/sbin/curl

libcurl-clean:
	-@$(MAKE) -C libcurl clean
	@rm -f libcurl/stamp-h1 libcurl/Makefile
	@rm -rf libcurl/staged
	$(call unpatch_files,libcurl)

libevent/stamp-h1:
	cd libevent && ./autogen.sh && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC" \
		CPPFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC -I$(TOP)/zlib $(if $(TCONFIG_HTTPS),-I$(TOP)/$(OPENSSLDIR)/include,) -fPIC" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC -L$(TOP)/zlib $(if $(TCONFIG_HTTPS),-L$(TOP)/$(OPENSSLDIR),)" \
		PKG_CONFIG_PATH="$(PKG_CONFIG_PATH):$(TOP)/$(OPENSSLDIR)" \
		$(CONFIGURE) $(if $(TCONFIG_HTTPS),,--disable-openssl) --disable-doxygen-html \
			--disable-debug-mode --disable-samples --disable-dependency-tracking
	@touch $@

libevent: libevent/stamp-h1
	@$(SEP)
	$(MAKE) -C libevent $(PARALLEL_BUILD)
	$(MAKE) -C libevent DESTDIR=$(TOP)/libevent/staged install

libevent-clean:
	-@$(MAKE) -C libevent clean
	@rm -f libevent/stamp-h1 libevent/Makefile
	@rm -rf libevent/staged

libevent-install:
	install -d $(INSTALLDIR)/libevent/usr/lib
	install libevent/.libs/libevent-2.1.so.7.0.1 $(INSTALLDIR)/libevent/usr/lib/libevent-2.1.so.7
	$(STRIP) -s $(INSTALLDIR)/libevent/usr/lib/libevent-2.1.so.7

libiconv/stamp-h1:
	cd libiconv && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -fPIC" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
		$(CONFIGURE) --prefix=/usr --disable-nls --enable-static --enable-shared
	@touch $@

libiconv: libiconv/stamp-h1
	@$(SEP)
	$(MAKE) -C libiconv $(PARALLEL_BUILD)
	$(MAKE) -C libiconv DESTDIR=$(TOP)/libiconv/staged install

libiconv-clean:
	-@$(MAKE) -C libiconv clean
	@rm -rf libiconv/stamp-h1 libiconv/Makefile
	@rm -rf libiconv/staged

libiconv-install:
	install -d $(INSTALLDIR)/libiconv/usr/lib
	install libiconv/lib/.libs/libiconv.so.2.6.1 $(INSTALLDIR)/libiconv/usr/lib/libiconv.so.2.6.1
	$(STRIP) -s $(INSTALLDIR)/libiconv/usr/lib/libiconv.so.2.6.1
	cd $(INSTALLDIR)/libiconv/usr/lib/ && \
		ln -sf libiconv.so.2.6.1 libiconv.so.2 && \
		ln -sf libiconv.so.2.6.1 libiconv.so

transmission/stamp-h1: $(OPENSSLDIR) libcurl libevent zlib
	cd transmission && ./autogen.sh && \
		CFLAGS="-O3 -Wall -pipe $(if $(TCONFIG_MIPSR2),-march=mips32r2 -mips32r2 -mtune=mips32r2,-march=mips32 -mips32 -mtune=mips32) -fno-delete-null-pointer-checks -funit-at-a-time -ffunction-sections -fdata-sections -fPIC --param large-function-growth=800 --param max-inline-insns-single=3600" \
		CPPFLAGS="-O3 -Wall -pipe $(if $(TCONFIG_MIPSR2),-march=mips32r2 -mips32r2 -mtune=mips32r2,-march=mips32 -mips32 -mtune=mips32) -ffunction-sections -fdata-sections -fPIC --param large-function-growth=800 --param max-inline-insns-single=3600" \
		CXXFLAGS="-O3 -Wall -pipe $(if $(TCONFIG_MIPSR2),-march=mips32r2 -mips32r2 -mtune=mips32r2,-march=mips32 -mips32 -mtune=mips32) -ffunction-sections -fdata-sections -fPIC --param large-function-growth=800 --param max-inline-insns-single=3600" \
		LDFLAGS="-L$(TOP)/zlib -L$(TOP)/$(OPENSSLDIR) -L$(TOP)/libcurl/lib/.libs -L$(TOP)/libevent/.libs -ffunction-sections -fdata-sections -Wl,--gc-sections -fPIC" \
		$(CONFIGURE) --prefix=/usr --enable-lightweight --enable-largefile --enable-utp \
			--disable-nls --disable-cli --without-gtk --disable-dependency-tracking \
			LIBCURL_CFLAGS="-I$(TOP)/libcurl/include" \
			LIBCURL_LIBS="-lcurl" \
			LIBEVENT_CFLAGS="-I$(TOP)/libevent/include" \
			LIBEVENT_LIBS="-levent" \
			OPENSSL_CFLAGS="-I$(TOP)/$(OPENSSLDIR)/include" \
			OPENSSL_LIBS="-lcrypto -lssl" \
			ZLIB_CFLAGS="-I$(TOP)/zlib" \
			ZLIB_LIBS="-lz"
	@touch $@

transmission: transmission/stamp-h1
	@$(SEP)
	$(MAKE) -C transmission $(PARALLEL_BUILD)

transmission-clean:
	-@$(MAKE) -C transmission clean
	@rm -f transmission/stamp-h1 transmission/Makefile

transmission-install:
	$(MAKE) -C transmission DESTDIR=$(INSTALLDIR)/transmission install-strip
	@rm -rf $(INSTALLDIR)/transmission/usr/share/man
	@rm -rf $(INSTALLDIR)/transmission/usr/bin/transmission-show
	@rm -rf $(INSTALLDIR)/transmission/usr/bin/transmission-edit
	@rm -rf $(INSTALLDIR)/transmission/usr/bin/transmission-create
	$(STRIP) -s $(INSTALLDIR)/transmission/usr/bin/transmission-daemon
ifneq ($(TCONFIG_TR_EXTRAS),y)
	@rm -rf $(INSTALLDIR)/transmission/usr/bin/transmission-remote
else
	$(STRIP) -s $(INSTALLDIR)/transmission/usr/bin/transmission-remote
endif

libnfsidmap/stamp-h1:
	cd libnfsidmap && ./autogen.sh && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS)" \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes \
		$(CONFIGURE) --prefix=/usr --enable-shared --enable-static
	@touch $@

libnfsidmap: libnfsidmap/stamp-h1
	@$(SEP)
	$(MAKE) -C libnfsidmap $(PARALLEL_BUILD)

libnfsidmap-install:
	install -d $(TOP)/libnfsidmap/staged
	$(MAKE) -C libnfsidmap DESTDIR=$(TOP)/libnfsidmap/staged install
	@rm -f libnfsidmap/staged/usr/lib/libnfsidmap.la

libnfsidmap-clean:
	-@$(MAKE) -C libnfsidmap clean
	@rm -f libnfsidmap/stamp-h1
	@rm -rf libnfsidmap/staged

portmap:
	@$(SEP)
	$(MAKE) -C portmap CFLAGS="-Os -Wall $(EXTRACFLAGS)" NO_TCP_WRAPPER=y NO_PIE=y RPCUSER=nobody $(PARALLEL_BUILD)

portmap-install:
	install -D portmap/portmap $(INSTALLDIR)/portmap/usr/sbin/portmap
	$(STRIP) -s $(INSTALLDIR)/portmap/usr/sbin/portmap

portmap-clean:
	-@$(MAKE) -C portmap clean

e2fsprogs/stamp-h1:
	$(call patch_files,e2fsprogs)
	cd e2fsprogs && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
		$(CONFIGURE) --prefix=/usr --sysconfdir=/etc --enable-elf-shlibs --disable-tls --disable-defrag $(if $(TCONFIG_BCMARM),ac_cv_lib_pthread_sem_init=no,) \
			--disable-jbd-debug --disable-blkid-debug --disable-testio-debug --disable-backtrace --disable-e2initrd-helper \
			--disable-nls --disable-debugfs --disable-imager --disable-resizer --disable-uuidd --disable-rpath
	@touch $@

e2fsprogs: e2fsprogs/stamp-h1
	@$(SEP)
	$(MAKE) -C e2fsprogs $(PARALLEL_BUILD)

e2fsprogs-install:
	install -D e2fsprogs/e2fsck/e2fsck $(INSTALLDIR)/e2fsprogs/usr/sbin/e2fsck
	install -D e2fsprogs/misc/mke2fs $(INSTALLDIR)/e2fsprogs/usr/sbin/mke2fs
	install -D e2fsprogs/misc/tune2fs $(INSTALLDIR)/e2fsprogs/usr/sbin/tune2fs
ifneq ($(TCONFIG_BCMARM),y)
ifeq ($(TCONFIG_AIO),y)
	install -D e2fsprogs/misc/badblocks $(INSTALLDIR)/e2fsprogs/usr/sbin/badblocks
endif
endif
	$(STRIP) -s $(INSTALLDIR)/e2fsprogs/usr/sbin/*
	install -D e2fsprogs/lib/libblkid.so.1.0 $(INSTALLDIR)/e2fsprogs/usr/lib/libblkid.so.1.0
	install -D e2fsprogs/lib/libcom_err.so.2.1 $(INSTALLDIR)/e2fsprogs/usr/lib/libcom_err.so.2.1
	install -D e2fsprogs/lib/libe2p.so.2.3 $(INSTALLDIR)/e2fsprogs/usr/lib/libe2p.so.2.3
	install -D e2fsprogs/lib/libext2fs.so.2.4 $(INSTALLDIR)/e2fsprogs/usr/lib/libext2fs.so.2.4
	install -D e2fsprogs/lib/libuuid.so.1.2 $(INSTALLDIR)/e2fsprogs/usr/lib/libuuid.so.1.2
	$(STRIP) -s $(INSTALLDIR)/e2fsprogs/usr/lib/*.so.*
	ln -sf libblkid.so.1.0 $(INSTALLDIR)/e2fsprogs/usr/lib/libblkid.so.1
	ln -sf libcom_err.so.2.1 $(INSTALLDIR)/e2fsprogs/usr/lib/libcom_err.so.2
	ln -sf libe2p.so.2.3 $(INSTALLDIR)/e2fsprogs/usr/lib/libe2p.so.2
	ln -sf libext2fs.so.2.4 $(INSTALLDIR)/e2fsprogs/usr/lib/libext2fs.so.2
	ln -sf libuuid.so.1.2 $(INSTALLDIR)/e2fsprogs/usr/lib/libuuid.so.1
	ln -sf e2fsck $(INSTALLDIR)/e2fsprogs/usr/sbin/fsck.ext2
	ln -sf e2fsck $(INSTALLDIR)/e2fsprogs/usr/sbin/fsck.ext3
ifeq ($(TCONFIG_BCMARM),y)
	ln -sf e2fsck $(INSTALLDIR)/e2fsprogs/usr/sbin/fsck.ext4
endif
	ln -sf mke2fs $(INSTALLDIR)/e2fsprogs/usr/sbin/mkfs.ext2
	ln -sf mke2fs $(INSTALLDIR)/e2fsprogs/usr/sbin/mkfs.ext3
ifeq ($(TCONFIG_BCMARM),y)
	ln -sf mke2fs $(INSTALLDIR)/e2fsprogs/usr/sbin/mkfs.ext4
endif
	install -D -m 0644 e2fsprogs/misc/mke2fs.conf $(INSTALLDIR)/rom/rom/etc/mke2fs.conf
	install -D -m 0644 e2fsprogs/e2fsck/e2fsck.conf $(INSTALLDIR)/rom/rom/etc/e2fsck.conf

e2fsprogs-clean:
	-@$(MAKE) -C e2fsprogs clean
	@rm -f e2fsprogs/stamp-h1
	@rm -f e2fsprogs/Makefile
	$(call unpatch_files,e2fsprogs)

nfs-utils/stamp-h1: libevent-install e2fsprogs portmap libnfsidmap-install
	$(call patch_files,nfs-utils)
	cd nfs-utils && ./autogen.sh && \
	CPPFLAGS="-Os $(EXTRACFLAGS)" \
	CFLAGS="-Os -Wall -fno-delete-null-pointer-checks -funit-at-a-time -pipe $(if $(TCONFIG_MIPSR2),-march=mips32r2 -mips32r2 -mtune=mips32r2,-march=mips32 -mips32 -mtune=mips32) -ffunction-sections -fdata-sections \
		-I$(TOP)/libevent/staged/usr/local/include \
		-I$(TOP)/libnfsidmap/staged/usr/include -ffunction-sections -fdata-sections" \
	LDFLAGS="-L$(TOP)/libevent/staged/usr/local/lib \
		-L$(TOP)/libnfsidmap/staged/usr/lib -ffunction-sections -fdata-sections -Wl,--gc-sections" \
		knfsd_cv_bsd_signals=no \
	CC_FOR_BUILD=$(CC) $(CONFIGURE) --disable-gss --without-tcp-wrappers \
		--disable-nfsv4 --disable-ipv6 \
		--disable-uuid --disable-mount --disable-tirpc --disable-dependency-tracking
	@touch $@

nfs-utils: nfs-utils/stamp-h1
	@$(SEP)
	$(MAKE) -C $@ $(PARALLEL_BUILD)

nfs-utils-install:
	install -d $(INSTALLDIR)/nfs-utils/usr/sbin
	install -D nfs-utils/utils/nfsd/nfsd $(INSTALLDIR)/nfs-utils/usr/sbin/nfsd
	install -D nfs-utils/utils/showmount/showmount $(INSTALLDIR)/nfs-utils/usr/sbin/showmount
	install -D nfs-utils/utils/exportfs/exportfs $(INSTALLDIR)/nfs-utils/usr/sbin/exportfs
	install -D nfs-utils/utils/statd/statd $(INSTALLDIR)/nfs-utils/usr/sbin/statd
	install -D nfs-utils/utils/mountd/mountd $(INSTALLDIR)/nfs-utils/usr/sbin/mountd
	$(STRIP) -s $(INSTALLDIR)/nfs-utils/usr/sbin/*

nfs-utils-clean:
	-@$(MAKE) -C nfs-utils clean
	@rm -f nfs-utils/stamp-h1
	$(call unpatch_files,nfs-utils)

tinc/stamp-h1: $(OPENSSLDIR) zlib lzo
	$(call patch_files,tinc)
	cd tinc && autoreconf -fsi && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections -I$(TOP)/$(OPENSSLDIR)/include -std=gnu99" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -L$(TOP)/$(OPENSSLDIR) -Wl,-rpath,$(TOP)/$(OPENSSLDIR)" \
	LIBS="-lpthread" \
	$(CONFIGURE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--with-zlib-include="$(TOP)/zlib" \
		--with-zlib-lib="$(TOP)/zlib" \
		--with-lzo-include="$(TOP)/lzo/include" \
		--with-lzo-lib="$(TOP)/lzo/src/.libs" \
		--with-openssl-include="$(TOP)/$(OPENSSLDIR)/include" \
		--with-openssl-lib="$(TOP)/$(OPENSSLDIR)" \
		--disable-curses \
		--disable-readline
	@touch $@

tinc: tinc/stamp-h1
	@$(SEP)
	@$(MAKE) -C tinc LIBS="-lcrypto $(TOP)/zlib/libz.a -llzo2 -lm -lpthread" $(PARALLEL_BUILD)

tinc-clean:
	-@$(MAKE) -C tinc clean
	@rm -f tinc/stamp-h1
	$(call unpatch_files,tinc)

tinc-install:
	install -D tinc/src/tinc $(INSTALLDIR)/tinc/usr/sbin/tinc
	install -D tinc/src/tincd $(INSTALLDIR)/tinc/usr/sbin/tincd
	$(STRIP) $(INSTALLDIR)/tinc/usr/sbin/tinc
	$(STRIP) $(INSTALLDIR)/tinc/usr/sbin/tincd

snmp/stamp-h1:
	$(call patch_files,snmp)
	cd snmp && autoreconf -fsi && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections $(OPTSIZE_FLAG)" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
		$(CONFIGURE) --prefix=/usr --with-persistent-directory=/tmp/snmp-persist --with-logfile=/var/log/snmpd.log \
		--disable-debugging --disable-manuals --disable-scripts --disable-applications --disable-privacy \
		--disable-ipv6 --disable-mibs --disable-mib-loading --disable-embedded-perl --with-perl-modules=no --without-opaque-special-types \
		--without-openssl --without-rsaref --without-kmem-usage --without-rpm \
		--with-out-transports=UDPIPv6,TCPIPv6,AAL5PVC,IPX,TCP,Unix \
		--with-out-mib-modules=snmpv3mibs,agent_mibs,agentx,notification,utilities,target \
		--with-mib-modules="\
			agent/extend,\
			host/hr_device,host/hr_disk,host/hr_filesys,host/hr_network,host/hr_partition,host/hr_print,host/hr_proc,host/hrSWRunTable,host/hr_storage,host/hr_system,\
			mibII/at,mibII/icmp,mibII/ifTable,mibII/ip,mibII/ipAddr,mibII/kernel_linux,mibII/snmp_mib,mibII/sysORTable,mibII/system_mib,mibII/tcp,mibII/udp,mibII/vacm_context,mibII/vacm_vars,mibII/var_route,\
			ucd-snmp/disk_hw,ucd-snmp/dlmod,ucd-snmp/extensible,ucd-snmp/loadave,ucd-snmp/logmatch,ucd-snmp/memory,ucd-snmp/pass,ucd-snmp/proc,ucd-snmp/proxy,ucd-snmp/vmstat,\
			util_funcs,if-mib/ifXTable,ip-mib/inetNetToMediaTable"\
		--with-default-snmp-version=2 --with-sys-contact=root --with-sys-location=Unknown \
		--with-endianness=little --enable-mini-agent --enable-shared=no --enable-static --with-gnu-ld \
		--enable-internal-md5 --enable-mfd-rewrites --with-defaults --with-copy-persistent-files=no
	@touch $@

snmp: snmp/stamp-h1
	@$(SEP)
	$(MAKE) -C snmp

snmp-clean:
	-@$(MAKE) -C snmp clean
	@rm -f snmp/stamp-h1
	$(call unpatch_files,snmp)

snmp-install:
	install -D snmp/agent/snmpd $(INSTALLDIR)/snmp/usr/sbin/snmpd
	$(STRIP) $(INSTALLDIR)/snmp/usr/sbin/snmpd

apcupsd/stamp-h1:
	$(call patch_files,apcupsd)
	cd apcupsd && touch autoconf/variables.mak && \
	$(MAKE) configure && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
	CPPFLAGS="-Os -Wall -ffunction-sections -fdata-sections" \
	LDFLAGS="-L$(TOOLCHAIN)/lib -ffunction-sections -fdata-sections" \
	$(CONFIGURE) --prefix=/usr --without-x --enable-usb --disable-pcnet --enable-cgi \
		--disable-lgd --enable-net --sysconfdir=/usr/local/apcupsd --bindir=/bin \
		--disable-dumb --disable-snmp --with-cgi-bin=/www/apcupsd --with-serial-dev=
	@touch $@

apcupsd: apcupsd/stamp-h1
	@$(SEP)
	$(MAKE) -C apcupsd $(PARALLEL_BUILD)

apcupsd-clean:
	-@$(MAKE) -C apcupsd clean
	@rm -f apcupsd/stamp-h1
	@rm -f apcupsd/config*
	$(call unpatch_files,apcupsd)

apcupsd-install:
	$(MAKE) -C apcupsd DESTDIR=$(INSTALLDIR)/apcupsd install
	@rm -rf $(INSTALLDIR)/apcupsd/sbin/apctest
	@rm -rf $(INSTALLDIR)/apcupsd/www/apcupsd/ups*.cgi
	$(STRIP) $(INSTALLDIR)/apcupsd/sbin/*
	$(STRIP) $(INSTALLDIR)/apcupsd/www/apcupsd/*

libsodium/stamp-h1:
	cd libsodium && autoreconf -fsi && \
		$(CONFIGURE) --prefix=/usr --disable-ssp --enable-minimal
	@touch $@

libsodium: libsodium/stamp-h1
	@$(SEP)
	$(MAKE) -C libsodium $(PARALLEL_BUILD)

libsodium-install:
	install -d $(INSTALLDIR)/libsodium/usr/lib
	install -D libsodium/src/libsodium/.libs/libsodium.so.23.0.0 $(INSTALLDIR)/libsodium/usr/lib/libsodium.so.23.0.0
	$(STRIP) -s $(INSTALLDIR)/libsodium/usr/lib/libsodium.so.23.0.0
	cd $(INSTALLDIR)/libsodium/usr/lib/ && \
		ln -sf libsodium.so.23.0.0 libsodium.so.23 && \
		ln -sf libsodium.so.23.0.0 libsodium.so

libsodium-clean:
	-$(MAKE) -C libsodium clean
	@rm -rf libsodium/stamp-h1

dnscrypt/stamp-h1: libsodium
	cd dnscrypt && autoreconf && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
		CPPFLAGS="-I$(TOP)/libsodium/src/libsodium/include" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections -L$(TOP)/libsodium/src/libsodium/.libs" \
		$(CONFIGURE) --prefix=/usr --disable-ssp
	@touch $@

dnscrypt: dnscrypt/stamp-h1
	@$(SEP)
	$(MAKE) -C dnscrypt $(PARALLEL_BUILD)

dnscrypt-install:
	install -D dnscrypt/src/proxy/.libs/dnscrypt-proxy $(INSTALLDIR)/dnscrypt/usr/sbin/dnscrypt-proxy
	install -D dnscrypt/src/hostip/.libs/hostip $(INSTALLDIR)/dnscrypt/usr/sbin/hostip
	$(STRIP) -s $(INSTALLDIR)/dnscrypt/usr/sbin/dnscrypt-proxy
	$(STRIP) -s $(INSTALLDIR)/dnscrypt/usr/sbin/hostip

dnscrypt-clean:
	-@$(MAKE) -C dnscrypt clean
	@rm -rf dnscrypt/stamp-h1 dnscrypt/src/dnscrypt-proxy/.deps dnscrypt/Makefile

libyaml/stamp-h1:
	cd libyaml && autoreconf -fsi && \
	CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
	LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
	$(CONFIGURE) --prefix=/usr --sysconfdir=/etc \
		--enable-static --disable-shared
	@touch $@

libyaml: libyaml/stamp-h1
	@$(SEP)
	$(MAKE) -C libyaml $(PARALLEL_BUILD)

libyaml-install:
	@true

libyaml-clean:
	-$(MAKE) -C libyaml clean
	@rm -rf libyaml/stamp-h1 libyaml/src/.deps libyaml/src/tests/.deps

getdns/build/Makefile:
	@rm -rf getdns/build && mkdir -p getdns/build
	$(call patch_files,getdns)
	cd getdns/build && \
	$(call CMAKE_CrossOptions, crosscompiled.cmake) && \
	cmake -DCMAKE_TOOLCHAIN_FILE=crosscompiled.cmake \
		-DCMAKE_INSTALL_PREFIX:PATH=/usr \
		-DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_SKIP_RPATH=TRUE \
		-DCMAKE_C_FLAGS="-Os -DNDEBUG -ffunction-sections -fdata-sections -std=c99 $(EXTRACFLAGS)" \
		-DCMAKE_EXE_LINKER_FLAGS="-Wl,--gc-sections $(if $(TCONFIG_OPENSSL11),-lpthread,)" \
		-DENABLE_STATIC=TRUE -DENABLE_SHARED=FALSE -DENABLE_GOST=FALSE \
		-DBUILD_GETDNS_QUERY=FALSE \
		-DBUILD_GETDNS_SERVER_MON=FALSE \
		-DBUILD_STUBBY=TRUE -DENABLE_STUB_ONLY=TRUE \
		-DBUILD_LIBEV=FALSE -DBUILD_LIBEVENT2=FALSE -DBUILD_LIBUV=FALSE \
		-DBUILD_TESTING=FALSE \
		-DOPENSSL_ROOT_DIR=$(TOP)/$(OPENSSLDIR) \
		-DOPENSSL_INCLUDE_DIR=$(TOP)/$(OPENSSLDIR)/include \
		-DOPENSSL_CRYPTO_LIBRARY=$(TOP)/$(OPENSSLDIR)/libcrypto.so \
		-DOPENSSL_SSL_LIBRARY=$(TOP)/$(OPENSSLDIR)/libssl.so \
		-DLIBYAML_DIR=$(TOP)/libyaml \
		-DLIBYAML_INCLUDE_DIR=$(TOP)/libyaml/include \
		-DLIBYAML_LIBRARY=$(TOP)/libyaml/src/.libs/libyaml.a \
		-DCMAKE_DISABLE_FIND_PACKAGE_Libsystemd=TRUE \
		-DUSE_LIBIDN2=FALSE \
		-DSTRPTIME_WORKS_EXITCODE=0 \
		-DSTRPTIME_WORKS_EXITCODE__TRYRUN_OUTPUT=1 \
		..

getdns: $(OPENSSLDIR) libyaml getdns/build/Makefile
	$(MAKE) -C getdns/build

getdns-install:
	install -d $(INSTALLDIR)/getdns/usr/sbin
	install -D getdns/build/stubby/stubby $(INSTALLDIR)/getdns/usr/sbin/stubby
	$(STRIP) -s $(INSTALLDIR)/getdns/usr/sbin/stubby

getdns-clean:
	@rm -rf getdns/build
	$(call unpatch_files,getdns)

tor/stamp-h1: $(OPENSSLDIR) zlib libevent
	cd tor && autoreconf -fsi && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS) -I$(TOP)/$(OPENSSLDIR)/include -ffunction-sections -fdata-sections $(if $(TCONFIG_KEYGEN),,-DOPENSSL_NO_ENGINE) -std=gnu99" \
		CPPFLAGS="-I$(TOP)/$(OPENSSLDIR)/include" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" \
		$(CONFIGURE) --prefix=/usr --with-libevent-dir=$(TOP)/libevent/staged/usr/local \
			--with-openssl-dir=$(TOP)/$(OPENSSLDIR) --with-zlib-dir=$(TOP)/zlib \
			--disable-asciidoc --disable-tool-name-check --disable-unittests --disable-lzma \
			--disable-seccomp --disable-libscrypt --disable-zstd-advanced-apis \
			--disable-manpage --disable-html-manual --disable-dependency-tracking --disable-zstd --disable-systemd
	@touch $@

tor: tor/stamp-h1
	@$(SEP)
	$(MAKE) -C tor $(PARALLEL_BUILD)

tor-install:
	install -d $(INSTALLDIR)/tor/usr/share
	install -D tor/src/app/tor $(INSTALLDIR)/tor/usr/sbin/tor
	$(STRIP) -s $(INSTALLDIR)/tor/usr/sbin/tor

tor-clean:
	-@$(MAKE) -C tor clean
	@rm -rf tor/stamp-h1 tor/Makefile

udpxy/stamp-h1:
	$(call patch_files,udpxy)
	@touch $@

udpxy: udpxy/stamp-h1
	@$(SEP)
	NO_UDPXREC=yes \
	$(MAKE) -C udpxy lean CFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
		CPPFLAGS="-Os -Wall $(EXTRACFLAGS) -ffunction-sections -fdata-sections" \
		LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections"

udpxy-install:
	install -d $(INSTALLDIR)/udpxy/usr/bin
	install -D udpxy/udpxy $(INSTALLDIR)/udpxy/bin/udpxy
	$(STRIP) -s $(INSTALLDIR)/udpxy/bin/udpxy

udpxy-clean:
	-@$(MAKE) -C udpxy clean
	@rm -f udpxy/stamp-h1
	$(call unpatch_files,udpxy)

mdadm:
	@$(SEP)
	$(MAKE) -C mdadm mdadm $(PARALLEL_BUILD)

mdadm-install:
	install -D mdadm/mdadm $(INSTALLDIR)/mdadm/usr/sbin/mdadm
	$(STRIP) -s $(INSTALLDIR)/mdadm/usr/sbin/mdadm

mdadm-clean:
	-@$(MAKE) -C mdadm clean

ipset:
	@$(SEP)
	$(call patch_files,ipset)
	$(MAKE) -C ipset binaries COPT_FLAGS="-Os -Wall $(EXTRACFLAGS) $(OPTSIZE_FLAG) -ffunction-sections -fdata-sections --param large-function-growth=800 --param max-inline-insns-single=3000"

ipset-install:
	install -D ipset/ipset $(INSTALLDIR)/ipset/usr/sbin/ipset
	install -d $(INSTALLDIR)/ipset/usr/lib/
	install ipset/*.so $(INSTALLDIR)/ipset/usr/lib/
	$(STRIP) $(INSTALLDIR)/ipset/usr/lib/*.so
	$(STRIP) $(INSTALLDIR)/ipset/usr/sbin/ipset

ipset-clean:
	-@$(MAKE) -C ipset clean
	$(call unpatch_files,ipset)

libjson-c/build/Makefile:
	$(call patch_files,libjson-c)
	@rm -rf libjson-c/build && mkdir -p libjson-c/build
	cd libjson-c/build && \
	$(call CMAKE_CrossOptions, crosscompiled.cmake) && \
	cmake -DCMAKE_TOOLCHAIN_FILE=crosscompiled.cmake \
		-DCMAKE_INSTALL_PREFIX:PATH=/usr \
		-DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_SKIP_RPATH=TRUE \
		-DCMAKE_C_FLAGS="-Os -DNDEBUG -ffunction-sections -fdata-sections $(EXTRACFLAGS)" \
		-DCMAKE_EXE_LINKER_FLAGS="-Wl,--gc-sections" \
		-DBUILD_TESTING=FALSE \
		-DDISABLE_WERROR=TRUE \
		-DBUILD_STATIC_LIBS=FALSE \
		..

libjson-c: libjson-c/build/Makefile
	@$(SEP)
	$(MAKE) -C libjson-c/build all
	cd libjson-c && ln -sf build/json_config.h json_config.h

libjson-c-clean:
	@rm -rf libjson-c/build
	$(call unpatch_files,libjson-c)

uqmi: libjson-c
	@$(SEP)
	$(call patch_files,libubox)
	$(MAKE) -C uqmi/libubox
	$(MAKE) -C uqmi SHARED=0 CC='$(CC) -static'

uqmi-install:
	install -D uqmi/uqmi $(INSTALLDIR)/uqmi/usr/sbin/uqmi
	$(STRIP) $(INSTALLDIR)/uqmi/usr/sbin/uqmi

uqmi-clean: libjson-c-clean
	-@$(MAKE) -C uqmi/libubox clean
	$(call unpatch_files,libubox)
	-@$(MAKE) -C uqmi clean

comgt:
	@$(SEP)
	$(call patch_files,comgt)
	@$(MAKE) -C comgt CFLAGS="-Os $(EXTRACFLAGS)" LDFLAGS="-ffunction-sections -fdata-sections -Wl,--gc-sections" comgt

comgt-install:
	install -D comgt/comgt $(INSTALLDIR)/comgt/usr/sbin/comgt
	cd $(INSTALLDIR)/comgt/usr/sbin/ && \
		ln -sf comgt gcom
	$(STRIP) -s $(INSTALLDIR)/comgt/usr/sbin/comgt
	@mkdir -p $(TARGETDIR)/rom/etc/gcom
	@cp -f comgt/gcom/* $(TARGETDIR)/rom/etc/gcom/

comgt-clean:
	-@$(MAKE) -C comgt clean
	$(call unpatch_files,comgt)

sd-idle:
	@$(SEP)
	$(MAKE) -C sd-idle CFLAGS="-Os -Wall $(EXTRACFLAGS)"

sd-idle-install:
	install -d $(INSTALLDIR)/sd-idle/usr/bin
	install -D -m 0755 sd-idle/sd-idle $(INSTALLDIR)/sd-idle/usr/bin/sd-idle
	$(STRIP) -s $(INSTALLDIR)/sd-idle/usr/bin/sd-idle

sd-idle-clean:
	-@$(MAKE) -C sd-idle clean

iperf/stamp-h1:
	cd iperf && autoreconf -fsi && \
		CFLAGS="-Os -Wall $(EXTRACFLAGS)" \
		ac_cv_func_clock_gettime="no" \
		ac_cv_func_daemon="no" \
		$(CONFIGURE) --prefix=/usr --disable-profiling --without-openssl
	@touch $@

iperf: iperf/stamp-h1
	@$(SEP)
	$(call patch_files,iperf)
	$(MAKE) -C iperf

iperf-install:
	install -D iperf/src/.libs/iperf3 $(INSTALLDIR)/iperf/usr/sbin/iperf
	install -d $(INSTALLDIR)/iperf/usr/lib/
	install iperf/src/.libs/libiperf.so.0.0.0 $(INSTALLDIR)/iperf/usr/lib/libiperf.so.0.0.0
	$(STRIP) $(INSTALLDIR)/iperf/usr/lib/libiperf.so.0.0.0
	$(STRIP) $(INSTALLDIR)/iperf/usr/sbin/iperf
	cd $(INSTALLDIR)/iperf/usr/lib/ && \
		ln -sf libiperf.so.0.0.0 libiperf.so.0 && \
		ln -sf libiperf.so.0.0.0 libiperf.so

iperf-clean:
	-@$(MAKE) -C iperf clean
	-@rm -rf iperf/Makefile iperf/stamp-h1
	$(call unpatch_files,iperf)

#
# Generic rules
#

%:
	@[ ! -d $* ] || ( $(SEP); $(MAKE) -C $* )


%-clean:
	@-[ ! -d $* ] || $(MAKE) -C $* clean

%-distclean:
	@-[ ! -d $* ] || $(MAKE) -C $* distclean

%-install:
	@[ ! -d $* ] || $(MAKE) -C $* install INSTALLDIR=$(INSTALLDIR)/$*

%-build:
	$(MAKE) $*-clean $*

$(obj-y) $(obj-n) $(obj-clean) $(obj-install): dummy

.PHONY: all clean distclean mrproper install package
.PHONY: conf mconf oldconf kconf kmconf config menuconfig oldconfig
.PHONY: dummy libnet libpcap
