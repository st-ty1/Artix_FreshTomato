#!/usr/bin/perl
#
#	libfoo.pl
#	Copyright (C) 2006-2008 Jonathan Zarate
#
#	- strip un-needed objects
#	- create xref of symbols used
#

$root = $ENV{"TARGETDIR"};
$uclibc = $ENV{"TOOLCHAIN"};
$router = $ENV{"SRCBASE"} . "/router";
$openssldir = $ENV{"OPENSSLDIR"};

sub error
{
	print STDERR "\n*** ERROR: " . (shift) . "\n\n";
	exit 1;
}

sub basename
{
	my $fn = shift;
	if ($fn =~ /([^\/]+)$/) {
		return $1;
	}
	return $fn;
}

sub load
{
    my $fname = shift;

	if ((-l $fname) ||
		($fname =~ /\/lib\/modules\/\d+\.\d+\.\d+/) ||
		($fname =~ /\.(asp|gif|png|svg|js|jsx|css|txt|pat|sh)$/)) {
		return;
	}
	
	if (-d $fname) {
		my $d;
		if (opendir($d, $fname)) {
			foreach (readdir($d)) {
				if ($_ !~ /^\./) {
					load($fname . "/" . $_);
				}
			}
			closedir($d);
		}
		return;
	}


	my $f;
	my $base;
	my $ok;
	my $s;

	$base = basename($fname);
	print LOG "\n\nreadelf $base:\n";
	
	open($f, "mipsel-linux-readelf -WhsdD ${fname} 2>&1 |") || error("readelf - $!\n");

	while (<$f>) {
		print LOG;

		if (/\s+Type:\s+(\w+)/) {
			$elf_type{$base} = $1;
			$ok = 1;
			last;
		}
	}
	
	if (!$ok) {
		close($f);
		return;
	}

	print "$elf_type{$base} $base", " " x 30, "\r";
	
	push(@elfs, $base);
	
	while (<$f>) {
		print LOG;
		
		if (/\(NEEDED\)\s+Shared library: \[(.+)\]/) {
			push(@{$elf_lib{$base}}, $1);
		}
		elsif (/Symbol table for image:/) {
			last;
		}
	}
	
	while (<$f>) {
		print LOG;

		if (/\s+(WEAK|GLOBAL)\s+(?:DEFAULT|VISIBLE)\s+(\w+)\s+(\w+)/) {
			$s = $3;
			if ($2 eq 'UND') {
				if ($1 eq 'GLOBAL') {
					$elf_ext{$base}{$s} = 1;
				}
				else {
					print LOG "*** not GLOBAL\n";
				}
			}
			elsif ($2 eq 'ABS') {
			}
			elsif ($2 =~ /^\d+$/) {
				$elf_exp{$base}{$s} = 1;
			}
			else {
				print LOG "*** unknown type\n";
			}
		}
		elsif (!/Num Buc:/) {
			print LOG "*** strange line\n";
		}
	}

	close($f);
}

sub fixDynDep
{
	my ($user, $dep) = @_;
	
	if (!defined $elf_dyn{$user}{$dep}) {
		push(@{$elf_lib{$user}}, $dep);
		$elf_dyn{$user}{$dep} = 1;

		print LOG "FixDynDep: $user = $dep\n";
	}
}

sub fixDyn
{
	my $s;

	foreach (@elfs) {
		if (/^libipt_.+\.so$/) {
			fixDynDep("iptables", $_);
			fixDynDep($_, "libxtables.so");
		}
		elsif (/^libip6t_.+\.so$/) {
			fixDynDep("ip6tables", $_);
			fixDynDep($_, "libxtables.so");
		}
		elsif (/^libxt_.+\.so$/) {
			fixDynDep("ip6tables", $_);
			fixDynDep($_, "libxtables.so");
		}
		elsif (/^CP\d+\.so$/) {
			fixDynDep("smbd", $_);
		}
	}

	fixDynDep("l2tpd", "cmd.so");
	fixDynDep("l2tpd", "sync-pppd.so");
	fixDynDep("pppd", "pppol2tp.so");
	fixDynDep("pppd", "pptp.so");
	fixDynDep("pppd", "rp-pppoe.so");

	fixDynDep("libcrypto.so.1.0.0", "libssl.so.1.0.0");

#shibby
	fixDynDep("transmission-daemon", "libevent-2.1.so.7");
	fixDynDep("transmission-daemon", "libcurl.so.4.7.0");
#	fixDynDep("transmission-daemon", "libiconv.so.2.6.1");
	fixDynDep("transmission-remote", "libevent-2.1.so.7");
	fixDynDep("transmission-remote", "libcurl.so.4.7.0");
#	fixDynDep("transmission-remote", "libiconv.so.2.6.1");
	fixDynDep("radvd", "libdaemon.so.0.5.0");
	fixDynDep("miniupnpd", "libnfnetlink.so.0.2.0");
	fixDynDep("dnscrypt-proxy", "libsodium.so.23.3.0");
	fixDynDep("tincd", "liblzo2.so.2.0.0");
	fixDynDep("openvpn", "liblzo2.so.2.0.0");
	fixDynDep("usb_modeswitch", "libusb-1.0.so");
	fixDynDep("nginx", "libpcre.so.1.2.12");
	fixDynDep("libpcreposix.so.0.0.7", "libpcre.so.1.2.12");

#minidlna module, bwq518
	fixDynDep("minidlna", "libz.so.1");
	fixDynDep("minidlna", "libstdc.so.6");
	fixDynDep("minidlna", "libiconv.so.2.6.1");
#	fixDynDep("minidlna", "libssl.so.1.0.0");
	fixDynDep("minidlna", "libjpeg.so");
	fixDynDep("minidlna", "libogg.so.0");
	fixDynDep("minidlna", "libvorbis.so.0");
	fixDynDep("minidlna", "libid3tag.so.0");
	fixDynDep("minidlna", "libexif.so.12");
	fixDynDep("minidlna", "libFLAC.so.8");
	fixDynDep("minidlna", "libsqlite3.so.0.8.6");
	fixDynDep("libjpeg.so", "libc.so.0");
	fixDynDep("libavcodec.so.52", "libpthread.so.0");

#mysql - bwq518
	fixDynDep("mysql", "libmysqlclient.so.16.0.0");
	fixDynDep("my_print_defaults", "libmysqlclient.so.16.0.0");
	fixDynDep("myisamchk", "libmysqlclient.so.16.0.0");
	fixDynDep("mysqladmin", "libmysqlclient.so.16.0.0");
	fixDynDep("mysqld", "libmysqlclient.so.16.0.0");
	fixDynDep("mysqldump", "libmysqlclient.so.16.0.0");
	fixDynDep("mysql", "libmysqlclient_r.so.16.0.0");
	fixDynDep("my_print_defaults", "libmysqlclient_r.so.16.0.0");
	fixDynDep("myisamchk", "libmysqlclient_r.so.16.0.0");
	fixDynDep("mysqladmin", "libmysqlclient_r.so.16.0.0");
	fixDynDep("mysqld", "libmysqlclient_r.so.16.0.0");
	fixDynDep("mysqldump", "libmysqlclient_r.so.16.0.0");
	fixDynDep("libmysqlclient.so.16.0.0", "libz.so.1");
	fixDynDep("libmysqlclient_r.so.16.0.0", "libz.so.1");
	fixDynDep("libmysqlclient.so.16.0.0", "libncurses.so.6");
	fixDynDep("libmysqlclient_r.so.16.0.0", "libncurses.so.6");
	fixDynDep("libmysqlclient.so.16.0.0", "libcrypto.so.1.0.0");
	fixDynDep("libmysqlclient_r.so.16.0.0", "libcrypto.so.1.0.0");
	fixDynDep("libmysqlclient.so.16.0.0", "libssl.so.1.0.0");
	fixDynDep("libmysqlclient_r.so.16.0.0", "libssl.so.1.0.0");
	fixDynDep("mysql", "libz.so.1");
	fixDynDep("mysqld", "libz.so.1");
	fixDynDep("mysqldump", "libz.so.1");
	fixDynDep("myisamchk", "libz.so.1");
	fixDynDep("mysqladmin", "libz.so.1");
	fixDynDep("my_print_defaults", "libz.so.1");
	fixDynDep("mysql", "libncurses.so.6");
	fixDynDep("mysqld", "libncurses.so.6");
	fixDynDep("mysqldump", "libncurses.so.6");
	fixDynDep("myisamchk", "libncurses.so.6");
	fixDynDep("mysqladmin", "libncurses.so.6");
	fixDynDep("my_print_defaults", "libncurses.so.6");
	fixDynDep("mysql", "libz.so.1");
	fixDynDep("mysqld", "libz.so.1");
	fixDynDep("mysqldump", "libz.so.1");
	fixDynDep("myisamchk", "libz.so.1");
	fixDynDep("mysqladmin", "libz.so.1");
	fixDynDep("my_print_defaults", "libz.so.1");
	fixDynDep("mysql", "libcrypto.so.1.0.0");
	fixDynDep("mysqld", "libcrypto.so.1.0.0");
	fixDynDep("mysqldump", "libcrypto.so.1.0.0");
	fixDynDep("myisamchk", "libcrypto.so.1.0.0");
	fixDynDep("mysqladmin", "libcrypto.so.1.0.0");
	fixDynDep("my_print_defaults", "libcrypto.so.1.0.0");
	fixDynDep("mysql", "libssl.so.1.0.0");
	fixDynDep("mysqld", "libssl.so.1.0.0");
	fixDynDep("mysqldump", "libssl.so.1.0.0");
	fixDynDep("myisamchk", "libssl.so.1.0.0");
	fixDynDep("mysqladmin", "libssl.so.1.0.0");
	fixDynDep("my_print_defaults", "libssl.so.1.0.0");

#ipset modules
	fixDynDep("libipset_iphash.so", "ipset");
	fixDynDep("libipset_iptree.so", "ipset");
	fixDynDep("libipset_ipmap.so", "ipset");
	fixDynDep("libipset_ipporthash.so", "ipset");
	fixDynDep("libipset_ipportiphash.so", "ipset");
	fixDynDep("libipset_ipportnethash.so", "ipset");
	fixDynDep("libipset_iptreemap.so", "ipset");
	fixDynDep("libipset_macipmap.so", "ipset");
	fixDynDep("libipset_nethash.so", "ipset");
	fixDynDep("libipset_portmap.so", "ipset");
	fixDynDep("libipset_setlist.so", "ipset");

	fixDynDep("tomatodata.cgi", "libc.so.0");
	fixDynDep("tomatoups.cgi", "libc.so.0");
	fixDynDep("apcupsd", "libc.so.0");
	fixDynDep("apcupsd", "libgcc_s.so.1");
	fixDynDep("apcaccess", "libc.so.0");
	fixDynDep("smtp", "libc.so.0");

#	fixDynDep("libbcm.so", "libshared.so");
#	fixDynDep("libbcm.so", "libc.so.0");

	fixDynDep("nginx", "libpcre.so.1.2.12");
	fixDynDep("nginx", "libpcreposix.so.0.0.7");
	fixDynDep("php-cgi", "libxml2.so.2.9.12");
	fixDynDep("php-cgi", "libpng16.so.16.37.0");
	fixDynDep("php-cgi", "libiconv.so.2.6.1");
	fixDynDep("php-cgi", "libsqlite3.so.0.8.6");
	fixDynDep("php-cgi", "libcurl.so.4.7.0");
	fixDynDep("php-cli", "libxml2.so.2.9.12");
	fixDynDep("php-cli", "libpng16.so.16.37.0");
	fixDynDep("php-cli", "libiconv.so.2.6.1");
	fixDynDep("php-cli", "libsqlite3.so.0.8.6");
	fixDynDep("php-cli", "libcurl.so.4.7.0");

	fixDynDep("curl", "libcurl.so.4.7.0");
	fixDynDep("mdu", "libcurl.so.4.7.0");

#!!TB - Updated Broadcom WL driver
	fixDynDep("libbcmcrypto.so", "libc.so.0");
	fixDynDep("nas", "libbcmcrypto.so");
	fixDynDep("wl", "libbcmcrypto.so");
	fixDynDep("nas", "libc.so.0");
	fixDynDep("wl", "libc.so.0");

#Roadkill for NocatSplash
	fixDynDep("splashd","libglib-1.2.so.0.0.10");

# iperf (pedro)
	fixDynDep("iperf", "libiperf.so.0.0.0");

# ebtables (pedro)
	fixDynDep("ebtables-legacy", "libebtc.so.0.0.0");

# samba3 (pedro)
	fixDynDep("samba_multicall", "libiconv.so.2.6.1");

# tor (pedro)
	fixDynDep("tor", "libevent-2.1.so.7");

# e2fsprogs (pedro)
	fixDynDep("e2fsck", "libext2fs.so.2.4");
	fixDynDep("e2fsck", "libuuid.so.1.2");
	fixDynDep("e2fsck", "libblkid.so.1.0");
	fixDynDep("e2fsck", "libe2p.so.2.3");
	fixDynDep("e2fsck", "libcom_err.so.2.1");
	fixDynDep("mke2fs", "libext2fs.so.2.4");
	fixDynDep("mke2fs", "libuuid.so.1.2");
	fixDynDep("mke2fs", "libblkid.so.1.0");
	fixDynDep("mke2fs", "libe2p.so.2.3");
	fixDynDep("mke2fs", "libcom_err.so.2.1");
	fixDynDep("tune2fs", "libext2fs.so.2.4");
	fixDynDep("tune2fs", "libuuid.so.1.2");
	fixDynDep("tune2fs", "libblkid.so.1.0");
	fixDynDep("tune2fs", "libe2p.so.2.3");
	fixDynDep("tune2fs", "libcom_err.so.2.1");
	fixDynDep("badblocks", "libext2fs.so.2.4");
	fixDynDep("badblocks", "libuuid.so.1.2");
	fixDynDep("badblocks", "libblkid.so.1.0");
	fixDynDep("badblocks", "libe2p.so.2.3");
	fixDynDep("badblocks", "libcom_err.so.2.1");

# avahi (pedro)
	fixDynDep("avahi-daemon", "libavahi-core.so.7.0.2");
	fixDynDep("avahi-daemon", "libavahi-common.so.3.5.3");
	fixDynDep("avahi-daemon", "libexpat.so.1.6.2");
	fixDynDep("avahi-daemon", "libdaemon.so.0.5.0");
}

sub usersOf
{
	my $name = shift;
	my $sym = shift;
	my @x;
	my $e;
	my $l;
	
	@x = ();
	foreach $e (@elfs) {
		foreach $l (@{$elf_lib{$e}}) {
			if ($l eq $name) {
				if ((!defined $sym) || (defined $elf_ext{$e}{$sym})) {
					push(@x, $e);
				}
				last;
			}
		}
	}
	return @x;
}

sub resolve
{
	my $name = shift;
	my $sym = shift;
	my $l;
	
	foreach $l (@{$elf_lib{$name}}) {
#		print "\n$l $sym ", $elf_exp{$l}{$sym}, "\n";
		return $l if (defined $elf_exp{$l}{$sym});
	}
	return "*** unresolved ***";
}

sub fillGaps
{
	my $name;
	my $sym;
	my @users;
	my $u;
	my $t;
	my $found;

	print LOG "Resolving implicit links...\n";
	
	foreach $name (@elfs) {
		foreach $sym (keys %{$elf_ext{$name}}) {
			$found = 0;

			if ($sym eq '__uClibc_start_main') {
				$sym = '__uClibc_main';
			}

			#  __gnu_local_gp is defined specially by the linker on MIPS
			if ($sym eq '__gnu_local_gp') {
				$found = 1;
			}
			elsif (resolve($name, $sym) eq "*** unresolved ***") {
				@users = usersOf($name);
				foreach $u (@users) {
					# if exported by $u
					if (defined $elf_exp{$u}{$sym}) {
						fixDynDep($name, $u);
						$found = 1;
					}
					# if exported by shared libs of $u
					if (($t = resolve($u, $sym)) ne "*** unresolved ***") {
						fixDynDep($name, $t);
						$found = 1;
					}
				}
				
				if ($found == 0) {
					print "Unable to resolve $sym used by $name\n", @users;
					exit 1;
				}
			}
		}
	}
}

sub tab
{
	my $current = shift;
	my $target = shift;
	my $s = "";
	my $n;
	
	while (1) {
		$n = $current + (4 - ($current % 4));
		last if ($n > $target);
		$s = $s . "\t";
		$current = $n;
	}
	while ($current < $target) {
		$s = $s . " ";
		$current++;
	}
	return $s;
}

sub genXref
{
	my $f;
	my $fname;
	my $s;
	my @u;
	
	print "Generating Xref Report...\n";
	
	open($f, ">libfoo_xref.txt");
	foreach $fname (sort keys %elf_type) {
		print $f "$fname:\n";
		
		if (scalar(@{$elf_lib{$fname}}) > 0) {
			print $f "Dependency:\n";
			foreach $s (sort @{$elf_lib{$fname}}) {
				print $f "\t$s", defined $elf_dyn{$fname}{$s} ? " (dyn)\n" : "\n";
			}
		}
		
		if (scalar(keys %{$elf_exp{$fname}}) > 0) {
			print $f "Export:\n";
			foreach $s (sort keys %{$elf_exp{$fname}}) {
				@u = usersOf($fname, $s);
				if (scalar(@u) > 0) {
					print $f "\t$s", tab(length($s) + 4, 40), " > ", join(",", @u), "\n";
				}
				else {
					print $f "\t$s\n";
				}
			}
		}
		
		if (scalar(keys %{$elf_ext{$fname}}) > 0) {
			print $f "External:\n";
			foreach $s (sort keys %{$elf_ext{$fname}}) {
				print $f "\t$s", tab(length($s) + 4, 40), " < ", resolve($fname, $s), "\n";
			}
		}
		
		print $f "\n";
	}
	close($f);
}


sub genSO
{
	my ($so, $arc, $strip, $opt) = @_;
	my $name = basename($so);
	my $sym;
	my $fn;
	my $inuse;
	my @used;
	my @unused;
	my $cmd;
	my $before, $after;

	if (!-f $so) {
		print "$name: not found, skipping...\n";
		return 0;
	}

	#!!TB
	if (!-f $arc) {
		print "$arc: not found, skipping...\n";
		return 0;
	}
	
	foreach $sym (sort keys %{$elf_exp{$name}}) {
		if ((scalar(usersOf($name, $sym)) > 0) || (${strip} eq "no")) {
			push(@used, $sym);
		}
		else {
			push(@unused, $sym);
		}
	}

#	print "\n$name: Attempting to link ", scalar(@used), " and remove ", scalar(@unused), " objects...\n";

	print LOG "\n\n${base}\n";
	
#	$cmd = "mipsel-brcm-linux-uclibc-ld -shared -s -z combreloc --warn-common --fatal-warnings ${opt} -soname ${name} -o ${so}";
#	$cmd = "mipsel-brcm-linux-uclibc-gcc -shared -nostdlib -Wl,-s,-z,combreloc -Wl,--warn-common -Wl,--fatal-warnings -Wl,--gc-sections ${opt} -Wl,-soname=${name} -o ${so}";
	$cmd = "mipsel-brcm-linux-uclibc-gcc -shared -nostdlib -Wl,-s,-z,combreloc -Wl,--warn-common -Wl,--gc-sections ${opt} -Wl,-soname=${name} -o ${so}";
	foreach (@{$elf_lib{$name}}) {
		if ((!$elf_dyn{$name}{$_}) && (/^lib(.+)\.so/)) {
			$cmd .= " -l$1";
		}
		else {
#			print LOG "Not marking for linkage: $_\n";
		}
	}
#	print "$cmd -u... ${arc}\n";	
	if (scalar(@used) == 0) {
		print "$name: WARNING: Library is not used by anything, will be deleted...\n";
		unlink $so;
#		<>;
		return 0;
	}
	$cmd .= " -u " . join(" -u ", @used) . " ". $arc;

	print LOG "Command: $cmd\n";
	print LOG "Used: ", join(",", @used), "\n";
	print LOG "Unused: ", join(",", @unused), "\n";
	
	$before = -s $so;

	system($cmd);
	if ($? != 0) {
		error("ld returned $?");
	}

	$after = -s $so;
	
	print "$name: Attempted to remove ", scalar(@unused), "/", scalar(@unused) + scalar(@used), " symbols. ";
	printf "%.2fK - %.2fK = %.2fK\n", $before / 1024, $after / 1024, ($before - $after) / 1024;
	
#	print "\n$name: Attempting to link ", scalar(@used), " and remove ", scalar(@unused), " objects...\n";
#	printf "Before: %.2fK / After: %.2fK / Removed: %.2fK\n\n", $before / 1024, $after / 1024, ($before - $after) / 1024;
	return ($before > $after)
}


##
##
##

#	print "\nlibfoo.pl - fooify shared libraries\n";
#	print "Copyright (C) 2006-2007 Jonathan Zarate\n\n";

if ((!-d $root) || (!-d $uclibc) || (!-d $router)) {
	print "Missing or invalid environment variables\n";
	exit(1);
}

open(LOG, ">libfoo.debug");
#open(LOG, ">/dev/null");

print "Loading...\r";
load($root);
print "Finished loading files.", " " x 30, "\r";

fixDyn();
fillGaps();

genXref();

$stripshared = "yes";
if ($ARGV[0] eq "--noopt") {
	$stripshared = "no";
}
#genSO("${root}/lib/libc.so.0", "${uclibc}/mipsel-brcm-linux-uclibc/sysroot/usr/lib/libc.a", "", "-Wl,-init=__uClibc_init ${uclibc}/lib/optinfo/interp.os");
genSO("${root}/lib/libresolv.so.0", "${uclibc}/mipsel-brcm-linux-uclibc/sysroot/usr/lib/libresolv.a", "${stripshared}");
genSO("${root}/lib/libcrypt.so.0", "${uclibc}/mipsel-brcm-linux-uclibc/sysroot/usr/lib/libcrypt.a", "${stripshared}");
genSO("${root}/lib/libm.so.0", "${uclibc}/mipsel-brcm-linux-uclibc/sysroot/usr/lib/libm.a");
genSO("${root}/lib/libpthread.so.0", "${uclibc}/mipsel-brcm-linux-uclibc/sysroot/usr/lib/libpthread.a", "${stripshared}", "-u pthread_mutexattr_init -Wl,-init=__pthread_initialize_minimal_internal");
genSO("${root}/lib/libutil.so.0", "${uclibc}/mipsel-brcm-linux-uclibc/sysroot/usr/lib/libutil.a", "${stripshared}");
genSO("${root}/lib/libdl.so.0", "${uclibc}/mipsel-brcm-linux-uclibc/sysroot/usr/lib/libdl.a", "${stripshared}");
genSO("${root}/lib/libnsl.so.0", "${uclibc}/mipsel-brcm-linux-uclibc/sysroot/usr/lib/libnsl.a", "${stripshared}");

if ($openssldir eq "openssl") {
	genSO("${root}/usr/lib/libcrypto.so.1.0.0", "${openssldir}/libcrypto.so.1.0.0");
	genSO("${root}/usr/lib/libssl.so.1.0.0", "${openssldir}/libssl.so.1.0.0", "${stripshared}", "-L${router}/${openssldir}");
}
else {
	genSO("${root}/usr/lib/libcrypto.so.1.1", "${openssldir}/libcrypto.so.1.1");
	genSO("${root}/usr/lib/libssl.so.1.1", "${openssldir}/libssl.so.1.1", "${stripshared}", "-L${router}/${openssldir}");
}

genSO("${root}/usr/lib/libzebra.so", "${router}/zebra/lib/libzebra.a");
genSO("${root}/usr/lib/libz.so.1", "${router}/zlib/libz.a");
genSO("${root}/usr/lib/libjpeg.so", "${router}/jpeg/libjpeg.a");
genSO("${root}/usr/lib/libsqlite3.so.0.8.6", "${router}/sqlite/.libs/libsqlite3.so.0.8.6");
genSO("${root}/usr/lib/libvorbis.so.0", "${router}/libvorbis/lib/.libs/libvorbis.a", "", "-L${router}/libogg/src/.libs");
genSO("${root}/usr/lib/libid3tag.so.0", "${router}/libid3tag/.libs/libid3tag.a", "", "-L${router}/zlib");
genSO("${root}/usr/lib/libexif.so.12", "${router}/libexif/libexif/.libs/libexif.a");
genSO("${root}/usr/lib/libFLAC.so.8", "${router}/flac/src/libFLAC/.libs/libFLAC.a", "", "-L${router}/libogg/src/.libs");
genSO("${root}/usr/lib/libavcodec.so.52", "${router}/ffmpeg/libavcodec/libavcodec.a", "", "-L${router}/ffmpeg/libavutil -L${router}/zlib");
genSO("${root}/usr/lib/libavutil.so.50", "${router}/ffmpeg/libavutil/libavutil.a", "-L${router}/zlib");
genSO("${root}/usr/lib/libavformat.so.52", "${router}/ffmpeg/libavformat/libavformat.a", "", "-L${router}/ffmpeg/libavutil -L${router}/ffmpeg/libavcodec -L${router}/zlib");

genSO("${root}/usr/lib/liblzo2.so.2.0.0", "${router}/lzo/src/.libs/liblzo2.a");
genSO("${root}/usr/lib/libiptc.so", "${router}/iptables/libiptc/libiptc.a");
genSO("${root}/usr/lib/libshared.so", "${router}/shared/libshared.a");
genSO("${root}/usr/lib/libnvram.so", "${router}/nvram/libnvram.a");
genSO("${root}/usr/lib/libusb-1.0.so.0", "${router}/libusb10/libusb/.libs/libusb-1.0.a");
genSO("${root}/usr/lib/libusb-0.1.so.4", "${router}/libusb/libusb/.libs/libusb.a", "", "-L${router}/libusb10/libusb/.libs");

genSO("${root}/usr/lib/libbcmcrypto.so", "${router}/libbcmcrypto/libbcmcrypto.a");

#shibby
#genSO("${root}/usr/lib/libcurl.so.4.7.0", "${router}/libcurl/lib/.libs/libcurl.a", "", "-L${router}/zlib -L${router}/${openssldir}");
genSO("${root}/usr/lib/libevent-2.1.so.7", "${router}/libevent/.libs/libevent.a", "", "-L${router}/${openssldir}");
genSO("${root}/usr/lib/libdaemon.so.0.5.0", "${router}/libdaemon/libdaemon/.libs/libdaemon.so.0.5.0");
genSO("${root}/usr/lib/libiconv.so.2.6.1", "${router}/libiconv/lib/.libs/libiconv.a");
genSO("${root}/usr/lib/libnfnetlink.so.0.2.0", "${router}/libnfnetlink/src/.libs/libnfnetlink.a");
genSO("${root}/usr/lib/libsodium.so.23.3.0", "${router}/libsodium/src/libsodium/.libs/libsodium.a");
genSO("${root}/usr/lib/libpng16.so.16.37.0", "${router}/libpng/.libs/libpng16.so.16.37.0", "", "-L${router}/zlib");
genSO("${root}/usr/lib/libxml2.so.2.9.12", "${router}/libxml2/.libs/libxml2.a", "", "-L${router}/zlib");
genSO("${root}/usr/lib/libpcre.so.1.2.13", "${router}/pcre/.libs/libpcre.so.1.2.12");
genSO("${root}/usr/lib/libpcreposix.so.0.0.7", "${router}/pcre/.libs/libpcreposix.a");
genSO("${root}/usr/lib/libatomic_ops.so.1.0.3", "${router}/libatomic_ops/src/.libs/libatomic_ops.a");
genSO("${root}/usr/lib/libncurses.so.6", "${router}/libncurses/lib/libncurses.a");

# iperf (pedro)
genSO("${root}/usr/lib/libiperf.so.0.0.0", "${router}/iperf/src/.libs/libiperf.so.0.0.0");

# e2fsprogs (pedro)
genSO("${root}/usr/lib/libext2fs.so.2.4", "${router}/e2fsprogs/lib/libext2fs.so.2.4", "", "-L${router}/e2fsprogs/lib");
genSO("${root}/usr/lib/libuuid.so.1.2", "${router}/e2fsprogs/lib/libuuid.so.1.2", "", "-L${router}/e2fsprogs/lib");
genSO("${root}/usr/lib/libblkid.so.1.0", "${router}/e2fsprogs/lib/libblkid.so.1.0","", "-L${router}/e2fsprogs/lib");
genSO("${root}/usr/lib/libe2p.so.2.3", "${router}/e2fsprogs/lib/libe2p.so", "", "-L${router}/e2fsprogs/lib");
genSO("${root}/usr/lib/libcom_err.so.2.1", "${router}/e2fsprogs/lib/libcom_err.so", "", "-L${router}/e2fsprogs/lib");
print "\n";

close(LOG);
exit(0);
