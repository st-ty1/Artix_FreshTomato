/*

	Copyright 2003, CyberTAN  Inc.  All Rights Reserved

	This is UNPUBLISHED PROPRIETARY SOURCE CODE of CyberTAN Inc.
	the contents of this file may not be disclosed to third parties,
	copied or duplicated in any form without the prior written
	permission of CyberTAN Inc.

	This software should be used as a reference only, and it not
	intended for production use!

	THIS SOFTWARE IS OFFERED "AS IS", AND CYBERTAN GRANTS NO WARRANTIES OF ANY
	KIND, EXPRESS OR IMPLIED, BY STATUTE, COMMUNICATION OR OTHERWISE.  CYBERTAN
	SPECIFICALLY DISCLAIMS ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS
	FOR A SPECIFIC PURPOSE OR NONINFRINGEMENT CONCERNING THIS SOFTWARE

*/
/*

	Copyright 2005, Broadcom Corporation
	All Rights Reserved.

	THIS SOFTWARE IS OFFERED "AS IS", AND BROADCOM GRANTS NO WARRANTIES OF ANY
	KIND, EXPRESS OR IMPLIED, BY STATUTE, COMMUNICATION OR OTHERWISE. BROADCOM
	SPECIFICALLY DISCLAIMS ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS
	FOR A SPECIFIC PURPOSE OR NONINFRINGEMENT CONCERNING THIS SOFTWARE.

*/
/*

	Modified for Tomato Firmware
	Portions, Copyright (C) 2006-2009 Jonathan Zarate

*/


#include "rc.h"

#include <arpa/inet.h>
#include <time.h>
#include <sys/time.h>
#include <errno.h>
#include <string.h>
#include <wlutils.h>

#include <sys/mount.h>
#include <mntent.h>
#include <dirent.h>
#include <linux/version.h>

#define ADBLOCK_EXE		"/usr/sbin/adblock"
#define DNSMASQ_CONF		"/etc/dnsmasq.conf"
#define RESOLV_CONF		"/etc/resolv.conf"
#define IGMP_CONF		"/etc/igmp.conf"
#define UPNP_DIR		"/etc/upnp"
#ifdef TCONFIG_ZEBRA
#define ZEBRA_CONF		"/etc/zebra.conf"
#define RIPD_CONF		"/etc/ripd.conf"
#endif
#ifdef TCONFIG_MEDIA_SERVER
#define MEDIA_SERVER_APP	"minidlna"
#endif
#ifdef TCONFIG_MDNS
#define AVAHI_CONFIG_PATH	"/etc/avahi"
#define AVAHI_SERVICES_PATH	"/etc/avahi/services"
#define AVAHI_CONFIG_FN		"avahi-daemon.conf"
#endif /* TCONFIG_MDNS */

/* needed by logmsg() */
#define LOGMSG_DISABLE		DISABLE_SYSLOG_OSM
#define LOGMSG_NVDEBUG		"services_debug"

#define ONEMONTH_LIFETIME	(30 * 24 * 60 * 60)
#define IPV6_MIN_LIFETIME	120

/* The g_upgrade global variable is used to skip several unnecessary delay
 * and redundant steps during upgrade procedure.
 */
int g_upgrade = 0;

/* Pop an alarm to recheck pids in 500 msec */
static const struct itimerval pop_tv = { {0, 0}, {0, 500 * 1000} };
/* Pop an alarm to reap zombies */
static const struct itimerval zombie_tv = { {0, 0}, {307, 0} };
static const char dmhosts[] = "/etc/hosts.dnsmasq";
static const char dmresolv[] = "/etc/resolv.dnsmasq";
#ifdef TCONFIG_FTP
static const char vsftpd_conf[] =  "/etc/vsftpd.conf";
static const char vsftpd_passwd[] = "/etc/vsftpd.passwd";
static char vsftpd_users[] = "/etc/vsftpd.users";
#endif
static pid_t pid_dnsmasq = -1;
static pid_t pid_crond = -1;
static pid_t pid_hotplug2 = -1;
static pid_t pid_igmp = -1;
#ifdef TCONFIG_FANCTRL
static pid_t pid_phy_tempsense = -1;
#endif


static int is_wet(int idx, int unit, int subunit, void *param)
{
	return nvram_match(wl_nvname("mode", unit, subunit), "wet");
}

#ifdef TCONFIG_BCMWL6
static int is_psta(int idx, int unit, int subunit, void *param)
{
	return nvram_match(wl_nvname("mode", unit, subunit), "psta");
}
#endif /* TCONFIG_BCMWL6 */

void start_dnsmasq()
{
	FILE *f, *hf;
	const char *nv;
	const char *router_ip;
	char sdhcp_lease[32];
	char buf[512], lan[24], tmp[128];
	char *e, *p;
	struct in_addr in4;
	char *mac, *ip, *name, *bind;
	char *nve, *nvp;
	unsigned char ea[ETHER_ADDR_LEN];
	int n;
	int dhcp_start, dhcp_count, dhcp_lease;
	int do_dhcpd, do_dns, do_dhcpd_hosts = 0;
#ifdef TCONFIG_IPV6
	int ipv6_lease; /* DHCP IPv6 lease time */
	int service;
#endif
	int wan_unit, mwan_num;
	const dns_list_t *dns;
	char br;
	char wan_prefix[] = "wanXX";
	char lanN_proto[] = "lanXX_proto";
	char lanN_ifname[] = "lanXX_ifname";
	char lanN_ipaddr[] = "lanXX_ipaddr";
	char lanN_netmask[] = "lanXX_netmask";
	char dhcpdN_startip[] = "dhcpdXX_startip";
	char dhcpdN_endip[] = "dhcpdXX_endip";
	char dhcpN_start[] = "dhcpXX_start";
	char dhcpN_num[] = "dhcpXX_num";
	char dhcpN_lease[] = "dhcpXX_lease";

	if (getpid() != 1) {
		start_service("dnsmasq");
		return;
	}

	stop_dnsmasq();

	/* check wireless ethernet bridge (wet) after stop_dnsmasq() */
	if (foreach_wif(1, NULL, is_wet)) {
		logmsg(LOG_WARNING, "Starting dnsmasq is skipped due to the WEB mode enabled");
		return;
	}

#ifdef TCONFIG_BCMWL6
	/* check media bridge (psta) after stop_dnsmasq() */
	if (foreach_wif(1, NULL, is_psta)) {
		logmsg(LOG_WARNING, "Starting dnsmasq is skipped due to the Media Bridge mode enabled");
		return;
	}
#endif /* TCONFIG_BCMWL6 */

	if ((f = fopen(DNSMASQ_CONF, "w")) == NULL) {
		perror(DNSMASQ_CONF);
		return;
	}

	if (((nv = nvram_get("wan_domain")) != NULL) || ((nv = nvram_get("wan_get_domain")) != NULL)) {
		if (*nv)
			fprintf(f, "domain=%s\n", nv);
	}

	if ((nv = nvram_safe_get("dns_minport")) && (*nv))
		n = atoi(nv);
	else
		n = 4096;

	fprintf(f, "pid-file=/var/run/dnsmasq.pid\n"
	           "resolv-file=%s\n"				/* the real stuff is here */
	           "expand-hosts\n"				/* expand hostnames in hosts file */
	           "min-port=%u\n"				/* min port used for random src port */
	           "no-negcache\n"				/* disable negative caching */
	           "dhcp-name-match=set:wpad-ignore,wpad\n"	/* protect against VU#598349 */
	           "dhcp-ignore-names=tag:wpad-ignore\n",
	           dmresolv, n);

	/* DNS rebinding protection, will discard upstream RFC1918 responses */
	if (nvram_get_int("dns_norebind"))
		fprintf(f, "stop-dns-rebind\n"
		           "rebind-localhost-ok\n");

	/* instruct clients like Firefox to not auto-enable DoH */
	if (nvram_get_int("dns_priv_override")) {
		fprintf(f, "address=/use-application-dns.net/\n"
		           "address=/_dns.resolver.arpa/\n");
	}

	/* forward local domain queries to upstream DNS */
	if (nvram_get_int("dns_fwd_local") != 1)
		fprintf(f, "bogus-priv\n"			/* don't forward private reverse lookups upstream */
		           "domain-needed\n");			/* don't forward plain name queries upstream */

#ifdef TCONFIG_DNSCRYPT
	if (nvram_get_int("dnscrypt_proxy"))
		fprintf(f, "server=127.0.0.1#%s\n", nvram_safe_get("dnscrypt_port"));
#endif
#ifdef TCONFIG_STUBBY
	if (nvram_get_int("stubby_proxy"))
		fprintf(f, "server=127.0.0.1#%s\n", nvram_safe_get("stubby_port"));
#endif
#ifdef TCONFIG_TOR
	if ((nvram_get_int("tor_enable")) && (nvram_get_int("dnsmasq_onion_support"))) {
		char *t_ip = nvram_safe_get("lan_ipaddr");

		if (nvram_match("tor_iface", "br1"))
			t_ip = nvram_safe_get("lan1_ipaddr");
		if (nvram_match("tor_iface", "br2"))
			t_ip = nvram_safe_get("lan2_ipaddr");
		if (nvram_match("tor_iface", "br3"))
			t_ip = nvram_safe_get("lan3_ipaddr");

		fprintf(f, "server=/onion/%s#%s\n", t_ip, nvram_safe_get("tor_dnsport"));
	}
#endif

	mwan_num = nvram_get_int("mwan_num");
	if ((mwan_num < 1) || (mwan_num > MWAN_MAX))
		mwan_num = 1;

	for (wan_unit = 1; wan_unit <= mwan_num; ++wan_unit) {
		get_wan_prefix(wan_unit, wan_prefix);

		/* allow RFC1918 responses for server domain (fix connect PPTP/L2TP WANs) */
		switch (get_wanx_proto(wan_prefix)) {
			case WP_PPTP:
				nv = nvram_safe_get(strcat_r(wan_prefix, "_pptp_server_ip", tmp));
				break;
			case WP_L2TP:
				nv = nvram_safe_get(strcat_r(wan_prefix, "_l2tp_server_ip", tmp));
				break;
			default:
				nv = NULL;
				break;
		}
		if (nv && *nv)
			fprintf(f, "rebind-domain-ok=%s\n", nv);

		dns = get_dns(wan_prefix); /* this always points to a static buffer */

		/* check dns entries only for active connections */
		if ((check_wanup(wan_prefix) == 0) && (dns->count == 0))
			continue;

		/* dns list with non-standart ports */
		for (n = 0 ; n < dns->count; ++n) {
			if (dns->dns[n].port != 53)
				fprintf(f, "server=%s#%u\n", inet_ntoa(dns->dns[n].addr), dns->dns[n].port);
		}
	}

	if (nvram_get_int("dhcpd_static_only"))
		fprintf(f, "dhcp-ignore=tag:!known\n");

	if ((n = nvram_get_int("dnsmasq_q"))) { /* process quiet flags */
		if (n & 1)
			fprintf(f, "quiet-dhcp\n");
#ifdef TCONFIG_IPV6
		if (n & 2)
			fprintf(f, "quiet-dhcp6\n");
		if (n & 4)
			fprintf(f, "quiet-ra\n");
#endif
	}

	/* dhcp */
	do_dns = nvram_get_int("dhcpd_dmdns");
	for (br = 0; br < BRIDGE_COUNT; br++) {
		char bridge[2] = "0";
		if (br != 0)
			bridge[0] += br;
		else
			strcpy(bridge, "");

		sprintf(lanN_proto, "lan%s_proto", bridge);
		sprintf(lanN_ifname, "lan%s_ifname", bridge);
		sprintf(lanN_ipaddr, "lan%s_ipaddr", bridge);
		do_dhcpd = nvram_match(lanN_proto, "dhcp");
		if (do_dhcpd) {
			do_dhcpd_hosts++;

			router_ip = nvram_safe_get(lanN_ipaddr);
			strlcpy(lan, router_ip, sizeof(lan));
			if ((p = strrchr(lan, '.')) != NULL)
				*(p + 1) = 0;

			fprintf(f, "interface=%s\n", nvram_safe_get(lanN_ifname));

			sprintf(dhcpN_lease, "dhcp%s_lease", bridge);
			dhcp_lease = nvram_get_int(dhcpN_lease);

			if (dhcp_lease <= 0)
				dhcp_lease = 1440;

			if (((e = nvram_get("dhcpd_slt")) != NULL) && (*e))
				n = atoi(e);
			else
				n = 0;

			memset(sdhcp_lease, 0, 32);
			if (n < 0)
				strcpy(sdhcp_lease, "infinite");
			else
				sprintf(sdhcp_lease, "%dm", ((n > 0) ? n : dhcp_lease));

			if (!do_dns) { /* if not using dnsmasq for dns */

				for (wan_unit = 1; wan_unit <= mwan_num; ++wan_unit) {
					get_wan_prefix(wan_unit, wan_prefix);
					/* skip inactive WAN connections
					 * TBD: need to check if there is no WANs active do we need skip here also?!?
					 */
					if (check_wanup(wan_prefix) == 0)
						continue;

					dns = get_dns(wan_prefix); /* static buffer */

					if ((dns->count == 0) && (nvram_get_int("dhcpd_llndns"))) {
						/* no DNS might be temporary. use a low lease time to force clients to update. */
						dhcp_lease = 2;
						strcpy(sdhcp_lease, "2m");
						do_dns = 1;
					}
					else {
						/* pass the dns directly */
						buf[0] = 0;
						for (n = 0 ; n < dns->count; ++n) {
							if (dns->dns[n].port == 53) /* check: option 6 doesn't seem to support other ports */
								sprintf(buf + strlen(buf), ",%s", inet_ntoa(dns->dns[n].addr));
						}
						fprintf(f, "dhcp-option=tag:%s,6%s\n", nvram_safe_get(lanN_ifname), buf); /* dns-server */
					}
				}
			}

			sprintf(dhcpdN_startip, "dhcpd%s_startip", bridge);
			sprintf(dhcpdN_endip, "dhcpd%s_endip", bridge);
			sprintf(lanN_netmask, "lan%s_netmask", bridge);

			if ((p = nvram_safe_get(dhcpdN_startip)) && (*p) && (e = nvram_safe_get(dhcpdN_endip)) && (*e))
				fprintf(f, "dhcp-range=tag:%s,%s,%s,%s,%dm\n", nvram_safe_get(lanN_ifname), p, e, nvram_safe_get(lanN_netmask), dhcp_lease);
			else {
				/* for compatibility */
				sprintf(dhcpN_start, "dhcp%s_start", bridge);
				sprintf(dhcpN_num, "dhcp%s_num", bridge);
				sprintf(lanN_netmask, "lan%s_netmask", bridge);
				dhcp_start = nvram_get_int(dhcpN_start);
				dhcp_count = nvram_get_int(dhcpN_num);
				fprintf(f, "dhcp-range=tag:%s,%s%d,%s%d,%s,%dm\n", nvram_safe_get(lanN_ifname), lan, dhcp_start, lan, (dhcp_start + dhcp_count - 1), nvram_safe_get(lanN_netmask), dhcp_lease);
			}

			nv = nvram_safe_get(lanN_ipaddr);
			if ((nvram_get_int("dhcpd_gwmode") == 1) && (get_wan_proto() == WP_DISABLED)) {
				p = nvram_safe_get("lan_gateway");
				if ((*p) && (strcmp(p, "0.0.0.0") != 0))
					nv = p;
			}
			fprintf(f, "dhcp-option=tag:%s,3,%s\n", nvram_safe_get(lanN_ifname), nv); /* gateway */

			nv = nvram_safe_get("wan_wins");
			if ((*nv) && (strcmp(nv, "0.0.0.0") != 0))
				fprintf(f, "dhcp-option=tag:%s,44,%s\n", nvram_safe_get(lanN_ifname), nv); /* netbios-ns */
#ifdef TCONFIG_SAMBASRV
			else if (nvram_get_int("smbd_enable") && nvram_invmatch("lan_hostname", "") && nvram_get_int("smbd_wins")) {
				if ((!*nv) || (strcmp(nv, "0.0.0.0") == 0))
					/* Samba will serve as a WINS server */
					fprintf(f, "dhcp-option=tag:%s,44,%s\n", nvram_safe_get(lanN_ifname), nvram_safe_get(lanN_ipaddr)); /* netbios-ns */
			}
#endif
		}
		else {
			if (strcmp(nvram_safe_get(lanN_ifname), "") != 0)
				fprintf(f, "interface=%s\n", nvram_safe_get(lanN_ifname));
		}
	}

	/* write static lease entries & create hosts file */
	router_ip = nvram_safe_get("lan_ipaddr"); /* use the main one, not the last one from the loop! */

	if ((hf = fopen(dmhosts, "w")) != NULL) {
		if ((nv = nvram_safe_get("wan_hostname")) && (*nv))
			fprintf(hf, "%s %s\n", router_ip, nv);
#ifdef TCONFIG_SAMBASRV
		else if ((nv = nvram_safe_get("lan_hostname")) && (*nv)) /* FIXME: it has to be implemented (lan_hostname is always empty) */
			fprintf(hf, "%s %s\n", router_ip, nv);
#endif
		p = (char *)get_wanip("wan");
		if ((!*p) || strcmp(p, "0.0.0.0") == 0)
			p = "127.0.0.1";
		fprintf(hf, "%s wan1-ip\n", p);

		p = (char *)get_wanip("wan2");
		if ((!*p) || strcmp(p, "0.0.0.0") == 0)
			p = "127.0.0.1";
		fprintf(hf, "%s wan2-ip\n", p);
#ifdef TCONFIG_MULTIWAN
		p = (char *)get_wanip("wan3");
		if ((!*p) || strcmp(p, "0.0.0.0") == 0)
			p = "127.0.0.1";
		fprintf(hf, "%s wan3-ip\n", p);

		p = (char *)get_wanip("wan4");
		if ((!*p) || strcmp(p, "0.0.0.0") == 0)
			p = "127.0.0.1";
		fprintf(hf, "%s wan4-ip\n", p);
#endif
	}

	/* add dhcp reservations
	 *
	 * FORMAT (static ARP binding after hostname):
	 * 00:aa:bb:cc:dd:ee<123.123.123.123<xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xyz<a>
	 * 00:aa:bb:cc:dd:ee,00:aa:bb:cc:dd:ee<123.123.123.123<xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xyz<a>
	 */
	nve = nvp = strdup(nvram_safe_get("dhcpd_static"));
	while (nvp && (p = strsep(&nvp, ">")) != NULL) {
		name = NULL;

		if ((vstrsep(p, "<", &mac, &ip, &name, &bind)) < 4)
			continue;

		if (*ip != '\0' && (inet_pton(AF_INET, ip, &in4) <= 0 || in4.s_addr == INADDR_ANY || in4.s_addr == INADDR_LOOPBACK || in4.s_addr == INADDR_BROADCAST)) /* invalid IP (if any) */
			continue;

		if ((hf) && (*ip) && (*name))
			fprintf(hf, "%s %s\n", ip, name);

		if (do_dhcpd_hosts > 0 && ether_atoe(mac, ea)) {
			if (*ip)
				fprintf(f, "dhcp-host=%s,%s", mac, ip);
			else if (*name)
				fprintf(f, "dhcp-host=%s,%s", mac, name);

			if (((*ip) || (*name)) && (nvram_get_int("dhcpd_slt") != 0))
				fprintf(f, ",%s", sdhcp_lease);

			fprintf(f, "\n");
		}
	}
	if (nve)
		free(nve);

	if (hf) {
		/* add directory with additional hosts files */
		fprintf(f, "addn-hosts=%s\n", dmhosts);
		fclose(hf);
	}

	n = nvram_get_int("dhcpd_lmax");
	fprintf(f, "dhcp-lease-max=%d\n", ((n > 0) ? n : 255));

	if (nvram_get_int("dhcpd_auth") >= 0)
		fprintf(f, "dhcp-option=252,\"\\n\"\n"
		           "dhcp-authoritative\n");

	/* NTP server */
	if (nvram_get_int("ntpd_enable"))
		fprintf(f, "dhcp-option-force=42,%s\n", "0.0.0.0");

	if (nvram_get_int("dnsmasq_debug"))
		fprintf(f, "log-queries\n");

	/* generate a name for DHCP clients which do not otherwise have one */
	if (nvram_get_int("dnsmasq_gen_names"))
		fprintf(f, "dhcp-generate-names\n");

	if ((nvram_get_int("adblock_enable")) && (f_exists("/etc/dnsmasq.adblock")))
		fprintf(f, "conf-file=/etc/dnsmasq.adblock\n");

#if defined(TCONFIG_DNSSEC) || defined(TCONFIG_STUBBY)
	if (nvram_get_int("dnssec_enable")) {
#ifdef TCONFIG_STUBBY
		if ((!nvram_get_int("stubby_proxy")) || (nvram_match("dnssec_method", "0"))) {
#endif
#ifdef TCONFIG_DNSSEC
			fprintf(f, "conf-file=/etc/trust-anchors.conf\n"
			           "dnssec\n");

			/* if NTP isn't set yet, wait until rc's ntp signals us to start validating time */
			if (!nvram_get_int("ntp_ready"))
				fprintf(f, "dnssec-no-timecheck\n");
#endif
#ifdef TCONFIG_STUBBY
		}
		else /* use stubby dnssec or server only */
			fprintf(f, "proxy-dnssec\n");
#endif
	}
#endif /* TCONFIG_DNSSEC || TCONFIG_STUBBY */

#ifdef TCONFIG_DNSCRYPT
	if (nvram_get_int("dnscrypt_proxy")) {
		if (nvram_match("dnscrypt_priority", "1"))
			fprintf(f, "strict-order\n");

		if (nvram_match("dnscrypt_priority", "2"))
			fprintf(f, "no-resolv\n");
	}
#endif

#ifdef TCONFIG_STUBBY
	if (nvram_get_int("stubby_proxy")) {
		if (nvram_match("stubby_priority", "1"))
			fprintf(f, "strict-order\n");

		if (nvram_match("stubby_priority", "2"))
			fprintf(f, "no-resolv\n");
	}
#endif

#ifdef TCONFIG_OPENVPN
	write_ovpn_dnsmasq_config(f);
#endif

#ifdef TCONFIG_PPTPD
	write_pptpd_dnsmasq_config(f);
#endif

#ifdef TCONFIG_IPV6
	if (ipv6_enabled()) {

		service = get_ipv6_service();
		memset(tmp, 0, sizeof(tmp)); /* reset */

		/* get mtu for IPv6 --> only for "wan" (no multiwan support) */
		switch (service) {
		case IPV6_ANYCAST_6TO4: /* use tun mtu (visible at basic-ipv6.asp) */
		case IPV6_6IN4:
			sprintf(tmp, "%d", (nvram_get_int("ipv6_tun_mtu") > 0) ? nvram_get_int("ipv6_tun_mtu") : 1280);
			break;
		case IPV6_6RD:		/* use wan mtu and calculate it */
		case IPV6_6RD_DHCP:
			sprintf(tmp, "%d", (nvram_get_int("wan_mtu") > 0) ? (nvram_get_int("wan_mtu") - 20) : 1280);
			break;
		default:
			sprintf(tmp, "%d", (nvram_get_int("wan_mtu") > 0) ? nvram_get_int("wan_mtu") : 1280);
			break;
		}

		/* enable-ra should be enabled in both cases (SLAAC and/or DHCPv6) */
		if ((nvram_get_int("ipv6_radvd")) || (nvram_get_int("ipv6_dhcpd"))) {
			fprintf(f, "enable-ra\n");
			if (nvram_get_int("ipv6_fast_ra"))
				fprintf(f, "ra-param=br*, mtu:%s, 15, 600\n", tmp); /* interface = br*, mtu = XYZ, ra-interval = 15 sec, router-lifetime = 600 sec (10 min) */
			else /* default case */
				fprintf(f, "ra-param=br*, mtu:%s, 60, 1200\n", tmp); /* interface = br*, mtu = XYZ, ra-interval = 60 sec, router-lifetime = 1200 sec (20 min) */
		}

		/* Check for DHCPv6 PD (and use IPv6 preferred lifetime in that case) */
		if (service == IPV6_NATIVE_DHCP) {
			ipv6_lease = nvram_get_int("ipv6_pd_pltime"); /* get IPv6 preferred lifetime (seconds) */
			if ((ipv6_lease < IPV6_MIN_LIFETIME) || (ipv6_lease > ONEMONTH_LIFETIME)) /* check lease time and limit the range (120 sec up to one month) */
				ipv6_lease = IPV6_MIN_LIFETIME;

			/* only SLAAC and NO DHCPv6 */
			if ((nvram_get_int("ipv6_radvd")) && (!nvram_get_int("ipv6_dhcpd")))
				fprintf(f, "dhcp-range=::, constructor:br*, ra-names, ra-stateless, 64, %ds\n", ipv6_lease);

			/* only DHCPv6 and NO SLAAC */
			if ((nvram_get_int("ipv6_dhcpd")) && (!nvram_get_int("ipv6_radvd")))
				fprintf(f, "dhcp-range=::2, ::FFFF:FFFF, constructor:br*, 64, %ds\n", ipv6_lease);

			/* SLAAC and DHCPv6 (2 IPv6 IPs) */
			if ((nvram_get_int("ipv6_radvd")) && (nvram_get_int("ipv6_dhcpd")))
				fprintf(f, "dhcp-range=::2, ::FFFF:FFFF, constructor:br*, ra-names, 64, %ds\n", ipv6_lease);
		}
		else {
			ipv6_lease = nvram_get_int("ipv6_lease_time"); /* get DHCP IPv6 lease time via GUI */
			if ((ipv6_lease < 1) || (ipv6_lease > 720)) /* check lease time and limit the range (1...720 hours, 30 days should be enough) */
				ipv6_lease = 12;

			/* only SLAAC and NO DHCPv6 */
			if ((nvram_get_int("ipv6_radvd")) && (!nvram_get_int("ipv6_dhcpd")))
				fprintf(f, "dhcp-range=::, constructor:br*, ra-names, ra-stateless, 64, %dh\n", ipv6_lease);

			/* only DHCPv6 and NO SLAAC */
			if ((nvram_get_int("ipv6_dhcpd")) && (!nvram_get_int("ipv6_radvd")))
				fprintf(f, "dhcp-range=::2, ::FFFF:FFFF, constructor:br*, 64, %dh\n", ipv6_lease);

			/* SLAAC and DHCPv6 (2 IPv6 IPs) */
			if ((nvram_get_int("ipv6_radvd")) && (nvram_get_int("ipv6_dhcpd")))
				fprintf(f, "dhcp-range=::2, ::FFFF:FFFF, constructor:br*, ra-names, 64, %dh\n", ipv6_lease);
		}

		/* DNS server */
		fprintf(f, "dhcp-option=option6:dns-server,%s\n", "[::]"); /* use global address */

		/* SNTP & NTP server */
		if (nvram_get_int("ntpd_enable")) {
			fprintf(f, "dhcp-option=option6:31,%s\n", "[::]");
			fprintf(f, "dhcp-option=option6:56,%s\n", "[::]");
		}
	}
#endif /* TCONFIG_IPV6 */

	fprintf(f, "edns-packet-max=1280\n");
	fprintf(f, "%s\n", nvram_safe_get("dnsmasq_custom"));

	fappend(f, "/etc/dnsmasq.custom");
	fappend(f, "/etc/dnsmasq.ipset");

	fclose(f);

	if (do_dns) {
		unlink(RESOLV_CONF);
		symlink("/rom/etc/resolv.conf", RESOLV_CONF); /* nameserver 127.0.0.1 */
	}

#ifdef TCONFIG_DNSCRYPT
	start_dnscrypt();
#endif
#ifdef TCONFIG_STUBBY
	start_stubby();
#endif

	/* default to some values we like, but allow the user to override them */
	eval("dnsmasq", "-c", "4096", "--log-async");

	if (!nvram_contains_word("debug_norestart", "dnsmasq"))
		pid_dnsmasq = -2;
}

void stop_dnsmasq(void)
{
	if (getpid() != 1) {
		stop_service("dnsmasq");
		return;
	}

	pid_dnsmasq = -1;

	unlink(RESOLV_CONF);
	symlink(dmresolv, RESOLV_CONF);

	killall_tk_period_wait("dnsmasq", 50);
#ifdef TCONFIG_DNSCRYPT
	stop_dnscrypt();
#endif
#ifdef TCONFIG_STUBBY
	stop_stubby();
#endif
}

void reload_dnsmasq(void)
{
	/* notify dnsmasq */
	killall("dnsmasq", SIGINT);
}

void clear_resolv(void)
{
	logmsg(LOG_DEBUG, "*** %s: clear all DNS entries", __FUNCTION__);
	f_write(dmresolv, NULL, 0, 0, 0); /* blank */
}

#ifdef TCONFIG_DNSCRYPT
void start_dnscrypt(void)
{
	const static char *dnscrypt_resolv = "/etc/dnscrypt-resolvers.csv";
	const static char *dnscrypt_resolv_alt = "/etc/dnscrypt-resolvers-alt.csv";
	char dnscrypt_local[30];
	char *dnscrypt_ekeys;

	if (!nvram_get_int("dnscrypt_proxy"))
		return;

	if (getpid() != 1) {
		start_service("dnscrypt");
		return;
	}

	stop_dnscrypt();

	memset(dnscrypt_local, 0, 30);
	sprintf(dnscrypt_local, "127.0.0.1:%s", nvram_safe_get("dnscrypt_port"));
	dnscrypt_ekeys = nvram_get_int("dnscrypt_ephemeral_keys") ? "-E" : "";

	if (nvram_get_int("dnscrypt_manual"))
		eval("dnscrypt-proxy", "-d", dnscrypt_ekeys,
		     "-a", dnscrypt_local,
		     "-m", nvram_safe_get("dnscrypt_log"),
		     "-N", nvram_safe_get("dnscrypt_provider_name"),
		     "-k", nvram_safe_get("dnscrypt_provider_key"),
		     "-r", nvram_safe_get("dnscrypt_resolver_address"));
	else
		eval("dnscrypt-proxy", "-d", dnscrypt_ekeys,
		     "-a", dnscrypt_local,
		     "-m", nvram_safe_get("dnscrypt_log"),
		     "-R", nvram_safe_get("dnscrypt_resolver"),
		     "-L", f_exists(dnscrypt_resolv_alt) ? (char *) dnscrypt_resolv_alt : (char *) dnscrypt_resolv);
#ifdef TCONFIG_IPV6
	memset(dnscrypt_local, 0, 30);
	sprintf(dnscrypt_local, "::1:%s", nvram_safe_get("dnscrypt_port"));

	if (get_ipv6_service() != *("NULL")) { /* when ipv6 enabled */
		if (nvram_get_int("dnscrypt_manual"))
			eval("dnscrypt-proxy", "-d", dnscrypt_ekeys,
			     "-a", dnscrypt_local,
			     "-m", nvram_safe_get("dnscrypt_log"),
			     "-N", nvram_safe_get("dnscrypt_provider_name"),
			     "-k", nvram_safe_get("dnscrypt_provider_key"),
			     "-r", nvram_safe_get("dnscrypt_resolver_address"));
		else
			eval("dnscrypt-proxy", "-d", dnscrypt_ekeys,
			     "-a", dnscrypt_local,
			     "-m", nvram_safe_get("dnscrypt_log"),
			     "-R", nvram_safe_get("dnscrypt_resolver"),
			     "-L", f_exists(dnscrypt_resolv_alt) ? (char *) dnscrypt_resolv_alt : (char *) dnscrypt_resolv);
	}
#endif
}

void stop_dnscrypt(void)
{
	if (getpid() != 1) {
		stop_service("dnscrypt");
		return;
	}

	killall_tk_period_wait("dnscrypt-proxy", 50);
}
#endif /* TCONFIG_DNSCRYPT */

#ifdef TCONFIG_STUBBY
void start_stubby(void)
{
	const static char *stubby_config = "/etc/stubby/stubby.yml";
	FILE *fp;
	char *nv, *nvp, *b;
	char *server, *tlsport, *hostname, *spkipin, *digest;
	int ntp_ready, port, dnssec, ret;
	union {
		struct in_addr addr4;
#ifdef TCONFIG_IPV6
		struct in6_addr addr6;
#endif
	} addr;

	if (!nvram_get_int("stubby_proxy"))
		return;

	if (getpid() != 1) {
		start_service("stubby");
		return;
	}

	stop_stubby();

	mkdir_if_none("/etc/stubby");

	/* alternative (user) configuration file */
	if (f_exists("/etc/stubby/stubby_alt.yml")) {
		eval("stubby", "-g", "-v", nvram_safe_get("stubby_log"), "-C", "/etc/stubby/stubby_alt.yml");
		return;
	}

	if ((fp = fopen(stubby_config, "w")) == NULL) {
		perror(stubby_config);
		return;
	}

	ntp_ready = nvram_get_int("ntp_ready");
	dnssec = (nvram_get_int("dnssec_enable") && nvram_match("dnssec_method", "1"));

	/* basic & privacy settings */
	fprintf(fp, "appdata_dir: \"/var/lib/misc\"\n"
	            "resolution_type: GETDNS_RESOLUTION_STUB\n"
	            "dns_transport_list:\n"
	            "%s"
	            "tls_authentication: %s\n"
	            "tls_query_padding_blocksize: 128\n"
	            "edns_client_subnet_private: 1\n"
	            "%s"
	/* connection settings */
	            "idle_timeout: 5000\n"
	            "tls_connection_retries: 5\n"
	            "tls_backoff_time: 900\n"
	            "timeout: 2000\n"
	            "round_robin_upstreams: 1\n"
	            "tls_min_version: %s\n"
	/* listen address */
	            "listen_addresses:\n"
	            "  - 127.0.0.1@%s\n",
	            ntp_ready ? "  - GETDNS_TRANSPORT_TLS\n" : "  - GETDNS_TRANSPORT_UDP\n  - GETDNS_TRANSPORT_TCP\n",
	            ntp_ready ? "GETDNS_AUTHENTICATION_REQUIRED" : "GETDNS_AUTHENTICATION_NONE",
	            (ntp_ready && dnssec) ? "dnssec: GETDNS_EXTENSION_TRUE\n" : "",
	            nvram_get_int("stubby_force_tls13") ? "GETDNS_TLS1_3" : "GETDNS_TLS1_2",
	            nvram_safe_get("stubby_port"));
#ifdef TCONFIG_IPV6
	if (get_ipv6_service() != *("NULL")) /* when ipv6 enabled */
		fprintf(fp, "  - 0::1@%s\n", nvram_safe_get("stubby_port"));
#endif
	/* upstreams */
	fprintf(fp, "upstream_recursive_servers:\n");

	nv = nvp = strdup(nvram_safe_get("stubby_resolvers"));
	while (nvp && (b = strsep(&nvp, "<")) != NULL) {
		server = tlsport = hostname = spkipin = NULL;

		/* <server>port>hostname>[digest:]spkipin */
		if ((vstrsep(b, ">", &server, &tlsport, &hostname, &spkipin)) < 4)
			continue;

		/* check server, can be IPv4/IPv6 address */
		if (*server == '\0')
			continue;
		else if (inet_pton(AF_INET, server, &addr) <= 0
#ifdef TCONFIG_IPV6
		         && ((inet_pton(AF_INET6, server, &addr) <= 0) || (!ipv6_enabled()))
#endif
		)
			continue;

		/* check port, if specified */
		port = (*tlsport ? atoi(tlsport) : 0);
		if ((port < 0) || (port > 65535))
			continue;

		/* add server */
		fprintf(fp, "  - address_data: %s\n", server);
		if (port)
			fprintf(fp, "    tls_port: %d\n", port);
		if (*hostname)
			fprintf(fp, "    tls_auth_name: \"%s\"\n", hostname);
		if (*spkipin) {
			digest = strchr(spkipin, ':') ? strsep(&spkipin, ":") : "sha256";
			fprintf(fp, "    tls_pubkey_pinset:\n"
			            "      - digest: \"%s\"\n"
			            "        value: %s\n", digest, spkipin);
		}
	}
	if (nv)
		free(nv);

	fclose(fp);

	if (dnssec) {
		if (ntp_ready)
			logmsg(LOG_INFO, "stubby: DNSSEC enabled");
		else
			logmsg(LOG_INFO, "stubby: DNSSEC pending ntp sync");
	}

	ret = eval("stubby", "-g", "-v", nvram_safe_get("stubby_log"), "-C", (char *)stubby_config);

	if (ret)
		logmsg(LOG_ERR, "starting stubby failed ...");
	else
		logmsg(LOG_INFO, "stubby is started");
}

void stop_stubby(void)
{
	if (getpid() != 1) {
		stop_service("stubby");
		return;
	}

	killall_tk_period_wait("stubby", 50);
	unlink("/var/run/stubby.pid");
}
#endif /* TCONFIG_STUBBY */

#ifdef TCONFIG_MDNS
void generate_mdns_config(void)
{
	FILE *fp;
	char avahi_config[80];
	char *wan2_ifname;
#ifdef TCONFIG_MULTIWAN
	char *wan3_ifname;
	char *wan4_ifname;
#endif

	sprintf(avahi_config, "%s/%s", AVAHI_CONFIG_PATH, AVAHI_CONFIG_FN);

	/* generate avahi configuration file */
	if (!(fp = fopen(avahi_config, "w"))) {
		perror(avahi_config);
		return;
	}

	/* set [server] configuration */
	fprintf(fp, "[Server]\n"
	            "use-ipv4=yes\n"
	            "use-ipv6=%s\n"
	            "deny-interfaces=%s",
	            ipv6_enabled() ? "yes" : "no",
	            nvram_safe_get("wan_ifname"));

	wan2_ifname = nvram_safe_get("wan2_ifname");
	if (*wan2_ifname)
		fprintf(fp, ",%s", wan2_ifname);

#ifdef TCONFIG_MULTIWAN
	wan3_ifname = nvram_safe_get("wan3_ifname");
	if (*wan3_ifname)
		fprintf(fp, ",%s", wan3_ifname);
	wan4_ifname = nvram_safe_get("wan4_ifname");
	if (*wan4_ifname)
		fprintf(fp, ",%s", wan4_ifname);
#endif

	fprintf(fp, "\n"
	            "ratelimit-interval-usec=1000000\n"
	            "ratelimit-burst=1000\n");

	/* set [publish] configuration */
	fprintf(fp, "\n[publish]\n"
	            "publish-hinfo=yes\n"
	            "publish-a-on-ipv6=no\n"
	            "publish-aaaa-on-ipv4=%s\n",
	            ipv6_enabled() ? "yes" : "no");

	/* set [reflector] configuration */
	fprintf(fp, "\n[reflector]\n");
	if (nvram_get_int("mdns_reflector"))
		fprintf(fp, "enable-reflector=yes\n");

	/* set [rlimits] configuration */
	fprintf(fp, "\n[rlimits]\n"
	            "rlimit-core=0\n"
	            "rlimit-data=4194304\n"
	            "rlimit-fsize=0\n"
	            "rlimit-nofile=256\n"
	            "rlimit-stack=4194304\n"
	            "rlimit-nproc=3\n");

	fclose(fp);
}

void start_mdns(void)
{
	if (g_upgrade)
		return;

	if (!nvram_get_int("mdns_enable"))
		return;

	if (getpid() != 1) {
		start_service("mdns");
		return;
	}

	stop_mdns();

	mkdir_if_none(AVAHI_CONFIG_PATH);
	mkdir_if_none(AVAHI_SERVICES_PATH);

	/* alternative (user) configuration file */
	if (f_exists(AVAHI_CONFIG_PATH"/avahi-daemon_alt.conf"))
		eval("avahi-daemon", "-D", "-f", AVAHI_CONFIG_PATH"/avahi-daemon_alt.conf", (nvram_get_int("mdns_debug") ? "--debug" : NULL));
	else {
		generate_mdns_config();
		eval("avahi-daemon", "-D", (nvram_get_int("mdns_debug") ? "--debug" : NULL));
	}
}

void stop_mdns(void)
{
	if (pidof("avahi-daemon") > 0) {
		if (getpid() != 1) {
			stop_service("mdns");
			return;
		}
		killall_tk_period_wait("avahi-daemon", 50);
	}
}
#endif /* TCONFIG_MDNS */

#ifdef TCONFIG_IRQBALANCE
void stop_irqbalance(void)
{
	if (pidof("irqbalance") > 0) {
		killall_tk_period_wait("irqbalance", 50);
		logmsg(LOG_INFO, "irqbalance is stopped");
	}
}

void start_irqbalance(void)
{
	int ret;

	if (getpid() != 1) {
		start_service("irqbalance");
		return;
	}

	stop_irqbalance();

	mkdir_if_none("/var/run/irqbalance");
	ret = eval("irqbalance", "-t", "10");

	if (ret)
		logmsg(LOG_ERR, "starting irqbalance failed ...");
	else
		logmsg(LOG_INFO, "irqbalance is started");
}
#endif /* TCONFIG_IRQBALANCE */

#ifdef TCONFIG_FANCTRL
void start_phy_tempsense()
{
	stop_phy_tempsense();
	/* renice to high priority (10) - avoid revs fluctuations on high CPU load */
	char *phy_tempsense_argv[] = { "nice", "-n", "-10", "phy_tempsense", NULL };
	_eval(phy_tempsense_argv, NULL, 0, &pid_phy_tempsense);
}

void stop_phy_tempsense()
{
	pid_phy_tempsense = -1;
	killall_tk_period_wait("phy_tempsense", 50);
}
#endif /* TCONFIG_FANCTRL */

void start_adblock(int update)
{
	if (nvram_get_int("adblock_enable")) {
		killall("adblock", SIGTERM);
		sleep(1);
		if (update)
			xstart(ADBLOCK_EXE, "update");
		else
			xstart(ADBLOCK_EXE);
	}
}

void stop_adblock()
{
	xstart(ADBLOCK_EXE, "stop");
}

#ifdef TCONFIG_IPV6
static int write_ipv6_dns_servers(FILE *f, const char *prefix, char *dns, const char *suffix, int once)
{
	char p[INET6_ADDRSTRLEN + 1], *next = NULL;
	struct in6_addr addr;
	int cnt = 0;

	foreach(p, dns, next) {
		/* verify that this is a valid IPv6 address */
		if (inet_pton(AF_INET6, p, &addr) == 1) {
			fprintf(f, "%s%s%s", (once && cnt) ? "" : prefix, p, suffix);
			++cnt;
		}
	}

	return cnt;
}
#endif

void dns_to_resolv(void)
{
	FILE *f;
	const dns_list_t *dns;
	char *trig_ip;
	int i;
	mode_t m;
	char wan_prefix[] = "wanXX";
	int wan_unit, mwan_num;
	int append = 0;
	int exclusive = 0;
	char tmp[64];

	mwan_num = nvram_get_int("mwan_num");
	if ((mwan_num < 1) || (mwan_num > MWAN_MAX))
		mwan_num = 1;

	for (wan_unit = 1; wan_unit <= mwan_num; ++wan_unit) {
		get_wan_prefix(wan_unit, wan_prefix);

		/* skip inactive WAN connections */
		if ((check_wanup(wan_prefix) == 0) &&
		    get_wanx_proto(wan_prefix) != WP_DISABLED &&
		    get_wanx_proto(wan_prefix) != WP_PPTP &&
		    get_wanx_proto(wan_prefix) != WP_L2TP &&
		    !nvram_get_int(strcat_r(wan_prefix, "_ppp_demand", tmp)))
		{
			logmsg(LOG_DEBUG, "*** %s: %s (proto:%d) is not UP, not P-t-P or On Demand, SKIP ADD", __FUNCTION__, wan_prefix, get_wanx_proto(wan_prefix));
			continue;
		}
		else {
			logmsg(LOG_DEBUG, "*** %s: %s (proto:%d) is OK to ADD", __FUNCTION__, wan_prefix, get_wanx_proto(wan_prefix));
			append++;
		}
		m = umask(022); /* 077 from pppoecd */
		if ((f = fopen(dmresolv, (append == 1) ? "w" : "a")) != NULL) { /* write / append */
			if (append == 1)
				/* check for VPN DNS entries */
				exclusive = (write_pptp_client_resolv(f)
#ifdef TCONFIG_OPENVPN
				             || write_ovpn_resolv(f)
#endif
				);

			logmsg(LOG_DEBUG, "*** %s: exclusive: %d", __FUNCTION__, exclusive);
			if (!exclusive) { /* exclusive check */
#ifdef TCONFIG_IPV6
				if ((write_ipv6_dns_servers(f, "nameserver ", nvram_safe_get("ipv6_dns"), "\n", 0) == 0) || (nvram_get_int("dns_addget")))
					if (append == 1) /* only once */
						write_ipv6_dns_servers(f, "nameserver ", nvram_safe_get("ipv6_get_dns"), "\n", 0);
#endif
				dns = get_dns(wan_prefix); /* static buffer */
				if (dns->count == 0) {
					/* put a pseudo DNS IP to trigger Connect On Demand */
					if (nvram_match(strcat_r(wan_prefix, "_ppp_demand", tmp), "1")) {
						switch (get_wanx_proto(wan_prefix)) {
							case WP_PPPOE:
							case WP_PPP3G:
							case WP_PPTP:
							case WP_L2TP:
								/* The nameserver IP specified below used to be 1.1.1.1, however this became an legit IP address of a public recursive DNS server,
								 * defeating the purpose of specifying a bogus DNS server in order to trigger Connect On Demand.
								 * An IP address from TEST-NET-2 block was chosen here, as RFC 5737 explicitly states this address block
								 * should be non-routable over the public internet. In effect since January 2010.
								 * Further info: http://linksysinfo.org/index.php?threads/tomato-using-1-1-1-1-for-pppoe-connect-on-demand.74102
								 * Also add possibility to change that IP (198.51.100.1) in GUI by the user
								 */
								trig_ip = nvram_safe_get(strcat_r(wan_prefix, "_ppp_demand_dnsip", tmp));
								logmsg(LOG_DEBUG, "*** %s: no servers for %s: put a pseudo DNS (non-routable on public internet) IP %s to trigger Connect On Demand", __FUNCTION__, wan_prefix, trig_ip);
								fprintf(f, "nameserver %s\n", trig_ip);
								break;
						}
					}
				}
				else {
					fprintf(f, "# dns for %s:\n", wan_prefix);
					for (i = 0; i < dns->count; i++) {
						if (dns->dns[i].port == 53) { /* resolv.conf doesn't allow for an alternate port */
							fprintf(f, "nameserver %s\n", inet_ntoa(dns->dns[i].addr));
							logmsg(LOG_DEBUG, "*** %s: %s DNS %s to %s [%s]", ((append == 1) ? "write" : "append"), __FUNCTION__, inet_ntoa(dns->dns[i].addr), dmresolv, wan_prefix);
						}
					}
				}
			}
			fclose(f);
		}
		else {
			perror(dmresolv);
			return;
		}
		umask(m);

	} /* end for (wan_unit = 1; wan_unit <= mwan_num; ++wan_unit) */
}

void start_httpd(void)
{
	int ret;

	if (getpid() != 1) {
		start_service("httpd");
		return;
	}

	if (nvram_match("web_css", "online"))
		xstart("/usr/sbin/ttb");

	stop_httpd();
	/* wait to exit gracefully */
	sleep(1);

	/* set www dir */
	if (nvram_match("web_dir", "jffs"))
		chdir("/jffs/www");
	else if (nvram_match("web_dir", "opt"))
		chdir("/opt/www");
	else if (nvram_match("web_dir", "tmp"))
		chdir("/tmp/www");
	else
		chdir("/www");

	ret = eval("httpd", (nvram_get_int("http_nocache") ? "-N" : ""));
	chdir("/");

	if (ret)
		logmsg(LOG_ERR, "starting httpd failed ...");
	else
		logmsg(LOG_INFO, "httpd is started");
}

void stop_httpd(void)
{
	if (getpid() != 1) {
		stop_service("httpd");
		return;
	}

	if (pidof("httpd") > 0) {
		killall_tk_period_wait("httpd", 50);
		logmsg(LOG_INFO, "httpd is stopped");
	}
}

#ifdef TCONFIG_IPV6
static void add_ip6_lanaddr(void)
{
	char ip[INET6_ADDRSTRLEN + 4];
	const char *p;

	p = ipv6_router_address(NULL);
	if (*p) {
		snprintf(ip, sizeof(ip), "%s/%d", p, nvram_get_int("ipv6_prefix_length") ? : 64);

		eval("ip", "-6", "addr", "add", ip, "dev", nvram_safe_get("lan_ifname"));
	}
}

void start_ipv6_tunnel(void)
{
	char ip[INET6_ADDRSTRLEN + 4];
	struct in_addr addr4;
	struct in6_addr addr;
	char *wanip, *mtu, *tun_dev;
	int service;
	char wan_prefix[] = "wanXX";
	int wan_unit, mwan_num;

	mwan_num = nvram_get_int("mwan_num");
	if ((mwan_num < 1) || (mwan_num > MWAN_MAX))
		mwan_num = 1;

	for (wan_unit = 1; wan_unit <= mwan_num; ++wan_unit) {
		get_wan_prefix(wan_unit, wan_prefix);
		if (check_wanup(wan_prefix))
			break;
	}

	service = get_ipv6_service();
	tun_dev = (char *)get_wan6face();
	wanip = (char *)get_wanip(wan_prefix);

	mtu = (nvram_get_int("ipv6_tun_mtu") > 0) ? nvram_safe_get("ipv6_tun_mtu") : "1480";

	modprobe("sit");

	eval("ip", "tunnel", "add", tun_dev, "mode", "sit", "remote", (service == IPV6_ANYCAST_6TO4) ? "any" : nvram_safe_get("ipv6_tun_v4end"), "local", wanip, "ttl", nvram_safe_get("ipv6_tun_ttl"));
	eval("ip", "link", "set", tun_dev, "mtu", mtu, "up");

	nvram_set("ipv6_ifname", tun_dev);

	if (service == IPV6_ANYCAST_6TO4) {
		int prefixlen = 16;
		int mask4size = 0;

		addr4.s_addr = 0;
		memset(&addr, 0, sizeof(addr));
		inet_aton(wanip, &addr4);
		addr.s6_addr16[0] = htons(0x2002);
		ipv6_mapaddr4(&addr, prefixlen, &addr4, mask4size);
		addr.s6_addr16[7] = htons(0x0001);
		inet_ntop(AF_INET6, &addr, ip, sizeof(ip));
		snprintf(ip, sizeof(ip), "%s/%d", ip, prefixlen);
		add_ip6_lanaddr();
	}
	/* static tunnel 6to4 */
	else
		snprintf(ip, sizeof(ip), "%s/%d", nvram_safe_get("ipv6_tun_addr"), nvram_get_int("ipv6_tun_addrlen") ? : 64);

	eval("ip", "-6", "addr", "add", ip, "dev", tun_dev);

	if (service == IPV6_ANYCAST_6TO4) {
		snprintf(ip, sizeof(ip), "::192.88.99.%d", nvram_get_int("ipv6_relay"));
		eval("ip", "-6", "route", "add", "2000::/3", "via", ip, "dev", tun_dev, "metric", "1");
	}
	else
		eval("ip", "-6", "route", "add", "::/0", "dev", tun_dev, "metric", "1");

	/* (re)start dnsmasq */
	if (service == IPV6_ANYCAST_6TO4)
		start_dnsmasq();
}

void stop_ipv6_tunnel(void)
{
	eval("ip", "tunnel", "del", (char *)get_wan6face());

	if (get_ipv6_service() == IPV6_ANYCAST_6TO4)
		/* get rid of old IPv6 address from lan iface */
		eval("ip", "-6", "addr", "flush", "dev", nvram_safe_get("lan_ifname"), "scope", "global");

	modprobe_r("sit");
}

void start_6rd_tunnel(void)
{
	const char *tun_dev, *wanip;
	int service, mask_len, prefix_len, local_prefix_len;
	char mtu[10], prefix[INET6_ADDRSTRLEN], relay[INET_ADDRSTRLEN];
	struct in_addr netmask_addr, relay_addr, relay_prefix_addr, wanip_addr;
	struct in6_addr prefix_addr, local_prefix_addr;
	char local_prefix[INET6_ADDRSTRLEN];
	char tmp_ipv6[INET6_ADDRSTRLEN + 4], tmp_ipv4[INET_ADDRSTRLEN + 4];
	char tmp[256];
	FILE *f;
	char wan_prefix[] = "wanXX";
	int wan_unit, mwan_num;

	mwan_num = nvram_get_int("mwan_num");
	if ((mwan_num < 1) || (mwan_num > MWAN_MAX))
		mwan_num = 1;

	for (wan_unit = 1; wan_unit <= mwan_num; ++wan_unit) {
		get_wan_prefix(wan_unit, wan_prefix);
		if (check_wanup(wan_prefix))
			break;
	}

	service = get_ipv6_service();
	wanip = get_wanip(wan_prefix);
	tun_dev = get_wan6face();
	memset(mtu, 0, 10);
	sprintf(mtu, "%d", (nvram_get_int("wan_mtu") > 0) ? (nvram_get_int("wan_mtu") - 20) : 1280);

	/* maybe we can merge the ipv6_6rd_* variables into a single ipv_6rd_string (ala wan_6rd) to save nvram space? */
	if (service == IPV6_6RD) {
		logmsg(LOG_DEBUG, "*** %s: starting 6rd tunnel using manual settings", __FUNCTION__);
		mask_len = nvram_get_int("ipv6_6rd_ipv4masklen");
		prefix_len = nvram_get_int("ipv6_6rd_prefix_length");
		strcpy(prefix, nvram_safe_get("ipv6_6rd_prefix"));
		strcpy(relay, nvram_safe_get("ipv6_6rd_borderrelay"));
	}
	else {
		logmsg(LOG_DEBUG, "*** %s: starting 6rd tunnel using automatic settings", __FUNCTION__);
		char *wan_6rd = nvram_safe_get("wan_6rd");
		if (sscanf(wan_6rd, "%d %d %s %s", &mask_len,  &prefix_len, prefix, relay) < 4) {
			logmsg(LOG_DEBUG, "*** %s: wan_6rd string is missing or invalid (%s)", __FUNCTION__, wan_6rd);
			return;
		}
	}

	/* validate values that were passed */
	if ((mask_len < 0) || (mask_len > 32)) {
		logmsg(LOG_DEBUG, "*** %s: invalid mask_len value (%d)", __FUNCTION__, mask_len);
		return;
	}
	if ((prefix_len < 0) || (prefix_len > 128)) {
		logmsg(LOG_DEBUG, "*** %s: invalid prefix_len value (%d)", __FUNCTION__, prefix_len);
		return;
	}
	if (((32 - mask_len) + prefix_len) > 128) {
		logmsg(LOG_DEBUG, "*** %s: invalid combination of mask_len and prefix_len!", __FUNCTION__);
		return;
	}

	memset(tmp, 0, 256);
	sprintf(tmp, "ping -q -c 2 %s | grep packet", relay);
	if ((f = popen(tmp, "r")) == NULL) {
		logmsg(LOG_DEBUG, "*** %s: error obtaining data", __FUNCTION__);
		return;
	}
	fgets(tmp, sizeof(tmp), f);
	pclose(f);

	if (strstr(tmp, " 0% packet loss") == NULL) {
		logmsg(LOG_DEBUG, "*** %s: failed to ping border relay", __FUNCTION__);
		return;
	}

	/* get relay prefix from border relay address and mask */
	netmask_addr.s_addr = htonl(0xffffffff << (32 - mask_len));
	inet_aton(relay, &relay_addr);
	relay_prefix_addr.s_addr = relay_addr.s_addr & netmask_addr.s_addr;

	/* calculate the local prefix */
	inet_pton(AF_INET6, prefix, &prefix_addr);
	inet_pton(AF_INET, wanip, &wanip_addr);
	if (calc_6rd_local_prefix(&prefix_addr, prefix_len, mask_len, &wanip_addr, &local_prefix_addr, &local_prefix_len) == 0) {
		logmsg(LOG_DEBUG, "*** %s: error calculating local prefix", __FUNCTION__);
		return;
	}
	inet_ntop(AF_INET6, &local_prefix_addr, local_prefix, sizeof(local_prefix));

	snprintf(tmp_ipv6, sizeof(tmp_ipv6), "%s1", local_prefix);
	nvram_set("ipv6_rtr_addr", tmp_ipv6);
	nvram_set("ipv6_prefix", local_prefix);

	/* load sit module needed for the 6rd tunnel */
	modprobe("sit");

	/* create the 6rd tunnel */
	eval("ip", "tunnel", "add", (char *)tun_dev, "mode", "sit", "local", (char *)wanip, "ttl", nvram_safe_get("ipv6_tun_ttl"));

	snprintf(tmp_ipv6, sizeof(tmp_ipv6), "%s/%d", prefix, prefix_len);
	snprintf(tmp_ipv4, sizeof(tmp_ipv4), "%s/%d", inet_ntoa(relay_prefix_addr), mask_len);
	eval("ip", "tunnel" "6rd", "dev", (char *)tun_dev, "6rd-prefix", tmp_ipv6, "6rd-relay_prefix", tmp_ipv4);

	/* bring up the link */
	eval("ip", "link", "set", "dev", (char *)tun_dev, "mtu", (char *)mtu, "up");

	/* set the WAN address Note: IPv6 WAN CIDR should be: ((32 - ip6rd_ipv4masklen) + ip6rd_prefixlen) */
	snprintf(tmp_ipv6, sizeof(tmp_ipv6), "%s1/%d", local_prefix, local_prefix_len);
	eval("ip", "-6", "addr", "add", tmp_ipv6, "dev", (char *)tun_dev);

	/* set the LAN address Note: IPv6 LAN CIDR should be 64 */
	snprintf(tmp_ipv6, sizeof(tmp_ipv6), "%s1/%d", local_prefix, nvram_get_int("ipv6_prefix_length") ? : 64);
	eval("ip", "-6", "addr", "add", tmp_ipv6, "dev", nvram_safe_get("lan_ifname"));

	/* add default route via the border relay */
	snprintf(tmp_ipv6, sizeof(tmp_ipv6), "::%s", relay);
	eval("ip", "-6", "route", "add", "::/0", "via", tmp_ipv6, "dev", (char *)tun_dev);

	nvram_set("ipv6_ifname", (char *)tun_dev);

	/* (re)start dnsmasq */
	start_dnsmasq();
}

void stop_6rd_tunnel(void)
{
	eval("ip", "tunnel", "del", (char *)get_wan6face());
	eval("ip", "-6", "addr", "flush", "dev", nvram_safe_get("lan_ifname"), "scope", "global");

	modprobe_r("sit");
}

void start_ipv6(void)
{
	int service, i;
	char buffer[16];

	service = get_ipv6_service();

	/* check if turned on */
	if (service != IPV6_DISABLED) {

		ipv6_forward("default", 1); /* enable it for default */
		ipv6_forward("all", 1); /* enable it for all */
		ndp_proxy("default", 1);
		ndp_proxy("all", 1);

		/* check if "ipv6_accept_ra" (bit 1) for lan is enabled (via GUI, basic-ipv6.asp) and "ipv6_radvd" AND "ipv6_dhcpd" (SLAAC and/or DHCP with dnsmasq) is disabled (via GUI, advanced-dhcpdns.asp) */
		/* HINT: "ipv6_accept_ra" bit 0 ==> used for wan, "ipv6_accept_ra" bit 1 ==> used for lan interfaces (br0...br3) */
		/* check lanX / brX if available */
		for (i = 0; i < BRIDGE_COUNT; i++) {
			memset(buffer, 0, 16);
			sprintf(buffer, (i == 0 ? "lan_ipaddr" : "lan%d_ipaddr"), i);
			if (strcmp(nvram_safe_get(buffer), "") != 0) {
				memset(buffer, 0, 16);
				sprintf(buffer, (i == 0 ? "lan_ifname" : "lan%d_ifname"), i);
				if (((nvram_get_int("ipv6_accept_ra") & 0x02) != 0) && !nvram_get_int("ipv6_radvd") && !nvram_get_int("ipv6_dhcpd"))
					/* accept_ra for brX */
					accept_ra(nvram_safe_get(buffer));
				else
					/* accept_ra default value for brX */
					accept_ra_reset(nvram_safe_get(buffer));
			}
		}
	}

	switch (service) {
		case IPV6_NATIVE:
		case IPV6_6IN4:
		case IPV6_MANUAL:
			add_ip6_lanaddr();
			break;
		case IPV6_NATIVE_DHCP:
		case IPV6_ANYCAST_6TO4:
			nvram_set("ipv6_rtr_addr", "");
			nvram_set("ipv6_prefix", "");
			break;
	}
}

void stop_ipv6(void)
{
	stop_ipv6_tunnel();
	stop_dhcp6c();

	ipv6_forward("default", 0); /* disable it for default */
	ipv6_forward("all", 0); /* disable it for all */
	ndp_proxy("default", 0);
	ndp_proxy("all", 0);

	eval("ip", "-6", "addr", "flush", "scope", "global");
	eval("ip", "-6", "route", "flush", "scope", "global");
}
#endif /* TCONFIG_IPV6 */

void start_upnp(void)
{
	int enable;
	int upnp_port;
	int interval;
	int https;
	int ports[4];
	char uuid[45];
	char lanN_ipaddr[] = "lanXX_ipaddr";
	char lanN_netmask[] = "lanXX_netmask";
	char lanN_ifname[] = "lanXX_ifname";
	char upnp_lanN[] = "upnp_lanXX";
	char *lanip;
	char *lanmask;
	char *lanifname;
	char br;
	FILE *f;

	if (get_wan_proto() == WP_DISABLED)
		return;

	if (getpid() != 1) {
		start_service("upnp");
		return;
	}

	if (((enable = nvram_get_int("upnp_enable")) & 3) != 0) {
		mkdir(UPNP_DIR, 0777);
		if (f_exists(UPNP_DIR"/config.alt"))
			xstart("miniupnpd", "-f", UPNP_DIR"/config.alt");
		else {
			if ((f = fopen(UPNP_DIR"/config", "w")) != NULL) {
				upnp_port = nvram_get_int("upnp_port");
				if ((upnp_port < 0) || (upnp_port >= 0xFFFF))
					upnp_port = 0;

				if (check_wanup("wan2"))
					fprintf(f, "ext_ifname=%s\n", get_wanface("wan2"));
#ifdef TCONFIG_MULTIWAN
				if (check_wanup("wan3"))
					fprintf(f, "ext_ifname=%s\n", get_wanface("wan3"));

				if (check_wanup("wan4"))
					fprintf(f, "ext_ifname=%s\n", get_wanface("wan4"));
#endif

				fprintf(f, "ext_ifname=%s\n"
				           "port=%d\n"
				           "enable_upnp=%s\n"
				           "enable_natpmp=%s\n"
				           "secure_mode=%s\n"
				           "upnp_forward_chain=upnp\n"
				           "upnp_nat_chain=upnp\n"
				           "upnp_nat_postrouting_chain=pupnp\n"
				           "notify_interval=%d\n"
				           "system_uptime=yes\n"
				           "friendly_name=%s"" Router\n"
				           "model_name=%s\n"
				           "model_url=https://freshtomato.org/\n"
				           "manufacturer_name=FreshTomato Firmware\n"
				           "manufacturer_url=https://freshtomato.org/\n"
				           "\n",
				           get_wanface("wan"),
				           upnp_port,
				           (enable & 1) ? "yes" : "no",			/* upnp enable */
				           (enable & 2) ? "yes" : "no",			/* natpmp enable */
				           nvram_get_int("upnp_secure") ? "yes" : "no",	/* secure_mode (only forward to self) */
				           nvram_get_int("upnp_ssdp_interval"),
				           nvram_safe_get("router_name"),
				           nvram_safe_get("t_model_name"));

				if (nvram_get_int("upnp_clean")) {
					interval = nvram_get_int("upnp_clean_interval");
					if (interval < 60)
						interval = 60;

					fprintf(f, "clean_ruleset_interval=%d\n"
					           "clean_ruleset_threshold=%d\n",
					           interval,
					           nvram_get_int("upnp_clean_threshold"));
				}
				else
					fprintf(f, "clean_ruleset_interval=0\n");

				if (nvram_get_int("upnp_mnp")) {
					https = nvram_get_int("https_enable");
					fprintf(f, "presentation_url=http%s://%s:%s/forward-upnp.asp\n", (https ? "s" : ""), nvram_safe_get("lan_ipaddr"), nvram_safe_get(https ? "https_lanport" : "http_lanport"));
				}
				else
					/* Empty parameters are not included into XML service description */
					fprintf(f, "presentation_url=\n");

				f_read_string("/proc/sys/kernel/random/uuid", uuid, sizeof(uuid));
				fprintf(f, "uuid=%s\n", uuid);

				/* move custom configuration before "allow" statements */
				/* discussion: http://www.linksysinfo.org/index.php?threads/miniupnpd-custom-config-syntax.70863/#post-256291 */
				fappend(f, UPNP_DIR"/config.custom");
				fprintf(f, "%s\n", nvram_safe_get("upnp_custom"));

				for (br = 0; br < BRIDGE_COUNT; br++) {
					char bridge[2] = "0";
					if (br != 0)
						bridge[0] += br;
					else
						strcpy(bridge, "");

					sprintf(lanN_ipaddr, "lan%s_ipaddr", bridge);
					sprintf(lanN_netmask, "lan%s_netmask", bridge);
					sprintf(lanN_ifname, "lan%s_ifname", bridge);
					sprintf(upnp_lanN, "upnp_lan%s", bridge);

					lanip = nvram_safe_get(lanN_ipaddr);
					lanmask = nvram_safe_get(lanN_netmask);
					lanifname = nvram_safe_get(lanN_ifname);

					if ((strcmp(nvram_safe_get(upnp_lanN), "1") == 0) && (strcmp(lanifname, "") != 0)) {
						fprintf(f, "listening_ip=%s\n", lanifname);

						if ((ports[0] = nvram_get_int("upnp_min_port_ext")) > 0 &&
						    (ports[1] = nvram_get_int("upnp_max_port_ext")) > 0 &&
						    (ports[2] = nvram_get_int("upnp_min_port_int")) > 0 &&
						    (ports[3] = nvram_get_int("upnp_max_port_int")) > 0)
							fprintf(f, "allow %d-%d %s/%s %d-%d\n", ports[0], ports[1], lanip, lanmask, ports[2], ports[3]);
						else
							/* by default allow only redirection of ports above 1024 */
							fprintf(f, "allow 1024-65535 %s/%s 1024-65535\n", lanip, lanmask);
					}
				}
				fprintf(f, "\ndeny 0-65535 0.0.0.0/0 0-65535\n");

				fclose(f);

				xstart("miniupnpd", "-f", UPNP_DIR"/config");
			}
			else {
				perror(UPNP_DIR"/config");
				return;
			}
		}
	}
}

void stop_upnp(void)
{
	if (getpid() != 1) {
		stop_service("upnp");
		return;
	}

	killall_tk_period_wait("miniupnpd", 50);
}

void start_cron(void)
{
	stop_cron();

	eval("crond", (nvram_contains_word("log_events", "crond") ? NULL : "-l"), "9");

	if (!nvram_contains_word("debug_norestart", "crond"))
		pid_crond = -2;
}

void stop_cron(void)
{
	pid_crond = -1;
	killall_tk_period_wait("crond", 50);
}

void start_hotplug2()
{
	stop_hotplug2();

	f_write_string("/proc/sys/kernel/hotplug", "", FW_NEWLINE, 0);
	xstart("hotplug2", "--persistent", "--no-coldplug");

	/* FIXME: Don't remember exactly why I put "sleep" here - but it was not for a race with check_services()... */
	sleep(1);

	if (!nvram_contains_word("debug_norestart", "hotplug2"))
		pid_hotplug2 = -2;
}

void stop_hotplug2(void)
{
	pid_hotplug2 = -1;
	killall_tk_period_wait("hotplug2", 50);
}

#ifdef TCONFIG_ZEBRA
void start_zebra(void)
{
	FILE *fp;

	char *lan_tx = nvram_safe_get("dr_lan_tx");
	char *lan_rx = nvram_safe_get("dr_lan_rx");
	char *lan1_tx = nvram_safe_get("dr_lan1_tx");
	char *lan1_rx = nvram_safe_get("dr_lan1_rx");
	char *lan2_tx = nvram_safe_get("dr_lan2_tx");
	char *lan2_rx = nvram_safe_get("dr_lan2_rx");
	char *lan3_tx = nvram_safe_get("dr_lan3_tx");
	char *lan3_rx = nvram_safe_get("dr_lan3_rx");
	char *wan_tx = nvram_safe_get("dr_wan_tx");
	char *wan_rx = nvram_safe_get("dr_wan_rx");

	if (getpid() != 1) {
		start_service("zebra");
		return;
	}

	if ((*lan_tx == '0') && (*lan_rx == '0') &&
	    (*lan1_tx == '0') && (*lan1_rx == '0') &&
	    (*lan2_tx == '0') && (*lan2_rx == '0') &&
	    (*lan3_tx == '0') && (*lan3_rx == '0') &&
	    (*wan_tx == '0') && (*wan_rx == '0')) {
		return;
	}

	/* empty */
	if ((fp = fopen(ZEBRA_CONF, "w")) != NULL)
		fclose(fp);

	if ((fp = fopen(RIPD_CONF, "w")) != NULL) {
		char *lan_ifname = nvram_safe_get("lan_ifname");
		char *lan1_ifname = nvram_safe_get("lan1_ifname");
		char *lan2_ifname = nvram_safe_get("lan2_ifname");
		char *lan3_ifname = nvram_safe_get("lan3_ifname");
		char *wan_ifname = nvram_safe_get("wan_ifname");

		fprintf(fp, "router rip\n");
		if (strcmp(lan_ifname, "") != 0)
			fprintf(fp, "network %s\n", lan_ifname);
		if (strcmp(lan1_ifname, "") != 0)
			fprintf(fp, "network %s\n", lan1_ifname);
		if (strcmp(lan2_ifname, "") != 0)
			fprintf(fp, "network %s\n", lan2_ifname);
		if (strcmp(lan3_ifname, "") != 0)
			fprintf(fp, "network %s\n", lan3_ifname);
		fprintf(fp, "network %s\n", wan_ifname);
		fprintf(fp, "redistribute connected\n");

		if (strcmp(lan_ifname, "") != 0) {
			fprintf(fp, "interface %s\n", lan_ifname);
			if (*lan_tx != '0')
				fprintf(fp, "ip rip send version %s\n", lan_tx);
			if (*lan_rx != '0')
				fprintf(fp, "ip rip receive version %s\n", lan_rx);
		}
		if (strcmp(lan1_ifname, "") != 0) {
			fprintf(fp, "interface %s\n", lan1_ifname);
			if (*lan1_tx != '0')
				fprintf(fp, "ip rip send version %s\n", lan1_tx);
			if (*lan1_rx != '0')
				fprintf(fp, "ip rip receive version %s\n", lan1_rx);
		}
		if (strcmp(lan2_ifname, "") != 0) {
			fprintf(fp, "interface %s\n", lan2_ifname);
			if (*lan2_tx != '0')
				fprintf(fp, "ip rip send version %s\n", lan2_tx);
			if (*lan2_rx != '0')
				fprintf(fp, "ip rip receive version %s\n", lan2_rx);
		}
		if (strcmp(lan3_ifname, "") != 0) {
			fprintf(fp, "interface %s\n", lan3_ifname);
			if (*lan3_tx != '0')
				fprintf(fp, "ip rip send version %s\n", lan3_tx);
			if (*lan3_rx != '0')
				fprintf(fp, "ip rip receive version %s\n", lan3_rx);
		}
		fprintf(fp, "interface %s\n", wan_ifname);
		if (*wan_tx != '0')
			fprintf(fp, "ip rip send version %s\n", wan_tx);
		if (*wan_rx != '0')
			fprintf(fp, "ip rip receive version %s\n", wan_rx);

		fprintf(fp, "router rip\n");
		if (strcmp(lan_ifname, "") != 0) {
			if (*lan_tx == '0')
				fprintf(fp, "distribute-list private out %s\n", lan_ifname);
			if (*lan_rx == '0')
				fprintf(fp, "distribute-list private in %s\n", lan_ifname);
		}
		if (strcmp(lan1_ifname, "") != 0) {
			if (*lan1_tx == '0')
				fprintf(fp, "distribute-list private out %s\n", lan1_ifname);
			if (*lan1_rx == '0')
				fprintf(fp, "distribute-list private in %s\n", lan1_ifname);
		}
		if (strcmp(lan2_ifname, "") != 0) {
			if (*lan2_tx == '0')
				fprintf(fp, "distribute-list private out %s\n", lan2_ifname);
			if (*lan2_rx == '0')
				fprintf(fp, "distribute-list private in %s\n", lan2_ifname);
		}
		if (strcmp(lan3_ifname, "") != 0) {
			if (*lan3_tx == '0')
				fprintf(fp, "distribute-list private out %s\n", lan3_ifname);
			if (*lan3_rx == '0')
				fprintf(fp, "distribute-list private in %s\n", lan3_ifname);
		}
		if (*wan_tx == '0')
			fprintf(fp, "distribute-list private out %s\n", wan_ifname);
		if (*wan_rx == '0')
			fprintf(fp, "distribute-list private in %s\n", wan_ifname);
		fprintf(fp, "access-list private deny any\n");

		//fprintf(fp, "debug rip events\n");
		//fprintf(fp, "log file /etc/ripd.log\n");
		fclose(fp);
	}
	else {
		perror(RIPD_CONF);
		return;
	}

	xstart("zebra", "-d");
	xstart("ripd",  "-d");
}

void stop_zebra(void)
{
	if (getpid() != 1) {
		stop_service("zebra");
		return;
	}

	killall("zebra", SIGTERM);
	killall("ripd", SIGTERM);

	unlink(ZEBRA_CONF);
	unlink(RIPD_CONF);
}
#endif /* #ifdef TCONFIG_ZEBRA */

void start_syslog(void)
{
	char *argv[20];
	int argc;
	char *nv;
	char *b_opt = "";
	char rem[256];
	int n;
	char s[64];
	char cfg[256];
	char *rot_siz = "50";
	char *rot_keep = "1";
	char *log_file_path;
	char log_default[] = "/var/log/messages";
	char *log_min_level;

	argv[0] = "syslogd";
	argc = 1;

	if (nvram_get_int("log_dropdups"))
		argv[argc++] = "-D";

	if (nvram_get_int("log_remote")) {
		nv = nvram_safe_get("log_remoteip");
		if (*nv) {
			snprintf(rem, sizeof(rem), "%s:%s", nv, nvram_safe_get("log_remoteport"));
			argv[argc++] = "-R";
			argv[argc++] = rem;
		}
	}

	if (nvram_get_int("log_file")) {
		argv[argc++] = "-L";

		if (strcmp(nvram_safe_get("log_file_size"), "") != 0)
			rot_siz = nvram_safe_get("log_file_size");

		if (nvram_get_int("log_file_size") > 0)
			rot_keep = nvram_safe_get("log_file_keep");

		/* log to custom path */
		if (nvram_get_int("log_file_custom")) {
			log_file_path = nvram_safe_get("log_file_path");
			argv[argc++] = "-s";
			argv[argc++] = rot_siz;
			argv[argc++] = "-O";
			argv[argc++] = log_file_path;
			if (strcmp(nvram_safe_get("log_file_path"), log_default) != 0) {
				remove(log_default);
				symlink(log_file_path, log_default);
			}
		}
		else {
			/* Read options:    rotate_size(kb)    num_backups    logfilename.
			 * Ignore these settings and use defaults if the logfile cannot be written to.
			 */
			if (f_read_string("/etc/syslogd.cfg", cfg, sizeof(cfg)) > 0) {
				if ((nv = strchr(cfg, '\n')))
					*nv = 0;

				if ((nv = strtok(cfg, " \t"))) {
					if (isdigit(*nv))
						rot_siz = nv;
				}

				if ((nv = strtok(NULL, " \t")))
					b_opt = nv;

				if ((nv = strtok(NULL, " \t")) && *nv == '/') {
					if (f_write(nv, cfg, 0, FW_APPEND, 0) >= 0) {
						argv[argc++] = "-O";
						argv[argc++] = nv;
					}
					else {
						rot_siz = "50";
						b_opt = "";
					}
				}
			}
		}

		if (!(nvram_get_int("log_file_custom"))) {
			argv[argc++] = "-s";
			argv[argc++] = rot_siz;
			struct stat sb;
			if (lstat(log_default, &sb) != -1)
				if (S_ISLNK(sb.st_mode))
					remove(log_default);
		}

		if (isdigit(*b_opt)) {
			argv[argc++] = "-b";
			argv[argc++] = b_opt;
		}
		else if (nvram_get_int("log_file_size") > 0) {
			argv[argc++] = "-b";
			argv[argc++] = rot_keep;
		}

		log_min_level = nvram_safe_get("log_min_level");
		argv[argc++] = "-l";
		argv[argc++] = log_min_level;
	}

	if (argc > 1) {
		argv[argc] = NULL;
		_eval(argv, NULL, 0, NULL);

		argv[0] = "klogd";
		argv[1] = NULL;
		_eval(argv, NULL, 0, NULL);

		/* used to be available in syslogd -m */
		n = nvram_get_int("log_mark");
		if (n > 0) {
			memset(rem, 0, 256);
			/* n is in minutes */
			if (n < 60)
				sprintf(rem, "*/%d * * * *", n);
			else if (n < 60 * 24)
				sprintf(rem, "0 */%d * * *", n / 60);
			else
				sprintf(rem, "0 0 */%d * *", n / (60 * 24));

			memset(s, 0, 64);
			sprintf(s, "%s logger -p syslog.info -- -- MARK --", rem);
			eval("cru", "a", "syslogdmark", s);
		}
		else {
			eval("cru", "d", "syslogdmark");
		}
	}
}

void stop_syslog(void)
{
	killall("klogd", SIGTERM);
	killall("syslogd", SIGTERM);
}

void start_igmp_proxy(void)
{
	FILE *fp;
	const char *nv;
	char igmp_buffer[32];
	char wan_prefix[] = "wanXX";
	int wan_unit, mwan_num, count = 0;

	mwan_num = nvram_get_int("mwan_num");
	if ((mwan_num < 1) || (mwan_num > MWAN_MAX))
		mwan_num = 1;

	pid_igmp = -1;
	if (nvram_get_int("multicast_pass")) {
		int ret = 1;

		if (f_exists("/etc/igmp.alt"))
			ret = eval("igmpproxy", "/etc/igmp.alt");
		else if ((fp = fopen(IGMP_CONF, "w")) != NULL) {
			/* check that lan, lan1, lan2 and lan3 are not selected and use custom config */
			/* The configuration file must define one (or more) upstream interface(s) and one or more downstream interfaces,
			 * see https://github.com/pali/igmpproxy/commit/b55e0125c79fc9dbc95c6d6ab1121570f0c6f80f and
			 * see https://github.com/pali/igmpproxy/blob/master/igmpproxy.conf
			 */
			if ((!nvram_get_int("multicast_lan")) && (!nvram_get_int("multicast_lan1")) && (!nvram_get_int("multicast_lan2")) && (!nvram_get_int("multicast_lan3"))) {
				fprintf(fp, "%s\n", nvram_safe_get("multicast_custom"));
				fclose(fp);
				ret = eval("igmpproxy", IGMP_CONF);
			}
			/* create default config for upstream/downstream interface(s) */
			else {
				if (nvram_get_int("multicast_quickleave"))
					fprintf(fp, "quickleave\n");

				for (wan_unit = 1; wan_unit <= mwan_num; ++wan_unit) {
					get_wan_prefix(wan_unit, wan_prefix);
					if ((check_wanup(wan_prefix)) && (get_wanx_proto(wan_prefix) != WP_DISABLED)) {
						count++;
						/*
						 * Configuration for Upstream Interface
						 * Example:
						 * phyint ppp0 upstream ratelimit 0 threshold 1
						 * altnet 193.158.35.0/24
						 */
						fprintf(fp, "phyint %s upstream ratelimit 0 threshold 1\n", get_wanface(wan_prefix));
						/* check for allowed remote network address, see note at GUI advanced-firewall.asp */
						if ((nvram_get("multicast_altnet_1") != NULL) || (nvram_get("multicast_altnet_2") != NULL) || (nvram_get("multicast_altnet_3") != NULL)) {
							if (((nv = nvram_get("multicast_altnet_1")) != NULL) && (*nv)) {
								memset(igmp_buffer, 0, sizeof(igmp_buffer)); /* reset */
								snprintf(igmp_buffer, sizeof(igmp_buffer),"%s", nv); /* copy to buffer */
								fprintf(fp, "\taltnet %s\n", igmp_buffer); /* with the following format: a.b.c.d/n - Example: altnet 10.0.0.0/16 */
								logmsg(LOG_INFO, "igmpproxy: multicast_altnet_1 = %s", igmp_buffer);
							}

							if (((nv = nvram_get("multicast_altnet_2")) != NULL) && (*nv)) {
								memset(igmp_buffer, 0, sizeof(igmp_buffer)); /* reset */
								snprintf(igmp_buffer, sizeof(igmp_buffer),"%s", nv); /* copy to buffer */
								fprintf(fp, "\taltnet %s\n", igmp_buffer); /* with the following format: a.b.c.d/n - Example: altnet 10.0.0.0/16 */
								logmsg(LOG_INFO, "igmpproxy: multicast_altnet_2 = %s", igmp_buffer);
							}

							if (((nv = nvram_get("multicast_altnet_3")) != NULL) && (*nv)) {
								memset(igmp_buffer, 0, sizeof(igmp_buffer)); /* reset */
								snprintf(igmp_buffer, sizeof(igmp_buffer),"%s", nv); /* copy to buffer */
								fprintf(fp, "\taltnet %s\n", igmp_buffer); /* with the following format: a.b.c.d/n - Example: altnet 10.0.0.0/16 */
								logmsg(LOG_INFO, "igmpproxy: multicast_altnet_3 = %s", igmp_buffer);
							}
						}
						else
							fprintf(fp, "\taltnet 0.0.0.0/0\n"); /* default, allow all! */
					}
				}
				if (!count) {
					fclose(fp);
					unlink(IGMP_CONF);
					return;
				}

				char lanN_ifname[] = "lanXX_ifname";
				char multicast_lanN[] = "multicast_lanXX";
				char br;

				for (br = 0; br < BRIDGE_COUNT; br++) {
					char bridge[2] = "0";
					if (br != 0)
						bridge[0] += br;
					else
						strcpy(bridge, "");

					sprintf(lanN_ifname, "lan%s_ifname", bridge);
					sprintf(multicast_lanN, "multicast_lan%s", bridge);

					if ((strcmp(nvram_safe_get(multicast_lanN), "1") == 0) && (strcmp(nvram_safe_get(lanN_ifname), "") != 0)) {
					/*
					 * Configuration for Downstream Interface
					 * Example:
					 * phyint br0 downstream ratelimit 0 threshold 1
					 */
						fprintf(fp, "phyint %s downstream ratelimit 0 threshold 1\n", nvram_safe_get(lanN_ifname));
					}
				}
				fclose(fp);
				ret = eval("igmpproxy", IGMP_CONF);
			}
		}
		else {
			perror(IGMP_CONF);
			return;
		}

		if (!nvram_contains_word("debug_norestart", "igmprt"))
			pid_igmp = -2;

		if (ret)
			logmsg(LOG_ERR, "starting igmpproxy failed ...");
		else
			logmsg(LOG_INFO, "igmpproxy is started");
	}
}

void stop_igmp_proxy(void)
{
	pid_igmp = -1;
	if (pidof("igmpproxy") > 0) {
		killall_tk_period_wait("igmpproxy", 50);
		logmsg(LOG_INFO, "igmpproxy is stopped");
	}
}

void start_udpxy(void)
{
	char wan_prefix[] = "wan"; /* not yet mwan ready, use wan for now */
	char buffer[32], buffer2[16];
	int i, bind_lan = 0;

	/* check if udpxy is enabled via GUI, advanced-firewall.asp */
	if (nvram_get_int("udpxy_enable")) {
		if ((check_wanup(wan_prefix)) && (get_wanx_proto(wan_prefix) != WP_DISABLED)) {
			memset(buffer, 0, 32); /* reset */
			if (strlen(nvram_safe_get("udpxy_wanface")) > 0)
				snprintf(buffer, sizeof(buffer), "%s", nvram_safe_get("udpxy_wanface")); /* user entered upstream interface */
			else
				snprintf(buffer, sizeof(buffer), "%s", get_wanface(wan_prefix)); /* copy wanface to buffer */

			/* check interface to listen on */
			/* check udpxy enabled/selected for br0 - br3 */
			for (i = 0; i < BRIDGE_COUNT; i++) {
				int ret1 = 0, ret2 = 0;
				memset(buffer2, 0, 16);
				sprintf(buffer2, (i == 0 ? "udpxy_lan" : "udpxy_lan%d"), i);
				ret1 = nvram_match(buffer2, "1");
				memset(buffer2, 0, 16);
				sprintf(buffer2, (i == 0 ? "lan_ipaddr" : "lan%d_ipaddr"), i);
				ret2 = strcmp(nvram_safe_get(buffer2), "") != 0;
				if (ret1 && ret2) {
					memset(buffer2, 0, 16);
					sprintf(buffer2, (i == 0 ? "lan_ifname" : "lan%d_ifname"), i);
					eval("udpxy", (nvram_get_int("udpxy_stats") ? "-S" : ""), "-p", nvram_safe_get("udpxy_port"), "-c", nvram_safe_get("udpxy_clients"), "-a", nvram_safe_get(buffer2), "-m", buffer);
					bind_lan = 1;
					break; /* start udpxy only once and only for one lanX */
				}
			}
			/* address/interface to listen on: default = 0.0.0.0 */
			if (!bind_lan)
				eval("udpxy", (nvram_get_int("udpxy_stats") ? "-S" : ""), "-p", nvram_safe_get("udpxy_port"), "-c", nvram_safe_get("udpxy_clients"), "-m", buffer);
		}
	}
}

void stop_udpxy(void)
{
	killall_tk_period_wait("udpxy", 50);
}

void set_tz(void)
{
	f_write_string("/etc/TZ", nvram_safe_get("tm_tz"), (FW_CREATE | FW_NEWLINE), 0644);
}

void start_ntpd(void)
{
	FILE *f;
	char *servers, *ptr;
	int servers_len = 0, ntp_updates_int = 0, index = 2, ret;
	char *ntpd_argv[] = { "/usr/sbin/ntpd", "-t", NULL, NULL, NULL, NULL, NULL, NULL }; /* -d6 -q -S /sbin/ntpd_synced -l */
	pid_t pid;

	if (getpid() != 1) {
		start_service("ntpd");
		return;
	}

	set_tz();

	stop_ntpd();

	if ((nvram_get_int("dnscrypt_proxy")) || (nvram_get_int("stubby_proxy")))
		eval("ntp2ip");

	/* this is the nvram var defining how the server should be run / how often to sync */
	ntp_updates_int = nvram_get_int("ntp_updates");

	/* the Tomato GUI allows the user to select an NTP Server region, and then string concats 1. 2. and 3. as prefix
	 * therefore, the nvram variable contains a string of 3 NTP servers - This code separates them and passes them to
	 * ntpd as separate parameters. this code should continue to work if GUI is changed to only store 1 value in the NVRAM var
	 */
	if (ntp_updates_int >= 0) { /* -1 = never */
		servers_len = strlen(nvram_safe_get("ntp_server"));

		/* allocating memory dynamically both so we don't waste memory, and in case of unanticipatedly long server name in nvram */
		if ((servers = malloc(servers_len + 1)) == NULL) {
			logmsg(LOG_ERR, "ntpd: failed allocating memory, exiting");
			return; /* just get out if we couldn't allocate memory */
		}
		memset(servers, 0, sizeof(servers));

		/* get the space separated list of ntp servers */
		strcpy(servers, nvram_safe_get("ntp_server"));

		/* put the servers into the ntp config file */
		if ((f = fopen("/etc/ntp.conf", "w")) != NULL) {
			ptr = strtok(servers, " ");
			while(ptr) {
				fprintf(f, "server %s\n", ptr);
				ptr = strtok(NULL, " ");
			}
			fclose(f);
		}
		else {
			perror("/etc/ntp.conf");
			return;
		}

		free(servers);

		if (nvram_contains_word("log_events", "ntp")) /* add verbose (doesn't work right now) */
			ntpd_argv[index++] = "-d6";

		if (ntp_updates_int == 0) /* only at startup, then quit */
			ntpd_argv[index++] = "-q";
		else if (ntp_updates_int >= 1) { /* auto adjusted timing by ntpd since it doesn't currently implement minpoll and maxpoll */
			ntpd_argv[index++] = "-S";
			ntpd_argv[index++] = "/sbin/ntpd_synced";

			if (nvram_get_int("ntpd_enable")) /* enable local NTP server */
				ntpd_argv[index++] = "-l";
		}

		ret = _eval(ntpd_argv, NULL, 0, &pid);
		if (ret)
			logmsg(LOG_ERR, "starting ntpd failed ...");
		else
			logmsg(LOG_INFO, "ntpd is started");
	}
}

void stop_ntpd(void)
{
	if (getpid() != 1) {
		stop_service("ntpd");
		return;
	}

	if (pidof("ntpd") > 0) {
		killall_tk_period_wait("ntpd", 50);
		logmsg(LOG_INFO, "ntpd is stopped");
	}
}

int ntpd_synced_main(int argc, char *argv[])
{
	if (!nvram_match("ntp_ready", "1") && (argc == 2 && !strcmp(argv[1], "step"))) {
		nvram_set("ntp_ready", "1");
		logmsg(LOG_INFO, "initial clock set");

		start_httpd();
		start_sched();
		start_ddns();
#ifdef TCONFIG_DNSCRYPT
		start_dnscrypt();
#endif
#ifdef TCONFIG_STUBBY
		start_stubby();
#endif
#ifdef TCONFIG_DNSSEC
		if (nvram_get_int("dnssec_enable"))
			reload_dnsmasq();
#endif
#ifdef TCONFIG_OPENVPN
		start_ovpn_eas();
#endif
#ifdef TCONFIG_MDNS
		start_mdns();
#endif
	}

	return 0;
}

static void stop_rstats(void)
{
	int n, m;
	int pid;
	int pidz;
	int ppidz;
	int w = 0;

	n = 60;
	m = 15;
	while ((n-- > 0) && ((pid = pidof("rstats")) > 0)) {
		w = 1;
		pidz = pidof("gzip");
		if (pidz < 1)
			pidz = pidof("cp");

		ppidz = ppid(ppid(pidz));
		if ((m > 0) && (pidz > 0) && (pid == ppidz)) {
			logmsg(LOG_DEBUG, "*** %s: (PID %d) shutting down, waiting for helper process to complete (PID %d, PPID %d)", __FUNCTION__, pid, pidz, ppidz);
			--m;
		}
		else
			kill(pid, SIGTERM);

		sleep(1);
	}
	if ((w == 1) && (n > 0))
		logmsg(LOG_INFO, "rstats stopped");
}

static void start_rstats(int new)
{
	if (nvram_get_int("rstats_enable")) {
		stop_rstats();
		if (new)
			xstart("rstats", "--new");
		else
			xstart("rstats");

		logmsg(LOG_INFO, "starting rstats%s", (new ? " (new datafile)" : ""));
	}
}

static void stop_cstats(void)
{
	int n, m;
	int pid;
	int pidz;
	int ppidz;
	int w = 0;

	n = 60;
	m = 15;
	while ((n-- > 0) && ((pid = pidof("cstats")) > 0)) {
		w = 1;
		pidz = pidof("gzip");
		if (pidz < 1)
			pidz = pidof("cp");

		ppidz = ppid(ppid(pidz));
		if ((m > 0) && (pidz > 0) && (pid == ppidz)) {
			logmsg(LOG_DEBUG, "*** %s: (PID %d) shutting down, waiting for helper process to complete (PID %d, PPID %d)", __FUNCTION__, pid, pidz, ppidz);
			--m;
		}
		else
			kill(pid, SIGTERM);

		sleep(1);
	}
	if ((w == 1) && (n > 0))
		logmsg(LOG_INFO, "cstats stopped");
}

static void start_cstats(int new)
{
	if (nvram_get_int("cstats_enable")) {
		stop_cstats();
		if (new)
			xstart("cstats", "--new");
		else
			xstart("cstats");

		logmsg(LOG_INFO, "starting cstats%s", (new ? " (new datafile)" : ""));
	}
}

#ifdef TCONFIG_FTP
static char *get_full_storage_path(char *val)
{
	static char buf[128];
	int len;

	memset(buf, 0, 128);

	if (val[0] == '/')
		len = sprintf(buf, "%s", val);
	else
		len = sprintf(buf, "%s/%s", MOUNT_ROOT, val);

	if (len > 1 && buf[len - 1] == '/')
		buf[len - 1] = 0;

	return buf;
}

static char *nvram_storage_path(char *var)
{
	char *val = nvram_safe_get(var);

	return get_full_storage_path(val);
}

static void start_ftpd(void)
{
	char tmp[256];
	FILE *fp, *f;
	char *buf;
	char *p, *q;
	char *user, *pass, *rights, *root_dir;
	int i;
#ifdef TCONFIG_HTTPS
	unsigned long long sn;
	char t[32];
#endif

	if (!nvram_get_int("ftp_enable"))
		return;

	if (getpid() != 1) {
		start_service("ftpd");
		return;
	}

	mkdir_if_none(vsftpd_users);
	mkdir_if_none("/var/run/vsftpd");

	if ((fp = fopen(vsftpd_conf, "w")) == NULL) {
		perror(vsftpd_conf);
		return;
	}

	if (nvram_get_int("ftp_super")) {
		/* rights */
		memset(tmp, 0, 256);
		sprintf(tmp, "%s/%s", vsftpd_users, "admin");
		if ((f = fopen(tmp, "w")) != NULL) {
			fprintf(f, "dirlist_enable=yes\n"
			           "write_enable=yes\n"
			           "download_enable=yes\n");
			fclose(f);
		}
		else {
			perror(tmp);
			return;
		}
	}

	if (nvram_invmatch("ftp_anonymous", "0")) {
		fprintf(fp, "anon_allow_writable_root=yes\n"
		            "anon_world_readable_only=no\n"
		            "anon_umask=022\n");

		/* rights */
		memset(tmp, 0, 256);
		sprintf(tmp, "%s/ftp", vsftpd_users);
		if ((f = fopen(tmp, "w")) != NULL) {
			if (nvram_match("ftp_dirlist", "0"))
				fprintf(f, "dirlist_enable=yes\n");
			if ((nvram_match("ftp_anonymous", "1")) || (nvram_match("ftp_anonymous", "3")))
				fprintf(f, "write_enable=yes\n");
			if ((nvram_match("ftp_anonymous", "1")) || (nvram_match("ftp_anonymous", "2")))
				fprintf(f, "download_enable=yes\n");
			fclose(f);
		}
		else {
			perror(tmp);
			return;
		}

		if ((nvram_match("ftp_anonymous", "1")) || (nvram_match("ftp_anonymous", "3")))
			fprintf(fp, "anon_upload_enable=yes\n"
			            "anon_mkdir_write_enable=yes\n"
			            "anon_other_write_enable=yes\n");
	}
	else
		fprintf(fp, "anonymous_enable=no\n");

	fprintf(fp, "dirmessage_enable=yes\n"
	            "download_enable=no\n"
	            "dirlist_enable=no\n"
	            "hide_ids=yes\n"
	            "syslog_enable=yes\n"
	            "local_enable=yes\n"
	            "local_umask=022\n"
	            "chmod_enable=no\n"
	            "chroot_local_user=yes\n"
	            "check_shell=no\n"
	            "log_ftp_protocol=%s\n"
	            "user_config_dir=%s\n"
	            "passwd_file=%s\n"
	            "listen%s=yes\n"
	            "listen%s=no\n"
	            "listen_port=%s\n"
	            "background=yes\n"
#ifndef TCONFIG_BCMARM
	            "isolate=no\n"
#endif
	            "max_clients=%d\n"
	            "max_per_ip=%d\n"
	            "max_login_fails=1\n"
	            "idle_session_timeout=%s\n"
	            "use_sendfile=no\n"
	            "anon_max_rate=%d\n"
	            "local_max_rate=%d\n",
	            nvram_get_int("log_ftp") ? "yes" : "no",
	            vsftpd_users, vsftpd_passwd,
#ifdef TCONFIG_IPV6
	            ipv6_enabled() ? "_ipv6" : "",
	            ipv6_enabled() ? "" : "_ipv6",
#else
	            "",
	            "_ipv6",
#endif
	            nvram_get("ftp_port") ? : "21",
	            nvram_get_int("ftp_max"),
	            nvram_get_int("ftp_ipmax"),
	            nvram_get("ftp_staytimeout") ? : "300",
	            nvram_get_int("ftp_anonrate") * 1024,
	            nvram_get_int("ftp_rate") * 1024);

#ifdef TCONFIG_HTTPS
	if (nvram_get_int("ftp_tls")) {
		fprintf(fp, "ssl_enable=YES\n"
		            "rsa_cert_file=/etc/cert.pem\n"
		            "rsa_private_key_file=/etc/key.pem\n"
		            "allow_anon_ssl=NO\n"
		            "force_local_data_ssl=YES\n"
		            "force_local_logins_ssl=YES\n"
		            "ssl_tlsv1=YES\n"
		            "ssl_sslv2=NO\n"
		            "ssl_sslv3=NO\n"
		            "require_ssl_reuse=NO\n"
		            "ssl_ciphers=HIGH\n");

		/* does a valid HTTPD cert exist? if not, generate one */
		if ((!f_exists("/etc/cert.pem")) || (!f_exists("/etc/key.pem"))) {
			f_read("/dev/urandom", &sn, sizeof(sn));
			sprintf(t, "%llu", sn & 0x7FFFFFFFFFFFFFFFULL);
			nvram_set("https_crt_gen", "1");
			nvram_set("https_crt_save", "1");
			eval("gencert.sh", t);
		}
	}
#endif /* TCONFIG_HTTPS */

	fprintf(fp, "ftpd_banner=Welcome to FreshTomato %s FTP service.\n"
	            "%s\n",
	            nvram_safe_get("os_version"),
	            nvram_safe_get("ftp_custom"));

	fclose(fp);

	/* prepare passwd file and default users */
	if ((fp = fopen(vsftpd_passwd, "w")) == NULL) {
		perror(vsftpd_passwd);
		return;
	}

	if ((user = nvram_safe_get("http_username")) && (!*user))
		user = "admin";
	if ((pass = nvram_safe_get("http_passwd")) && (!*pass))
		pass = "admin";

	/* anonymous, admin, nobody */
	fprintf(fp, "ftp:x:0:0:ftp:%s:/sbin/nologin\n"
	            "%s:%s:0:0:root:/:/sbin/nologin\n"
	            "nobody:x:65534:65534:nobody:%s/:/sbin/nologin\n",
	            nvram_storage_path("ftp_anonroot"), user,
	            nvram_get_int("ftp_super") ? crypt(pass, "$1$") : "x",
	            MOUNT_ROOT);

	if ((buf = strdup(nvram_safe_get("ftp_users"))) && (*buf)) {
		/*
		 * username<password<rights[<root_dir>]
		 * rights:
		 *  Read/Write
		 *  Read Only
		 *  View Only
		 *  Private
		 */
		p = buf;
		while ((q = strsep(&p, ">")) != NULL) {
			i = vstrsep(q, "<", &user, &pass, &rights, &root_dir);
			if (i < 3)
				continue;
			if ((!user) || (!pass))
				continue;

			if ((i == 3) || (!root_dir) || (!(*root_dir)))
				root_dir = nvram_safe_get("ftp_pubroot");

			/* directory */
			memset(tmp, 0, 256);
			if (strncmp(rights, "Private", 7) == 0) {
				sprintf(tmp, "%s/%s", nvram_storage_path("ftp_pvtroot"), user);
				mkdir_if_none(tmp);
			}
			else
				sprintf(tmp, "%s", get_full_storage_path(root_dir));

			fprintf(fp, "%s:%s:0:0:%s:%s:/sbin/nologin\n", user, crypt(pass, "$1$"), user, tmp);

			/* rights */
			memset(tmp, 0, 256);
			sprintf(tmp, "%s/%s", vsftpd_users, user);
			if ((f = fopen(tmp, "w")) != NULL) {
				tmp[0] = 0;
				if (nvram_invmatch("ftp_dirlist", "1"))
					strcat(tmp, "dirlist_enable=yes\n");
				if ((strstr(rights, "Read")) || (!strcmp(rights, "Private")))
					strcat(tmp, "download_enable=yes\n");
				if ((strstr(rights, "Write")) || (!strncmp(rights, "Private", 7)))
					strcat(tmp, "write_enable=yes\n");

				fputs(tmp, f);
				fclose(f);
			}
			else {
				perror(tmp);
				return;
			}
		}
		free(buf);
	}

	fclose(fp);
	killall("vsftpd", SIGHUP);

	/* start vsftpd if it's not already running */
	if (pidof("vsftpd") <= 0) {
		int ret;

		ret = eval("vsftpd");
		if (ret)
			logmsg(LOG_ERR, "starting vsftpd failed ...");
		else
			logmsg(LOG_INFO, "vsftpd is started");
	}
}

static void stop_ftpd(void)
{
	if (getpid() != 1) {
		stop_service("ftpd");
		return;
	}

	if (pidof("vsftpd") > 0) {
		killall_tk_period_wait("vsftpd", 50);
		unlink(vsftpd_passwd);
		unlink(vsftpd_conf);
		eval("rm", "-rf", vsftpd_users);

		logmsg(LOG_INFO, "vsftpd is stopped");
	}
}
#endif /* TCONFIG_FTP */

#ifdef TCONFIG_SAMBASRV
static void kill_samba(int sig)
{
	if (sig == SIGTERM) {
		killall_tk_period_wait("smbd", 50);
		killall_tk_period_wait("nmbd", 50);
	}
	else {
		killall("smbd", sig);
		killall("nmbd", sig);
	}
}

#if defined(TCONFIG_BCMARM) && defined(TCONFIG_GROCTRL)
void enable_gro(int interval)
{
	char *argv[3] = { "echo", "", NULL };
	char lan_ifname[32], *lan_ifnames, *next;
	char path[64];
	char parm[32];

	if(nvram_get_int("gro_disable"))
		return;

	/* enabled gro on vlan interface */
	lan_ifnames = nvram_safe_get("lan_ifnames");
	foreach(lan_ifname, lan_ifnames, next) {
		if (!strncmp(lan_ifname, "vlan", 4)) {
			memset(path, 0, 64);
			sprintf(path, ">>/proc/net/vlan/%s", lan_ifname);
			memset(parm, 0, 32);
			sprintf(parm, "-gro %d", interval);
			argv[1] = parm;
			_eval(argv, path, 0, NULL);
		}
	}
}
#endif

void start_samba(void)
{
	FILE *fp;
	DIR *dir = NULL;
	struct dirent *dp;
	char nlsmod[16];
	int mode;
	char *nv;
	char *si;
	char *buf;
	char *p, *q;
	char *name, *path, *comment, *writeable, *hidden;
	int cnt = 0;
	char *smbd_user;
	int ret1 = 0, ret2 = 0;
#if defined(TCONFIG_BCMARM) && defined(TCONFIG_BCMSMP)
	int cpu_num = sysconf(_SC_NPROCESSORS_CONF);
	int taskset_ret = -1;
#endif

	mode = nvram_get_int("smbd_enable");
	if ((!mode) || (!nvram_invmatch("lan_hostname", "")))
		return;

	if (getpid() != 1) {
		start_service("smbd");
		return;
	}

	if ((fp = fopen("/etc/smb.conf", "w")) == NULL) {
		perror("/etc/smb.conf");
		return;
	}

#ifdef TCONFIG_BCMARM
	/* check samba enabled ? */
	if (mode)
		nvram_set("txworkq", "1"); /* set txworkq to 1, see et/sys/et_linux.c */
	else
		nvram_unset("txworkq");

#ifdef TCONFIG_GROCTRL
	/* enable / disable gro via GUI nas-samba.asp; Default: off */
	enable_gro(2);
#endif
#endif

	si = nvram_safe_get("smbd_ifnames");

	fprintf(fp, "[global]\n"
	            " interfaces = %s\n"
	            " bind interfaces only = yes\n"
	            " enable core files = no\n"
	            " deadtime = 30\n"
	            " smb encrypt = disabled\n"
	            " min receivefile size = 16384\n"
	            " workgroup = %s\n"
	            " netbios name = %s\n"
	            " server string = %s\n"
	            " dos charset = ASCII\n"
	            " unix charset = UTF8\n"
	            " display charset = UTF8\n"
	            " guest account = nobody\n"
	            " security = user\n"
	            " %s\n"
	            " guest ok = %s\n"
	            " guest only = no\n"
	            " browseable = yes\n"
	            " syslog only = yes\n"
	            " timestamp logs = no\n"
	            " syslog = 1\n"
	            " passdb backend = smbpasswd\n"
	            " encrypt passwords = yes\n"
	            " preserve case = yes\n"
	            " short preserve case = yes\n",
	            strlen(si) ? si : nvram_safe_get("lan_ifname"),
	            nvram_get("smbd_wgroup") ? : "WORKGROUP",
	            nvram_safe_get("lan_hostname"),
	            nvram_get("router_name") ? : "FreshTomato",
	            mode == 2 ? "" : "map to guest = Bad User",
	            mode == 2 ? "no" : "yes"); /* guest ok */

	fprintf(fp, " load printers = no\n" /* add for Samba printcap issue */
	            " printing = bsd\n"
	            " printcap name = /dev/null\n"
	            " map archive = no\n"
	            " map hidden = no\n"
	            " map read only = no\n"
	            " map system = no\n"
	            " store dos attributes = no\n"
	            " dos filemode = yes\n"
	            " strict locking = no\n"
	            " oplocks = yes\n"
	            " level2 oplocks = yes\n"
	            " kernel oplocks = no\n"
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,36)
	            " use sendfile = no\n");
#else
	            " use sendfile = yes\n");
#endif

	if (nvram_get_int("smbd_wins")) {
		nv = nvram_safe_get("wan_wins");
		if ((!*nv) || (strcmp(nv, "0.0.0.0") == 0))
			fprintf(fp, " wins support = yes\n");
	}

	/* 0 - smb1, 1 - smb2, 2 - smb1 + smb2 */
	if (nvram_get_int("smbd_protocol") == 0)
		fprintf(fp, " max protocol = NT1\n");
	else
		fprintf(fp, " max protocol = SMB2\n");
	if (nvram_get_int("smbd_protocol") == 1)
		fprintf(fp, " min protocol = SMB2\n");

	if (nvram_get_int("smbd_master")) {
		fprintf(fp,
			" domain master = yes\n"
			" local master = yes\n"
			" preferred master = yes\n"
			" os level = 255\n");
	}

	nv = nvram_safe_get("smbd_cpage");
	if (*nv) {
		memset(nlsmod, 0, 16);
		sprintf(nlsmod, "nls_cp%s", nv);

		nv = nvram_safe_get("smbd_nlsmod");
		if ((*nv) && (strcmp(nv, nlsmod) != 0))
			modprobe_r(nv);

		modprobe(nlsmod);
		nvram_set("smbd_nlsmod", nlsmod);
	}

	nv = nvram_safe_get("smbd_custom");
	/* add socket options unless overriden by the user */
	if (strstr(nv, "socket options") == NULL)
		fprintf(fp, " socket options = TCP_NODELAY SO_KEEPALIVE IPTOS_LOWDELAY SO_RCVBUF=65536 SO_SNDBUF=65536\n");

	fprintf(fp, "%s\n", nv);

	/* configure shares */
	if ((buf = strdup(nvram_safe_get("smbd_shares"))) && (*buf)) {
		/* sharename<path<comment<writeable[0|1]<hidden[0|1] */

		p = buf;
		while ((q = strsep(&p, ">")) != NULL) {
			if (vstrsep(q, "<", &name, &path, &comment, &writeable, &hidden) < 5)
				continue;
			if (!path || !name)
				continue;

			/* share name */
			fprintf(fp, "\n[%s]\n", name);

			/* path */
			fprintf(fp, " path = %s\n", path);

			/* access level */
			if (!strcmp(writeable, "1"))
				fprintf(fp, " writable = yes\n delete readonly = yes\n force user = root\n");
			if (!strcmp(hidden, "1"))
				fprintf(fp, " browseable = no\n");

			/* comment */
			if (comment)
				fprintf(fp, " comment = %s\n", comment);

			cnt++;
		}
		free(buf);
	}

	/* share every mountpoint below MOUNT_ROOT */
	if (nvram_get_int("smbd_autoshare") && (dir = opendir(MOUNT_ROOT))) {
		while ((dp = readdir(dir))) {
			if (strcmp(dp->d_name, ".") && strcmp(dp->d_name, "..")) {

				/* only if is a directory and is mounted */
				if (!dir_is_mountpoint(MOUNT_ROOT, dp->d_name))
					continue;

				/* smbd_autoshare: 0 - disable, 1 - read-only, 2 - writable, 3 - hidden writable */
				fprintf(fp, "\n[%s]\n path = %s/%s\n comment = %s\n", dp->d_name, MOUNT_ROOT, dp->d_name, dp->d_name);

				if (nvram_match("smbd_autoshare", "3")) /* hidden */
					fprintf(fp, "\n[%s$]\n path = %s/%s\n browseable = no\n", dp->d_name, MOUNT_ROOT, dp->d_name);

				if ((nvram_match("smbd_autoshare", "2")) || (nvram_match("smbd_autoshare", "3"))) /* RW */
					fprintf(fp, " writable = yes\n delete readonly = yes\n force user = root\n");

				cnt++;
			}
		}
	}
	if (dir)
		closedir(dir);

	if (cnt == 0) {
		/* by default share MOUNT_ROOT as read-only */
		fprintf(fp, "\n[share]\n"
		            " path = %s\n"
		            " writable = no\n",
		            MOUNT_ROOT);
	}

	fclose(fp);

	mkdir_if_none("/var/run/samba");
	mkdir_if_none("/etc/samba");

	/* write smbpasswd */
	eval("smbpasswd", "nobody", "\"\"");

	if (mode == 2) {
		smbd_user = nvram_safe_get("smbd_user");
		if ((!*smbd_user) || (!strcmp(smbd_user, "root")))
			smbd_user = "nas";

		eval("smbpasswd", smbd_user, nvram_safe_get("smbd_passwd"));
	}

	kill_samba(SIGHUP);

	/* start samba if it's not already running */
	if (pidof("nmbd") <= 0)
		ret1 = xstart("nmbd", "-D");

	if (pidof("smbd") <= 0) {
#if defined(TCONFIG_BCMARM) && defined(TCONFIG_BCMSMP)
		if (cpu_num > 1)
			taskset_ret = cpu_eval(NULL, "1", "ionice", "-c1", "-n0", "smbd", "-D");
		else
			taskset_ret = eval("ionice", "-c1", "-n0", "smbd", "-D");

		if (taskset_ret != 0)
#endif
		ret2 = xstart("smbd", "-D");
	}

	if (ret1 || ret2) {
		kill_samba(SIGTERM);
		logmsg(LOG_ERR, "starting Samba daemon failed ...");
	}
	else {
		start_wsdd();
		logmsg(LOG_INFO, "Samba daemon is started");
	}
}

void stop_samba(void)
{
	if (getpid() != 1) {
		stop_service("smbd");
		return;
	}

	stop_wsdd();

	if ((pidof("smbd") > 0 ) || (pidof("nmbd") > 0 )) {
		kill_samba(SIGTERM);

		/* clean up */
		unlink("/var/log/log.smbd");
		unlink("/var/log/log.nmbd");
		eval("rm", "-rf", "/var/nmbd");
		eval("rm", "-rf", "/var/log/cores");
		eval("rm", "-rf", "/var/run/samba");
#if defined(TCONFIG_BCMARM) && defined(TCONFIG_GROCTRL)
		enable_gro(0);
#endif
		logmsg(LOG_INFO, "Samba daemon is stopped");
	}
}

void start_wsdd()
{
	unsigned char ea[ETHER_ADDR_LEN];
	char serial[18];
	pid_t pid;
	char bootparms[64];
	char *wsdd_argv[] = { "/usr/sbin/wsdd2",
	                      "-d",
	                      "-w",
	                      "-i", /* no multi-interface binds atm */
	                      nvram_safe_get("lan_ifname"),
	                      "-b",
	                      NULL, /* boot parameters */
	                      NULL
	                    };
	stop_wsdd();

	if (!ether_atoe(nvram_safe_get("lan_hwaddr"), ea))
		f_read("/dev/urandom", ea, sizeof(ea));

	snprintf(serial, sizeof(serial), "%02x%02x%02x%02x%02x%02x", ea[0], ea[1], ea[2], ea[3], ea[4], ea[5]);

	snprintf(bootparms, sizeof(bootparms), "sku:%s,serial:%s", (nvram_get("odmpid") ? : "FreshTomato"), serial);
	wsdd_argv[6] = bootparms;

	_eval(wsdd_argv, NULL, 0, &pid);
}

void stop_wsdd() {
	killall_tk_period_wait("wsdd2", 50);
}
#endif /* TCONFIG_SAMBASRV */

#ifdef TCONFIG_MEDIA_SERVER
static void start_media_server(void)
{
	FILE *f;
	int port, pid, https;
	char *dbdir;
	char *argv[] = { MEDIA_SERVER_APP, "-f", "/etc/"MEDIA_SERVER_APP".conf", "-r", NULL, NULL };
	static int once = 1;
	int index = 4;
	char *msi;
	unsigned char ea[ETHER_ADDR_LEN];
	char serial[18], uuid[37];
	char *buf, *p, *q;
	char *path, *restrict;

	if (!nvram_get_int("ms_enable"))
		return;

	if (getpid() != 1) {
		start_service("media");
		return;
	}

	if (!nvram_get_int("ms_sas")) {
		once = 0;
		argv[index - 1] = NULL;
	}

	if (nvram_get_int("ms_rescan")) { /* force rebuild */
		argv[index - 1] = "-R";
		nvram_unset("ms_rescan");
	}

	if (f_exists("/etc/"MEDIA_SERVER_APP".alt"))
		argv[2] = "/etc/"MEDIA_SERVER_APP".alt";
	else {
		if ((f = fopen(argv[2], "w")) != NULL) {
			port = nvram_get_int("ms_port");
			https = nvram_get_int("https_enable");
			msi = nvram_safe_get("ms_ifname");
			dbdir = nvram_safe_get("ms_dbdir");
			if (!(*dbdir))
				dbdir = NULL;

			mkdir_if_none(dbdir ? : "/var/run/"MEDIA_SERVER_APP);

			/* persistent ident (router's mac as serial) */
			if (!ether_atoe(nvram_safe_get("et0macaddr"), ea))
				f_read("/dev/urandom", ea, sizeof(ea));

			snprintf(serial, sizeof(serial), "%02x:%02x:%02x:%02x:%02x:%02x", ea[0], ea[1], ea[2], ea[3], ea[4], ea[5]);
			snprintf(uuid, sizeof(uuid), "4d696e69-444c-164e-9d41-%02x%02x%02x%02x%02x%02x", ea[0], ea[1], ea[2], ea[3], ea[4], ea[5]);

			fprintf(f, "network_interface=%s\n"
			           "port=%d\n"
			           "friendly_name=%s\n"
			           "db_dir=%s/.db\n"
			           "enable_tivo=%s\n"
			           "strict_dlna=%s\n"
			           "presentation_url=http%s://%s:%s/nas-media.asp\n"
			           "inotify=yes\n"
			           "notify_interval=600\n"
			           "album_art_names=Cover.jpg/cover.jpg/Album.jpg/album.jpg/Folder.jpg/folder.jpg/Thumb.jpg/thumb.jpg\n"
			           "log_dir=/var/log\n"
			           "log_level=general,artwork,database,inotify,scanner,metadata,http,ssdp,tivo=warn\n"
			           "serial=%s\n"
			           "uuid=%s\n"
			           "model_number=%s\n\n",
			           strlen(msi) ? msi : nvram_safe_get("lan_ifname"),
			           (port < 0) || (port >= 0xffff) ? 0 : port,
			           nvram_get("router_name") ? : "FreshTomato",
			           dbdir ? : "/var/run/"MEDIA_SERVER_APP,
			           nvram_get_int("ms_tivo") ? "yes" : "no",
			           nvram_get_int("ms_stdlna") ? "yes" : "no",
			           https ? "s" : "", nvram_safe_get("lan_ipaddr"), nvram_safe_get(https ? "https_lanport" : "http_lanport"),
			           serial, uuid, nvram_safe_get("os_version"));

			/* media directories */
			if ((buf = strdup(nvram_safe_get("ms_dirs"))) && (*buf)) {
				/* path<restrict[A|V|P|] */
				p = buf;
				while ((q = strsep(&p, ">")) != NULL) {
					if ((vstrsep(q, "<", &path, &restrict) < 1) || (!path) || (!*path))
						continue;

					fprintf(f, "media_dir=%s%s%s\n",
						restrict ? : "", (restrict && *restrict) ? "," : "", path);
				}
				free(buf);
			}
			fclose(f);
		}
		else {
			perror(argv[2]);
			return;
		}
	}

	if (nvram_get_int("ms_debug"))
		argv[index++] = "-v";

	/* start media server if it's not already running */
	if (pidof(MEDIA_SERVER_APP) <= 0) {
		if ((_eval(argv, NULL, 0, &pid) == 0) && (once)) {
			/* if we started the media server successfully, wait 1 sec
			 * to let it die if it can't open the database file.
			 * if it's still alive after that, assume it's running and
			 * disable forced once-after-reboot rescan.
			 */
			sleep(1);
			if (pidof(MEDIA_SERVER_APP) > 0)
				once = 0;
			else {
				logmsg(LOG_ERR, "starting "MEDIA_SERVER_APP" failed ...");
				return;
			}
		}
	}
	logmsg(LOG_INFO, MEDIA_SERVER_APP" is started");
}

static void stop_media_server(void)
{
	if (getpid() != 1) {
		stop_service("media");
		return;
	}

	if (pidof(MEDIA_SERVER_APP) > 0) {
		killall_tk_period_wait(MEDIA_SERVER_APP, 50);

		logmsg(LOG_INFO, MEDIA_SERVER_APP" is stopped");
	}
}
#endif /* TCONFIG_MEDIA_SERVER */

#ifdef TCONFIG_USB
static void start_nas_services(void)
{
	if (g_upgrade)
		return;

	if (getpid() != 1) {
		start_service("usbapps");
		return;
	}

#ifdef TCONFIG_SAMBASRV
	start_samba();
#endif
#ifdef TCONFIG_FTP
	start_ftpd();
#endif
#ifdef TCONFIG_MEDIA_SERVER
	start_media_server();
#endif
}

static void stop_nas_services(void)
{
	if (getpid() != 1) {
		stop_service("usbapps");
		return;
	}

#ifdef TCONFIG_MEDIA_SERVER
	stop_media_server();
#endif
#ifdef TCONFIG_FTP
	stop_ftpd();
#endif
#ifdef TCONFIG_SAMBASRV
	stop_samba();
#endif
}

void restart_nas_services(int stop, int start)
{
	int fd = file_lock("usb");
	/* restart all NAS applications */
	if (stop)
		stop_nas_services();
	if (start && !g_upgrade)
		start_nas_services();

	file_unlock(fd);
}
#endif /* TCONFIG_USB */

/* -1 = Don't check for this program, it is not expected to be running.
 * Other = This program has been started and should be kept running.  If no
 * process with the name is running, call func to restart it.
 * Note: At startup, dnsmasq forks a short-lived child which forks a
 * long-lived (grand)child.  The parents terminate.
 * Many daemons use this technique.
 */
static void _check(pid_t pid, const char *name, void (*func)(void))
{
	if (pid == -1)
		return;

	if (pidof(name) > 0)
		return;

	logmsg(LOG_ERR, "%s terminated unexpectedly, restarting", name);
	func();

	/* force recheck in 500 msec */
	setitimer(ITIMER_REAL, &pop_tv, NULL);
}

void check_services(void)
{
	/* periodically reap any zombies */
	setitimer(ITIMER_REAL, &zombie_tv, NULL);

	/* do not restart if upgrading */
	if (!g_upgrade) {
		_check(pid_hotplug2, "hotplug2", start_hotplug2);
		_check(pid_dnsmasq, "dnsmasq", start_dnsmasq);
		_check(pid_crond, "crond", start_cron);
		_check(pid_igmp, "igmpproxy", start_igmp_proxy);
	}
}

void start_services(void)
{
	static int once = 1;

	if (once) {
		once = 0;

		if (nvram_get_int("telnetd_eas"))
			start_telnetd();
		if (nvram_get_int("sshd_eas"))
			start_sshd();
	}
	start_nas();
#ifdef TCONFIG_ZEBRA
	start_zebra();
#endif
#ifdef TCONFIG_SDHC
	start_mmc();
#endif
	start_dnsmasq();
#ifdef TCONFIG_MDNS
	start_mdns();
#endif
	start_cifs();
	start_httpd();
#ifdef TCONFIG_NGINX
	start_nginx();
	start_mysql();
#endif
	start_cron();
	start_rstats(0);
	start_cstats(0);
#ifdef TCONFIG_PPTPD
	start_pptpd();
#endif
#ifdef TCONFIG_USB
	restart_nas_services(1, 1); /* Samba, FTP and Media Server */
#endif
#ifdef TCONFIG_SNMP
	start_snmp();
#endif
	start_tomatoanon();
#ifdef TCONFIG_TOR
	start_tor();
#endif
#ifdef TCONFIG_BT
	start_bittorrent();
#endif
#ifdef TCONFIG_NOCAT
	start_nocat();
#endif
#ifdef TCONFIG_NFS
	start_nfs();
#endif
#ifdef TCONFIG_BCMARM
	/* do LED setup for Router */
	led_setup();
#endif
#ifdef TCONFIG_FANCTRL
	start_phy_tempsense();
#endif
#ifdef CONFIG_BCM7
	if (!nvram_get_int("debug_wireless")) { /* suppress dhd debug messages (default 0x01) */
		system("/usr/sbin/dhd -i eth1 msglevel 0x00");
		system("/usr/sbin/dhd -i eth2 msglevel 0x00");
		system("/usr/sbin/dhd -i eth3 msglevel 0x00");
	}
#endif
#ifdef TCONFIG_BCMBSD
	start_bsd();
#endif
#ifdef TCONFIG_IRQBALANCE
	start_irqbalance();
#endif
}

void stop_services(void)
{
	clear_resolv();
	stop_ntpd();
#ifdef TCONFIG_FANCTRL
	stop_phy_tempsense();
#endif
#ifdef TCONFIG_BT
	stop_bittorrent();
#endif
#ifdef TCONFIG_NOCAT
	stop_nocat();
#endif
#ifdef TCONFIG_SNMP
	stop_snmp();
#endif
#ifdef TCONFIG_TOR
	stop_tor();
#endif
	stop_tomatoanon();
#ifdef TCONFIG_NFS
	stop_nfs();
#endif
#ifdef TCONFIG_MDNS
	stop_mdns();
#endif
#ifdef TCONFIG_USB
	restart_nas_services(1, 0); /* Samba, FTP and Media Server */
#endif
#ifdef TCONFIG_PPTPD
	stop_pptpd();
#endif
	stop_sched();
	stop_rstats();
	stop_cstats();
	stop_cron();
#ifdef TCONFIG_NGINX
	stop_mysql();
	stop_nginx();
#endif
#ifdef TCONFIG_SDHC
	stop_mmc();
#endif
	stop_cifs();
	stop_httpd();
	stop_dnsmasq();
#ifdef TCONFIG_ZEBRA
	stop_zebra();
#endif
	stop_nas();
#ifdef TCONFIG_BCMBSD
	stop_bsd();
#endif
#ifdef TCONFIG_IRQBALANCE
	stop_irqbalance();
#endif
}

/* nvram "action_service" is: "service-action[-modifier]"
 * action is something like "stop" or "start" or "restart"
 * optional modifier is "c" for the "service" command-line command
 */
void exec_service(void)
{
	const int A_START = 1;
	const int A_STOP = 2;
	const int A_RESTART = 1|2;
	char buffer[128], buffer2[16];
	char *service;
	char *act;
	char *next;
	char *modifier;
	int action, user;
	int i;
	int act_start, act_stop;

	strlcpy(buffer, nvram_safe_get("action_service"), sizeof(buffer));
	next = buffer;

TOP:
	act = strsep(&next, ",");
	service = strsep(&act, "-");
	if (act == NULL) {
		next = NULL;
		goto CLEAR;
	}
	modifier = act;
	action = 0;
	strsep(&modifier, "-");

	if (strcmp(act, "start") == 0)
		action = A_START;
	if (strcmp(act, "stop") == 0)
		action = A_STOP;
	if (strcmp(act, "restart") == 0)
		action = A_RESTART;

	act_start = action & A_START;
	act_stop  = action & A_STOP;

	user = (modifier != NULL && *modifier == 'c');

	if (strcmp(service, "dhcpc-wan") == 0) {
		if (act_stop) stop_dhcpc("wan");
		if (act_start) start_dhcpc("wan");
		goto CLEAR;
	}

	if (strcmp(service, "dhcpc-wan2") == 0) {
		if (act_stop) stop_dhcpc("wan2");
		if (act_start) start_dhcpc("wan2");
		goto CLEAR;
	}

#ifdef TCONFIG_MULTIWAN
	if (strcmp(service, "dhcpc-wan3") == 0) {
		if (act_stop) stop_dhcpc("wan3");
		if (act_start) start_dhcpc("wan3");
		goto CLEAR;
	}

	if (strcmp(service, "dhcpc-wan4") == 0) {
		if (act_stop) stop_dhcpc("wan4");
		if (act_start) start_dhcpc("wan4");
		goto CLEAR;
	}
#endif

	if (strcmp(service, "dnsmasq") == 0) {
		if (act_stop) stop_dnsmasq();
		if (act_start && !g_upgrade) {
			dns_to_resolv();
			start_dnsmasq();
		}
		goto CLEAR;
	}

	if (strcmp(service, "dns") == 0) {
		if (act_start) reload_dnsmasq();
		goto CLEAR;
	}

#ifdef TCONFIG_DNSCRYPT
	if (strcmp(service, "dnscrypt") == 0) {
		if (act_stop) stop_dnscrypt();
		if (act_start) start_dnscrypt();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_STUBBY
	if (strcmp(service, "stubby") == 0) {
		if (act_stop) stop_stubby();
		if (act_start) start_stubby();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_MDNS
	if (strcmp(service, "mdns") == 0) {
		if (act_stop) stop_mdns();
		if (act_start) start_mdns();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_IRQBALANCE
	if (strcmp(service, "irqbalance") == 0) {
		if (act_stop) stop_irqbalance();
		if (act_start) start_irqbalance();
		goto CLEAR;
	}
#endif

	if (strcmp(service, "adblock") == 0) {
		if (act_stop) stop_adblock();
		if (act_start) start_adblock(1); /* update lists immediately */
		goto CLEAR;
	}

	if (strcmp(service, "firewall") == 0) {
		if (act_stop) {
			stop_firewall();
			stop_igmp_proxy();
			stop_udpxy();
		}
		if (act_start) {
			start_firewall();
			start_igmp_proxy();
			start_udpxy();
		}
		goto CLEAR;
	}

	if (strcmp(service, "restrict") == 0) {
		if (act_stop)
			stop_firewall();

		if (act_start) {
			i = nvram_get_int("rrules_radio"); /* -1 = not used, 0 = enabled by rule, 1 = disabled by rule */

			start_firewall();

			/* if radio was disabled by access restriction, but no rule is handling it now, enable it */
			if (i == 1) {
				if (nvram_get_int("rrules_radio") < 0)
					eval("radio", "on");
			}
		}
		goto CLEAR;
	}

	if (strcmp(service, "arpbind") == 0) {
		if (act_stop) stop_arpbind();
		if (act_start) start_arpbind();
		goto CLEAR;
	}

	if (strcmp(service, "bwlimit") == 0) {
		if (act_stop) {
			stop_bwlimit();
#ifdef TCONFIG_NOCAT
			stop_nocat();
#endif
		}
		stop_firewall();
		start_firewall(); /* always restarted */
		if (act_start) {
			start_bwlimit();
#ifdef TCONFIG_NOCAT
			start_nocat();
#endif
		}
		goto CLEAR;
	}

	if (strcmp(service, "qos") == 0) {
		if (act_stop) {
			stop_qos("wan");
			stop_qos("wan2");
#ifdef TCONFIG_MULTIWAN
			stop_qos("wan3");
			stop_qos("wan4");
#endif
		}
		stop_firewall();
		start_firewall(); /* always restarted */
		if (act_start) {
			start_qos("wan");
			if (check_wanup("wan2"))
				start_qos("wan2");
#ifdef TCONFIG_MULTIWAN
			if (check_wanup("wan3"))
				start_qos("wan3");
			if (check_wanup("wan4"))
				start_qos("wan4");
#endif
			if (nvram_get_int("qos_reset"))
				f_write_string("/proc/net/clear_marks", "1", 0, 0);
		}
		goto CLEAR;
	}

	if (strcmp(service, "upnp") == 0) {
		if (act_stop)
			stop_upnp();
		stop_firewall();
		start_firewall(); /* always restarted */
		if (act_start)
			start_upnp();
		goto CLEAR;
	}

	if (strcmp(service, "telnetd") == 0) {
		if (act_stop) stop_telnetd();
		if (act_start) start_telnetd();
		goto CLEAR;
	}

	if (strcmp(service, "sshd") == 0) {
		if (act_stop) stop_sshd();
		if (act_start) start_sshd();
		goto CLEAR;
	}

	if (strcmp(service, "httpd") == 0) {
		if (act_stop) stop_httpd();
		if (act_start) start_httpd();
		goto CLEAR;
	}

#ifdef TCONFIG_IPV6
	if (strcmp(service, "dhcp6") == 0) {
		if (act_stop) stop_dhcp6c();
		if (act_start) start_dhcp6c();
		goto CLEAR;
	}
#endif

	if (strncmp(service, "admin", 5) == 0) {
		if (act_stop) {
			if (!(strcmp(service, "adminnosshd") == 0))
				stop_sshd();
			stop_telnetd();
			stop_httpd();
		}
		stop_firewall();
		start_firewall(); /* always restarted */
		if (act_start) {
			start_httpd();
			if (!(strcmp(service, "adminnosshd") == 0))
				create_passwd();
			if (nvram_get_int("telnetd_eas"))
				start_telnetd();
			if (nvram_get_int("sshd_eas") && (!(strcmp(service, "adminnosshd") == 0)))
				start_sshd();
		}
		goto CLEAR;
	}

	if (strcmp(service, "ddns") == 0) {
		if (act_stop) stop_ddns();
		if (act_start) start_ddns();
		goto CLEAR;
	}

	if (strcmp(service, "ntpd") == 0) {
		if (act_stop) stop_ntpd();
		if (act_start) start_ntpd();
		goto CLEAR;
	}

	if (strcmp(service, "logging") == 0) {
		if (act_stop) stop_syslog();
		if (act_start) start_syslog();
		if (!user) {
			/* always restarted except from "service" command */
			stop_cron();
			start_cron();
			stop_firewall();
			start_firewall();
		}
		goto CLEAR;
	}

	if (strcmp(service, "crond") == 0) {
		if (act_stop) stop_cron();
		if (act_start) start_cron();
		goto CLEAR;
	}

	if (strcmp(service, "hotplug") == 0) {
		if (act_stop) stop_hotplug2();
		if (act_start) start_hotplug2(1);
		goto CLEAR;
	}

	if (strcmp(service, "upgrade") == 0) {
		if (act_start) {
			g_upgrade = 1;
			stop_sched();
			stop_cron();
#ifdef TCONFIG_USB
			restart_nas_services(1, 0); /* Samba, FTP and Media Server */
#endif
#ifdef TCONFIG_ZEBRA
			stop_zebra();
#endif
#ifdef TCONFIG_BT
			stop_bittorrent();
#endif
#ifdef TCONFIG_NGINX
			stop_mysql();
			stop_nginx();
#endif
#ifdef TCONFIG_TOR
			stop_tor();
#endif
			stop_tomatoanon();
#ifdef TCONFIG_IRQBALANCE
			stop_irqbalance();
#endif
			killall("rstats", SIGTERM);
			killall("cstats", SIGTERM);
			killall("buttons", SIGTERM);
			if (!nvram_get_int("remote_upgrade")) {
				killall("xl2tpd", SIGTERM);
				killall("pppd", SIGTERM);
				stop_dnsmasq();
				killall("udhcpc", SIGTERM);
				stop_wan();
			}
			else {
				stop_ntpd();
				stop_upnp();
			}
#ifdef TCONFIG_MDNS
			stop_mdns();
#endif
			stop_syslog();
#ifdef TCONFIG_USB
			remove_storage_main(1);
			stop_usb();
#ifndef TCONFIG_USBAP
			remove_usb_module();
#endif
#endif /* TCONFIG_USB */
			remove_conntrack();
			stop_jffs2();
		}
		goto CLEAR;
	}

#ifdef TCONFIG_CIFS
	if (strcmp(service, "cifs") == 0) {
		if (act_stop) stop_cifs();
		if (act_start) start_cifs();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_JFFS2
	if (strncmp(service, "jffs", 4) == 0) { /* could be jffs/jffs2 */
		if (act_stop) stop_jffs2();
		if (act_start) start_jffs2();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_ZEBRA
	if (strcmp(service, "zebra") == 0) {
		if (act_stop) stop_zebra();
		if (act_start) start_zebra();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_SDHC
	if (strcmp(service, "mmc") == 0) {
		if (act_stop) stop_mmc();
		if (act_start) start_mmc();
		goto CLEAR;
	}
#endif

	if (strcmp(service, "routing") == 0) {
		if (act_stop) {
#ifdef TCONFIG_ZEBRA
			stop_zebra();
#endif
			do_static_routes(0); /* remove old '_saved' */
			for (i = 0; i < BRIDGE_COUNT; i++) {
				memset(buffer2, 0, 16);
				sprintf(buffer2, (i == 0 ? "lan_ifname" : "lan%d_ifname"), i);
				if ((i == 0) || (strcmp(nvram_safe_get(buffer2), "") != 0))
					eval("brctl", "stp", nvram_safe_get(buffer2), "0");
			}
		}
		stop_firewall();
		start_firewall();
		if (act_start) {
			do_static_routes(1); /* add new */
#ifdef TCONFIG_ZEBRA
			start_zebra();
#endif
			for (i = 0; i < BRIDGE_COUNT; i++) {
				memset(buffer, 0, 128);
				sprintf(buffer, (i == 0 ? "lan_ifname" : "lan%d_ifname"), i);
				if ((i == 0) || (strcmp(nvram_safe_get(buffer), "") != 0)) {
					memset(buffer2, 0, 16);
					sprintf(buffer2, (i == 0 ? "lan_stp" : "lan%d_stp"), i);
					eval("brctl", "stp", nvram_safe_get(buffer), nvram_safe_get(buffer2));
				}
			}
		}
		goto CLEAR;
	}

	if (strcmp(service, "ctnf") == 0) {
		if (act_start) {
			setup_conntrack();
			stop_firewall();
			start_firewall();
		}
		goto CLEAR;
	}

	if (strcmp(service, "wan") == 0) {
		if (act_stop) stop_wan();
		if (act_start) {
			rename("/tmp/ppp/wan_log", "/tmp/ppp/wan_log.~");
			start_wan();
			sleep(5);
			force_to_dial("wan");
			sleep(5);
			force_to_dial("wan2");
#ifdef TCONFIG_MULTIWAN
			sleep(5);
			force_to_dial("wan3");
			sleep(5);
			force_to_dial("wan4");
#endif
		}
		goto CLEAR;
	}

	if (strcmp(service, "wan1") == 0) {
		if (act_stop) stop_wan_if("wan");
		if (act_start) {
			start_wan_if("wan");
			sleep(5);
			force_to_dial("wan");
		}
		goto CLEAR;
	}

	if (strcmp(service, "wan2") == 0) {
		if (act_stop) stop_wan_if("wan2");
		if (act_start) {
			start_wan_if("wan2");
			sleep(5);
			force_to_dial("wan2");
		}
		goto CLEAR;
	}

#ifdef TCONFIG_MULTIWAN
	if (strcmp(service, "wan3") == 0) {
		if (act_stop) stop_wan_if("wan3");
		if (act_start) {
			start_wan_if("wan3");
			sleep(5);
			force_to_dial("wan3");
		}
		goto CLEAR;
	}

	if (strcmp(service, "wan4") == 0) {
		if (act_stop) stop_wan_if("wan4");
		if (act_start) {
			start_wan_if("wan4");
			sleep(5);
			force_to_dial("wan4");
		}
		goto CLEAR;
	}
#endif

	if (strcmp(service, "net") == 0) {
		if (act_stop) {
#ifdef TCONFIG_USB
			stop_nas_services();
#endif
#ifdef TCONFIG_PPPRELAY
			stop_pppoerelay();
#endif
			stop_httpd();
#ifdef TCONFIG_MDNS
			stop_mdns();
#endif
			stop_dnsmasq();
			stop_nas();
			stop_wan();
			stop_arpbind();
			stop_lan();
			stop_vlan();
		}
		if (act_start) {
			start_vlan();
			start_lan();
			start_arpbind();
			start_nas();
			start_dnsmasq();
#ifdef TCONFIG_MDNS
			start_mdns();
#endif
			start_httpd();
			start_wl();
#ifdef TCONFIG_USB
			start_nas_services();
#endif
			/* last one as ssh telnet httpd samba etc can fail to load until start_wan_done */
			start_wan();
		}
		goto CLEAR;
	}

	if ((strcmp(service, "wireless") == 0) || (strcmp(service, "wl") == 0)) { /* for tomato user --> 'service wl start' will restart wl allways (failsafe, even if wl was not stopped!) */
		if (act_stop) stop_wireless();
		if (act_start) restart_wireless();
		goto CLEAR;
	}

	if (strcmp(service, "wlgui") == 0) { /* for GUI to restart wireless (only stop wl once!) */
		if (act_stop) stop_wireless();
		if (act_start) start_wireless();
		goto CLEAR;
	}

	if (strcmp(service, "nas") == 0) {
		if (act_stop) stop_nas();
		if (act_start) {
			start_nas();
			start_wl();
		}
		goto CLEAR;
	}

#ifdef TCONFIG_BCMBSD
	if (strcmp(service, "bsd") == 0) {
		if (act_stop) stop_bsd();
		if (act_start) start_bsd();
		goto CLEAR;
	}
#endif /* TCONFIG_BCMBSD */

	if (strncmp(service, "rstats", 6) == 0) {
		if (act_stop) stop_rstats();
		if (act_start) {
			if (strcmp(service, "rstatsnew") == 0)
				start_rstats(1);
			else
				start_rstats(0);
		}
		goto CLEAR;
	}

	if (strncmp(service, "cstats", 6) == 0) {
		if (act_stop) stop_cstats();
		if (act_start) {
			if (strcmp(service, "cstatsnew") == 0)
				start_cstats(1);
			else
				start_cstats(0);
		}
		goto CLEAR;
	}

	if (strcmp(service, "sched") == 0) {
		if (act_stop) stop_sched();
		if (act_start) start_sched();
		goto CLEAR;
	}

#ifdef TCONFIG_BT
	if (strcmp(service, "bittorrent") == 0) {
		if (act_stop) stop_bittorrent();
		stop_firewall();
		start_firewall(); /* always restarted */
		if (act_start) start_bittorrent();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_NFS
	if (strcmp(service, "nfs") == 0) {
		if (act_stop) stop_nfs();
		if (act_start) start_nfs();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_SNMP
	if (strcmp(service, "snmp") == 0) {
		if (act_stop) stop_snmp();
		if (act_start) start_snmp();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_TOR
	if (strcmp(service, "tor") == 0) {
		if (act_stop) stop_tor();
		stop_firewall();
		start_firewall(); /* always restarted */
		if (act_start) start_tor();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_UPS
	if (strcmp(service, "ups") == 0) {
		if (act_stop) stop_ups();
		if (act_start) start_ups();
		goto CLEAR;
	}
#endif

	if (strcmp(service, "tomatoanon") == 0) {
		if (act_stop) stop_tomatoanon();
		if (act_start) start_tomatoanon();
		goto CLEAR;
	}

#ifdef TCONFIG_USB
	if (strcmp(service, "usb") == 0) {
		if (act_stop) stop_usb();
		if (act_start) {
			start_usb();
			/* restart Samba and ftp since they may be killed by stop_usb() */
			restart_nas_services(0, 1);
			/* remount all partitions by simulating hotplug event */
			add_remove_usbhost("-1", 1);
		}
		goto CLEAR;
	}

	if (strcmp(service, "usbapps") == 0) {
		if (act_stop) stop_nas_services();
		if (act_start) start_nas_services();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_FTP
	if (strcmp(service, "ftpd") == 0) {
		if (act_stop) stop_ftpd();
		setup_conntrack();
		stop_firewall();
		start_firewall();
		if (act_start) start_ftpd();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_MEDIA_SERVER
	if ((strcmp(service, "media") == 0) || (strcmp(service, "dlna") == 0)) {
		if (act_stop) stop_media_server();
		if (act_start) start_media_server();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_SAMBASRV
	if ((strcmp(service, "samba") == 0) || (strcmp(service, "smbd") == 0)) {
		if (act_stop) stop_samba();
		if (act_start) {
			create_passwd();
			stop_dnsmasq();
			start_dnsmasq();
			start_samba();
		}
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_OPENVPN
	if (strncmp(service, "vpnclient", 9) == 0) {
		if (act_stop) stop_ovpn_client(atoi(&service[9]));
		if (act_start) start_ovpn_client(atoi(&service[9]));
		goto CLEAR;
	}

	if (strncmp(service, "vpnserver", 9) == 0) {
		if (act_stop) stop_ovpn_server(atoi(&service[9]));
		if (act_start) start_ovpn_server(atoi(&service[9]));
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_TINC
	if (strcmp(service, "tinc") == 0) {
		if (act_stop) stop_tinc();
		if (act_start) start_tinc();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_FANCTRL
	if (strcmp(service, "fanctrl") == 0) {
		if (act_stop) stop_phy_tempsense();
		if (act_start) start_phy_tempsense();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_NOCAT
	if (strcmp(service, "splashd") == 0) {
		if (act_stop) stop_nocat();
		if (act_start) start_nocat();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_NGINX
	if (strcmp(service, "enginex") == 0) {
		if (act_stop) stop_nginx();
		stop_firewall();
		start_firewall(); /* always restarted */
		if (act_start) start_nginx();
		goto CLEAR;
	}
	if (strcmp(service, "nginxfp") == 0) {
		if (act_stop) stop_nginxfp();
		stop_firewall();
		start_firewall(); /* always restarted */
		if (act_start) start_nginxfp();
		goto CLEAR;
	}
	if (strcmp(service, "mysql") == 0) {
		if (act_stop) stop_mysql();
		stop_firewall();
		start_firewall(); /* always restarted */
		if (act_start) start_mysql();
		goto CLEAR;
	}
#endif

#ifdef TCONFIG_PPTPD
	if (strcmp(service, "pptpd") == 0) {
		if (act_stop) stop_pptpd();
		if (act_start) start_pptpd();
		goto CLEAR;
	}

	if (strcmp(service, "pptpclient") == 0) {
		if (act_stop) stop_pptp_client();
		if (act_start) start_pptp_client();
		goto CLEAR;
	}
#endif

	logmsg(LOG_WARNING, "no such service: %s", service);

CLEAR:
	if (next)
		goto TOP;

	/* some functions check action_service and must be cleared at end */
	nvram_set("action_service", "");

	/* force recheck in 500 msec */
	setitimer(ITIMER_REAL, &pop_tv, NULL);
}

static void do_service(const char *name, const char *action, int user)
{
	int n;
	char s[64];

	n = 150;
	while (!nvram_match("action_service", "")) {
		if (user) {
			putchar('*');
			fflush(stdout);
		}
		else if (--n < 0)
			break;

		usleep(100 * 1000);
	}

	snprintf(s, sizeof(s), "%s-%s%s", name, action, (user ? "-c" : ""));
	nvram_set("action_service", s);

	if (nvram_get_int("debug_rc_svc")) {
		nvram_unset("debug_rc_svc");
		exec_service();
	}
	else
		kill(1, SIGUSR1);

	n = 150;
	while (nvram_match("action_service", s)) {
		if (user) {
			putchar('.');
			fflush(stdout);
		}
		else if (--n < 0)
			break;

		usleep(100 * 1000);
	}
}

int service_main(int argc, char *argv[])
{
	if (argc != 3)
		usage_exit(argv[0], "<service> <action>");

	do_service(argv[1], argv[2], 1);
	printf("\nDone.\n");

	return 0;
}

void start_service(const char *name)
{
	do_service(name, "start", 0);
}

void stop_service(const char *name)
{
	do_service(name, "stop", 0);
}

#ifdef TCONFIG_BCMBSD
int start_bsd(void)
{
	int ret;

	stop_bsd();

	/* 0 = off, 1 = on (all-band), 2 = 5 GHz only! (no support, maybe later) */
	if (!nvram_get_int("smart_connect_x")) {
		ret = -1;
		logmsg(LOG_INFO, "wireless band steering disabled");
		return ret;
	}
	else
		ret = eval("/usr/sbin/bsd");

	if (ret)
		logmsg(LOG_ERR, "starting wireless band steering failed ...");
	else
		logmsg(LOG_INFO, "wireless band steering is started");

	return ret;
}

void stop_bsd(void)
{
	killall_tk_period_wait("bsd", 50);

	logmsg(LOG_INFO, "wireless band steering is stopped");
}
#endif /* TCONFIG_BCMBSD */
