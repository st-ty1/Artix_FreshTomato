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
	
	open($f, "${uclibc}/bin/arm-brcm-linux-uclibcgnueabi-readelf -WhsdD ${fname} 2>&1 |") || error("readelf - $!\n");

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

	fixDynDep("pppd", "pppol2tp.so");
	fixDynDep("pppd", "pptp.so");
	fixDynDep("pppd", "rp-pppoe.so");

#shibby
	fixDynDep("transmission-daemon", "libcurl.so.4.7.0");
	fixDynDep("transmission-remote", "libcurl.so.4.7.0");
	fixDynDep("miniupnpd", "libnfnetlink.so.0.2.0");
	fixDynDep("tincd", "liblzo2.so.2.0.0");
	fixDynDep("openvpn", "liblzo2.so.2.0.0");
	fixDynDep("usb_modeswitch", "libusb-1.0.so");
	fixDynDep("nginx", "libpcre.so.1.2.12");

#minidlna module, bwq518
	fixDynDep("minidlna", "libiconv.so.2.6.1");
	fixDynDep("minidlna", "libsqlite3.so.0.8.6");

#mysql - bwq518
	fixDynDep("mysql", "libmysqlclient.so.16.0.0");
	fixDynDep("mysqladmin", "libmysqlclient.so.16.0.0");
	fixDynDep("mysqldump", "libmysqlclient.so.16.0.0");
	fixDynDep("nginx", "libpcre.so.1.2.12");
	fixDynDep("nginx", "libpcreposix.so.0.0.7");
	fixDynDep("php-cgi", "libxml2.so.2.9.12");
	fixDynDep("php-cgi", "libpng16.so.16.37.0");
	fixDynDep("php-cgi", "libiconv.so.2.6.1");
	fixDynDep("php-cgi", "libcurl.so.4.7.0");
	fixDynDep("php-cli", "libxml2.so.2.9.12");
	fixDynDep("php-cli", "libpng16.so.16.37.0");
	fixDynDep("php-cli", "libiconv.so.2.6.1");
	fixDynDep("php-cli", "libcurl.so.4.7.0");

	fixDynDep("curl", "libcurl.so.4.7.0");
	fixDynDep("mdu", "libcurl.so.4.7.0");

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

# new
	fixDynDep("conntrack", "libnetfilter_conntrack.so.3.7.0");
	fixDynDep("conntrack", "libmnl.so.0.2.0");
	fixDynDep("irqbalance", "libglib-1.2.so.0.0.10");
	fixDynDep("irqbalance", "libglib-2.0.so.0.3707.0");
	fixDynDep("xtables-legacy-multi", "libip4tc.so");
	fixDynDep("xtables-legacy-multi", "libxtables.so");
	fixDynDep("xtables-legacy-multi", "libip6tc.so");
	fixDynDep("ipset", "libmnl.so.0.2.0");
	fixDynDep("libnetfilter_queue.so.1.4.0", "libmnl.so.0.2.0");
	fixDynDep("libnetfilter_queue.so.1.4.0", "libnfnetlink.so.0.2.0");
	fixDynDep("libxt_connlabel.so", "libnetfilter_conntrack.so.3.7.0");
	fixDynDep("libglib-2.0.so.0.3707.0", "libiconv.so.2.6.1");
	fixDynDep("libnetfilter_conntrack.so.3.7.0", "libnfnetlink.so.0.2.0");
	fixDynDep("libipset.so.11.1.0", "libmnl.so.0.2.0");
	fixDynDep("libnetfilter_log.so.1.1.0", "libnfnetlink.so.0.2.0");
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

#	print "Resolving implicit links...\n";
	
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
	
#	print "Generating Xref Report...\n";
	
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
	
#	$cmd = "mipsel-uclibc-ld -shared -s -z combreloc --warn-common --fatal-warnings ${opt} -soname ${name} -o ${so}";
#	$cmd = "mipsel-uclibc-gcc -shared -nostdlib -Wl,-s,-z,combreloc -Wl,--warn-common -Wl,--fatal-warnings -Wl,--gc-sections ${opt} -Wl,-soname=${name} -o ${so}";
	$cmd = "arm-brcm-linux-uclibcgnueabi-gcc -shared -nostdlib -Wl,-s,-z,combreloc -Wl,--warn-common -Wl,--fatal-warnings -Wl,--gc-sections ${opt} -Wl,-soname=${name} -o ${so}";
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
		print "$name: WARNING: Library is not used by anything, deleting...\n";
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

#open(LOG, ">libfoo.debug");
open(LOG, ">/dev/null");

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
genSO("${root}/lib/libc.so.0", "${uclibc}/arm-brcm-linux-uclibcgnueabi/sysroot/lib/libc.so.0", "", "-Wl,-init=__uClibc_init");
#genSO("${root}/lib/libresolv.so.0", "${uclibc}/arm-brcm-linux-uclibcgnueabi/sysroot/usr/lib/libresolv.a", "${stripshared}");
genSO("${root}/lib/libcrypt.so.0", "${uclibc}/arm-brcm-linux-uclibcgnueabi/sysroot/usr/lib/libcrypt.a", "${stripshared}");
genSO("${root}/lib/libm.so.0", "${uclibc}/arm-brcm-linux-uclibcgnueabi/sysroot/usr/lib/libm.a", "${stripshared}");
genSO("${root}/lib/libpthread.so.0", "${uclibc}/arm-brcm-linux-uclibcgnueabi/sysroot/usr/lib/libpthread.a", "${stripshared}", "-u pthread_mutexattr_init -Wl,-init=__pthread_initialize_minimal_internal");
genSO("${root}/lib/libutil.so.0", "${uclibc}/arm-brcm-linux-uclibcgnueabi/sysroot/usr/lib/libutil.a", "${stripshared}");
genSO("${root}/lib/libdl.so.0", "${uclibc}/arm-brcm-linux-uclibcgnueabi/sysroot/usr/lib/libdl.so", "${stripshared}");
genSO("${root}/lib/libnsl.so.0", "${uclibc}/arm-brcm-linux-uclibcgnueabi/sysroot/usr/lib/libnsl.a", "${stripshared}");
genSO("${root}/lib/libstdc++.so.6", "${uclibc}/arm-brcm-linux-uclibcgnueabi/lib/libstdc++.a", "${stripshared}");

genSO("${root}/usr/lib/libcrypto.so.1.1", "${router}/openssl-1.1/libcrypto.so.1.1", "${stripshared}");
genSO("${root}/usr/lib/libssl.so.1.1", "${router}/openssl-1.1/libssl.a", "${stripshared}", "-L${router}/openssl-1.1");

genSO("${root}/usr/lib/libz.so.1", "${router}/zlib/libz.a");
#genSO("${root}/usr/lib/libogg.so.0", "${router}/libogg/src/.libs/libogg.a");
#genSO("${root}/usr/lib/libvorbis.so.0", "${router}/libvorbis/lib/.libs/libvorbis.a", "", "-L${router}/libogg/src/.libs");
#genSO("${root}/usr/lib/libid3tag.so.0", "${router}/libid3tag/.libs/libid3tag.a", "", "-L${router}/zlib");
#genSO("${root}/usr/lib/libexif.so.12", "${router}/libexif/libexif/.libs/libexif.a");
#genSO("${root}/usr/lib/libFLAC.so.8", "${router}/flac/src/libFLAC/.libs/libFLAC.a", "", "-L${router}/libogg/src/.libs");
#genSO("${root}/usr/lib/libavcodec.so.52", "${router}/ffmpeg/libavcodec/libavcodec.a", "", "-L${router}/ffmpeg/libavutil -L${router}/zlib");
#genSO("${root}/usr/lib/libavutil.so.50", "${router}/ffmpeg/libavutil/libavutil.a", "-L${router}/zlib");

genSO("${root}/usr/lib/liblzo2.so.2.0.0", "${router}/lzo/src/.libs/liblzo2.a", "${stripshared}");
genSO("${root}/usr/lib/libshared.so", "${router}/shared/libshared.a", "${stripshared}");
genSO("${root}/usr/lib/libnvram.so", "${router}/nvram_arm/libnvram.so", "${stripshared}");
genSO("${root}/usr/lib/libusb-1.0.so", "${router}/libusb10/libusb/.libs/libusb-1.0.a", "${stripshared}");
#shibby
genSO("${root}/usr/lib/libcurl.so.4.7.0", "${router}/libcurl/lib/.libs/libcurl.a", "${stripshared}", "-L${router}/openssl-1.1 -L${router}/zlib");
genSO("${root}/usr/lib/libevent-2.1.so.7", "${router}/libevent/.libs/libevent.a", "${stripshared}");
genSO("${root}/usr/lib/libdaemon.so.0.5.0", "${router}/libdaemon/libdaemon/.libs/libdaemon.a");
genSO("${root}/usr/lib/libiconv.so.2.6.1", "${router}/libiconv/lib/.libs/libiconv.a", "${stripshared}");
genSO("${root}/usr/lib/libnfnetlink.so.0.2.0", "${router}/libnfnetlink/src/.libs/libnfnetlink.a", "${stripshared}");
genSO("${root}/usr/lib/libsodium.so.23", "${router}/libsodium/src/libsodium/.libs/libsodium.a", "${stripshared}");
genSO("${root}/usr/lib/libjpeg.so", "${router}/jpeg/libjpeg.a", "${stripshared}");
genSO("${root}/usr/lib/libxml2.so.2.9.12", "${router}/libxml2/.libs/libxml2.a","${stripshared}", "-L${router}/zlib");
genSO("${root}/usr/lib/libipset.so.11.1.0", "${router}/ipset/lib/.libs/libipset.a", "${stripshared}");
genSO("${root}/usr/lib/libpcre.so.1.2.12", "${router}/pcre/.libs/libpcre.a", "${stripshared}");
genSO("${root}/usr/lib/libpcreposix.so.0.0.7", "${router}/pcre/.libs/libpcreposix.a", "${stripshared}");
genSO("${root}/usr/lib/libsqlite3.so.0.8.6", "${router}/sqlite/.libs/libsqlite3.a", "${stripshared}");
genSO("${root}/usr/lib/libext2fs.so.2.4", "${router}/e2fsprogs/lib/libext2fs.a", "${stripshared}", "-L${router}/e2fsprogs/lib");
genSO("${root}/usr/lib/libncurses.so.6", "${router}/libncurses/lib/libncurses.a", "${stripshared}");
genSO("${root}/usr/lib/libglib-1.2.so.0.0.10", "${router}/glib/.libs/libglib-1.2.so.0.0.10", "${stripshared}");
genSO("${root}/usr/lib/libiperf.so.0.0.0", "${router}/iperf/src/.libs/libiperf.a", "${stripshared}");
genSO("${root}/usr/lib/libebtc.so.0.0.0", "${router}/ebtables/.libs/libebtc.so.0.0.0", "${stripshared}");
genSO("${root}/usr/lib/libbcmcrypto.so", "${router}/libbcmcrypto/libbcmcrypto.so", "${stripshared}");
genSO("${root}/usr/lib/libnetfilter_conntrack.so.3.7.0", "${router}/libnetfilter_conntrack/src/.libs/libnetfilter_conntrack.so.3.7.0", "${stripshared}", "-L${router}/libnfnetlink/src/.libs -L${router}/libmnl/src/.libs");
genSO("${root}/usr/lib/libxtables.so", "${router}/iptables-1.8.x/libxtables/.libs/libxtables.so.12.4.0", "${stripshared}", "-L${router}/libnfnetlink/src/.libs");
genSO("${root}/usr/lib/mysql/libmysqlclient.so.16.0.0", "${router}/mysql/libmysql/.libs/libmysqlclient.so.16.0.0", "${stripshared}", "-L${router}/openssl-1.1 -L${router}/zlib -L${router}/libncurses/lib");
genSO("${root}/usr/lib/mysql/libmysqlclient_r.so.16.0.0", "${router}/mysql/libmysql_r/.libs/libmysqlclient_r.so.16.0.0", "${stripshared}", "-L${router}/openssl-1.1 -L${router}/zlib -L${router}/libncurses/lib");
genSO("${root}/usr/lib/libavahi-common.so.3.5.3", "${router}/avahi/avahi-common/.libs/libavahi-common.a", "${stripshared}");
genSO("${root}/usr/lib/libavahi-core.so.7.0.2", "${router}/avahi/avahi-core/.libs/libavahi-core.a", "${stripshared}", "-L${router}/avahi/avahi-common/.libs");
genSO("${root}/usr/lib/libbcm.so", "${router}/libbcm/libbcm.so", "${stripshared}");
genSO("${root}/usr/lib/libblkid.so.1.0", "${router}/e2fsprogs/lib/libblkid.a", "${stripshared}", "-L${router}/e2fsprogs/lib");
genSO("${root}/usr/lib/libcom_err.so.2.1", "${router}/e2fsprogs/lib/libcom_err.a", "${stripshared}");
genSO("${root}/usr/lib/libe2p.so.2.3", "${router}/e2fsprogs/lib/libe2p.a", "${stripshared}");
genSO("${root}/usr/lib/libexpat.so.1.6.2", "${router}/expat/.libs/libexpat.a", "${stripshared}");
genSO("${root}/usr/lib/libform.so.6", "${router}/libncurses/lib/libform.a", "${stripshared}");
genSO("${root}/usr/lib/libip4tc.so", "${router}/iptables-1.8.x/libiptc/.libs/libip4tc.so.2.0.0", "${stripshared}", "-L${router}/libnfnetlink/src/.libs");
genSO("${root}/usr/lib/libip6tc.so", "${router}/iptables-1.8.x/libiptc/.libs/libip6tc.so.2.0.0", "${stripshared}", "-L${router}/libnfnetlink/src/.libs");
genSO("${root}/usr/lib/libmenu.so.6", "${router}/libncurses/lib/libmenu.a", "${stripshared}");
genSO("${root}/usr/lib/libmnl.so.0.2.0", "${router}/libmnl/src/.libs/libmnl.so.0.2.0", "${stripshared}");
genSO("${root}/usr/lib/libnetfilter_log.so.1.1.0", "${router}/libnetfilter_log/src/.libs/libnetfilter_log.so.1.1.0", "${stripshared}");
genSO("${root}/usr/lib/libnetfilter_queue.so.1.4.0", "${router}/libnetfilter_queue/src/.libs/libnetfilter_queue.so.1.4.0", "${stripshared}");
genSO("${root}/usr/lib/libpanel.so.6", "${router}/libncurses/lib/libpanel.a", "${stripshared}");
genSO("${root}/usr/lib/libpng16.so.16.37.0", "${router}/libpng/.libs/libpng16.a", "${stripshared}", "-L${router}/zlib");
genSO("${root}/usr/lib/libuuid.so.1.2", "${router}/e2fsprogs/lib/libuuid.a", "${stripshared}");
genSO("${root}/usr/lib/libavcodec.so.52", "${router}/ffmpeg//libavcodec/libavcodec.so.52", "${stripshared}", "-L${router}/ffmpeg/libavutil -L${router}/zlib");
genSO("${root}/usr/lib/libavformat.so.52", "${router}/ffmpeg/libavformat/libavformat.so.52", "${stripshared}", "-L${router}/ffmpeg/libavutil -L${router}/ffmpeg/libavcodec -L${router}/zlib");
genSO("${root}/usr/lib/libavutil.so.50", "${router}/ffmpeg/libavutil/libavutil.so.50", "${stripshared}");
genSO("${root}/usr/lib/libexif.so.12", "${router}/libexif/libexif/.libs/libexif.so.12", "${stripshared}");
genSO("${root}/usr/lib/libFLAC.so.8", "${router}/flac/src/libFLAC/.libs/libFLAC.so.8", "${stripshared}", "-L${router}/libogg/src/.libs");
genSO("${root}/usr/lib/libogg.so.0", "${router}/libogg/src/.libs/libogg.so.0", "${stripshared}");
genSO("${root}/usr/lib/libmssl.so", "${router}/mssl/libmssl.so", "${stripshared}", "-L${router}/openssl-1.1");
genSO("${root}/usr/lib/libvorbis.so.0", "${router}/libvorbis/lib/.libs/libvorbis.so.0", "${stripshared}", "-L${router}/libogg/src/.libs");
genSO("${root}/usr/lib/libid3tag.so.0", "${router}/libid3tag/.libs/libid3tag.a", "${stripshared}", "-L${router}/zlib");
genSO("${root}/usr/lib/libffi.so.6.0.4", "${router}/libffi/.libs/libffi.so.6", "${stripshared}");
genSO("${root}/usr/lib/libglib-2.0.so.0.3707.0", "${router}/glib2/staged/usr/lib/libglib-2.0.so.0", "${stripshared}", "-L${router}/libiconv/lib/.libs -L${router}/libffi/.libs -L${router}/zlib");

print "\n";

close(LOG);
exit(0);
