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
		($fname =~ /\.(asp|gif|png|svg|js|jsx|css|txt|pat|sh|dat|pac|ico)$/)) {
		return;
	}
	
	if (-d $fname) {
		my $d;
		if (opendir($d, $fname)) {
			foreach (readdir($d)) {
				if ($_ !~ /^\./) {
#				print LOG2 "\nload $fname/$_:";
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
	print LOG2 "\nreadelf $base:";
	print LOG2 "\tfound $fname with basename $base   ... analysing: \n";

	open($f, "${uclibc}/bin/arm-brcm-linux-uclibcgnueabi-readelf -WhsdD ${fname} 2>&1 |") || error("readelf - $!\n");
	
	while (<$f>) {
#		print LOG2;

		if (/\s+Type:\s+(\w+)/) {
			$elf_type{$base} = $1;
			$ok = 1;
			print LOG2 "\tfound \"Type\" of base $base: ".$1.";      ->   set elf_type\{$base\} to ".$1."\n";
			last;
		}
	}
	
	if (!$ok) {
		close($f);
		return;
	}


	push(@elfs, $base);
	print LOG2 "elf_type{$base}: $elf_type{$base} von $base", " " x 30, "\r";
	print LOG2 "\t -> pushed $base to \@elfs\n";
	print LOG2 "\t -> list of \@elfs: @{$elf_lib{$base}}\n\n";
	print LOG2 "\tLooking for shared libraries:\n";
	while (<$f>) {
		print LOG2;
		
		if (/\(NEEDED\)\s+Shared library: \[(.+)\]/) {
			print LOG2 "\t\tShared library discovered: ".$1."  -> pushed ".$1." to elf_lib{$base} \n";
			push(@{$elf_lib{$base}}, $1);
		}
		elsif (/Symbol table for image:/) {
			last;
		}
	}
	print LOG2 "\t-> list of elf_lib{$base}: @{$elf_lib{$base}}\n\n"; 
	print LOG2 "\tLooking for symbols of $base:\n";
	while (<$f>) {
#		print LOG2;

		if (/\s+(WEAK|GLOBAL)\s+(?:DEFAULT|VISIBLE)\s+(\w+)\s+(\w+)/) {
			$s = $3;
			if ($2 eq 'UND') {
				if ($1 eq 'GLOBAL') {
					$elf_ext{$base}{$s} = 1;
					print LOG2 "\t\t\"GLOBAL\" (external symbol) found:   -> set elf_ext{$base}{$s} to  1\n";
				}
				else {
					print LOG2 "***\t\t$1 not GLOBAL\n";
				}
			}
			elsif ($2 eq 'ABS') {
#			print LOG2 "\t\t\"ABS\" found:   -> nothing to do. \n";
			}
			elsif ($2 =~ /^\d+$/) {
				print LOG2 "\t\tnumbers (exportable symol) found:   -> set elf_exp{$base}{$s} to  1\n";
				$elf_exp{$base}{$s} = 1;
			}
			else {
				print LOG2 "*** unknown type\n";
			}
		}
		elsif (!/Num Buc:/) {
			print LOG2 "*** strange line\n";
		}
	}

	close($f);
	print LOG2 "\tAnalysing basename $base   finished! *********\n";
}

sub fixDynDep
{
	my ($user, $dep) = @_;
#	print LOG "\tFixDynDep ($user, $dep)\n";
	
	if (!defined $elf_dyn{$user}{$dep}) {
#		print LOG "\telf_dyn{$user}{$dep} not defined yet.\n";
		push(@{$elf_lib{$user}}, $dep);
#		print LOG "\t\t-> pushed $dep to elflib($user)\n";

		$elf_dyn{$user}{$dep} = 1;
#		print LOG "\t\t-> set elf_dyn{$user}{$dep} to 1\n\n";

#		print LOG "FixDynDep: $user = $dep\n";
	}
}

sub fixDyn
{
	my $s;
	print LOG "Start FixDyn ..........\n\n";
	foreach (@elfs) {
		if (/^libipt_.+\.so$/) {
			fixDynDep("iptables", $_);
		}
		elsif (/^libip6t_.+\.so$/) {
			fixDynDep("ip6tables", $_);
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

#	fixDynDep("libcrypto.so.1.0.0", "libssl.so.1.0.0");
	fixDynDep("libcrypto.so.1.1", "libssl.so.1.1");

#shibby
	fixDynDep("transmission-daemon", "libevent-2.1.so.7");
	fixDynDep("transmission-daemon", "libcurl.so.4");
#	fixDynDep("transmission-daemon", "libiconv.so.2.6.1");
	fixDynDep("transmission-remote", "libevent-2.1.so.7");
	fixDynDep("transmission-remote", "libcurl.so.4");
#	fixDynDep("transmission-remote", "libiconv.so.2.6.1");
#	fixDynDep("radvd", "libdaemon.so.0.5.0");
	fixDynDep("miniupnpd", "libnfnetlink.so.0.2.0");
	fixDynDep("dnscrypt-proxy", "libsodium.so.23");
#	fixDynDep("wlconf", "libshared.so");


#minidlna module, bwq518
	fixDynDep("minidlna", "libz.so.1");
#	fixDynDep("minidlna", "libstdc.so.6");
#	fixDynDep("minidlna", "libiconv.so.2.6.1");
#	fixDynDep("minidlna", "libssl.so.1.0.0");
#	fixDynDep("minidlna", "libjpeg.so");
#	fixDynDep("minidlna", "libogg.so.0");
#	fixDynDep("minidlna", "libvorbis.so.0");
#	fixDynDep("minidlna", "libid3tag.so.0");
#	fixDynDep("minidlna", "libexif.so.12");
#	fixDynDep("minidlna", "libFLAC.so.8");
#	fixDynDep("libjpeg.so", "libc.so.0");
#	fixDynDep("libavcodec.so.52", "libpthread.so.0");

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
#shibby
	fixDynDep("libbcm.so", "libshared.so");
	fixDynDep("libbcm.so", "libc.so.0");

#!!TB - Updated Broadcom WL driver
	fixDynDep("libbcmcrypto.so", "libc.so.0");
	fixDynDep("nas", "libbcmcrypto.so");
	fixDynDep("wl", "libbcmcrypto.so");
	fixDynDep("nas", "libc.so.0");
	fixDynDep("wl", "libc.so.0");

#Roadkill for NocatSplash
	fixDynDep("splashd","libglib-1.2.so.0");

#Tomato RAF - php
	fixDynDep("php-cli","libz.so.1");
	fixDynDep("php-cgi","libz.so.1");
	fixDynDep("php-cli","libz.so.1");
	fixDynDep("php-cgi","libz.so.1");
	print LOG "\n\nFinish FixDyn ..........\n\n";
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
#		print LOG "sub resolve: $l $sym ", $elf_exp{$l}{$sym}, "\n";
		if (defined $elf_exp{$l}{$sym}) {
			print LOG "\t\t -> resolved: $sym = exp. symbol of $l   (subroutine resolve)\n";
			return $l
			} 
	}
	print LOG "\t\t -> not resolved: *** $sym not exp. symbol of any \"elf_libs\" of $name ***\n";
	return  "*** unresolved ***";
}

sub fillGaps
{
	my $name;
	my $sym;
	my @users;
	my $u;
	my $t;
	my $found;

	print LOG "sub fillGaps: Start: Resolving implicit links...\n\n";
	foreach $name (@elfs) {
	print LOG "\nELF file: $name  ";
		foreach $sym (keys %{$elf_ext{$name}}) {
			print LOG "\n\t  external symbol: $sym :\n";
#			print LOG "\texternal symbol $sym (external symbol list \@elf_ext{$name})";
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
						print LOG "\t\t\t\t -> $sym = exp. symbol of user $u \n\n";					
					}
					# if exported by shared libs of $u
					if (($t = resolve($u, $sym)) ne "*** unresolved ***") {
						fixDynDep($name, $t);
						$found = 1;
						print LOG "\t\t\t\t -> $sym = exp. symbol of shared lib $t of user $u \n\n";
					}
				}
				
				if ($found == 0) {
					print LOG "\t ->unable to resolve $sym used by $name\n", @users;
					print "\t\t ->unable to resolve $sym used by $name\n\n";
					exit 1;
				}
			}
		}
	}
	print LOG "Finished sub fillGaps...\n";
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
	
	print LOG "\n\nGenerating Xref Report...\n\n";
	
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
#				print $f "\t$s", tab(length($s) + 4, 40), " < ", resolve($fname, $s), defined $elf_dyn{$fname}{$s} ? " (dyn)\n" : "\n";
				print $f "\t$s", tab(length($s) + 4, 40), " < ", resolve($fname, $s),"\n";
			}
		}
		
		print $f "\n";
	}
	close($f);
	print LOG "Finished Xref Report...\n";
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
		print LOG "--$name: not found, skipping...\n\n";
		return 0;
	}

	#!!TB
	if (!-f $arc) {
		print LOG "--$arc: not found, skipping...\n\n";
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

	print LOG "++$name: Attempting to link ", scalar(@used), " and remove ", scalar(@unused), " objects...\n";

#	print LOG "\n\n$base\n";
	
#	$cmd = "mipsel-uclibc-ld -shared -s -z combreloc --warn-common --fatal-warnings ${opt} -soname ${name} -o ${so}";
#	$cmd = "mipsel-uclibc-gcc -shared -nostdlib -Wl,-s,-z,combreloc -Wl,--warn-common -Wl,--fatal-warnings -Wl,--gc-sections ${opt} -Wl,-soname=${name} -o ${so}";
#	$cmd = "arm-brcm-linux-uclibcgnueabi-ld -shared -s -z combreloc --warn-common --fatal-warnings ${opt} -soname ${name} -o ${so}";
	$cmd = "arm-brcm-linux-uclibcgnueabi-gcc -shared -nostdlib -Wl,-s,-z,combreloc -Wl,--warn-common -Wl,--fatal-warnings -Wl,--gc-sections ${opt} -Wl,-soname=${name} -o ${so}";
	foreach (@{$elf_lib{$name}}) {
		if ((!$elf_dyn{$name}{$_}) && (/^lib(.+)\.so/)) {
			$cmd .= " -l$1";
		}
		else {
			print LOG "\tNot marking for linkage: $_\n";
		}
	}
#	print LOG "$cmd -u... ${arc}\n";	
	if (scalar(@used) == 0) {
		print LOG "\t$name: WARNING: Library is not used by anything, will be deleted...\n\n";
		unlink $so;
#		<>;
		return 0;
	}
	$cmd .= " -u " . join(" -u ", @used) . " ". $arc;

	print LOG "\t\t++Command: $cmd\n";
	print LOG "\t\t++Used: ", join(",", @used), "\n";
	print LOG "\t\t++Unused: ", join(",", @unused), "\n";
	
	$before = -s $so;

	system($cmd);
	if ($? != 0) {
		error("ld returned $?");
	}

	$after = -s $so;
	
	print LOG "\t$name: Attempted to remove ", scalar(@unused), "/", scalar(@unused) + scalar(@used), " symbols. \n\n";
	printf "$name:  %.2fK - %.2fK = %.2fK\n", $before / 1024, $after / 1024, ($before - $after) / 1024;
	
	$before = -s $so;

	system("arm-brcm-linux-uclibcgnueabi-strip -s ${so}");

	$after = -s $so;
	
	printf "\tShrinked to  %.2fK \n", $after / 1024;
#	printf "$name:  %.2fK - %.2fK = %.2fK\n", $before / 1024, $after / 1024, ($before - $after) / 1024;
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
open(LOG2, ">libfoo2.debug");
#open(LOG2, ">/dev/null");

print LOG2 "\r--- Loading...\r\r";
load($root);
print LOG2 "\r--- Finished loading files. ---\r\r";

fixDyn();

fillGaps();

genXref();

$stripshared = "yes";
if ($ARGV[0] eq "--noopt") {
	$stripshared = "no";
}
print LOG "\r--- Start genSO...\r\r";

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

#$samba_libs = "-L${router}/samba4/bin/default/source4/heimdal_build -L${router}/samba4/bin/default/lib/util -L${router}/samba4/bin/shared/private -L${router}/samba4/bin/default/lib/talloc -L${router}/samba4/bin/default/source3 -L${router}/samba4/bin/default/lib/tevent -L${router}/samba4/bin/default/libcli/util -L${router}/samba4/bin/default/lib/util -L${router}/gnutls/lib/.libs -L${router}/gmp/.libs -L${router}/samba4/bin/default/lib/tdb -L${router}/samba4/bin/default/librpc -L${router}/samba4/bin/default/lib/ldb -L${router}/samba4/bin/default/source4/dsdb -L${router}/samba4/bin/default/source4/librpc/ -L${router}/samba4/bin/default/lib/param/ -L${router}/samba4/bin/default/auth/credentials/ -L${router}/samba4/bin/default/nsswitch/libwbclient/";

#genSO("${root}/usr/lib/libndr-standard.so.0","${router}/samba4/bin/default/librpc/libndr-standard.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libsmbd-base-samba4.so","${router}/samba4/bin/default/source3/libsmbd-base-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libndr-samba4.so","${router}/samba4/bin/default/source4/librpc/libndr-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libndr-samba-samba4.so","${router}/samba4/bin/default/librpc/libndr-samba-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libdcerpc-samba-samba4.so","${router}/samba4/bin/default/librpc/libdcerpc-samba-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libsamba-errors.so.1","${router}/samba4/bin/default/libcli/util/libsamba-errors.so", "", $samba_libs);
#genSO("${root}/usr/lib/libasn1-samba4.so.8","${router}/samba4/bin/default/source4/heimdal_build/libasn1-samba4.so.8", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libsmbconf.so.0","${router}/samba4/bin/default/source3/libsmbconf.so.0", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/liblibsmb-samba4.so","${router}/samba4/bin/default/source3/liblibsmb-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libsamba-util.so.0","${router}/samba4/bin/default/lib/util/libsamba-util.so.0", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libnetapi.so.0","${router}/samba4/bin/default/source3/libnetapi.so.0", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libkrb5-samba4.so.26","${router}/samba4/bin/default/source4/heimdal_build/libkrb5-samba4.so.26", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libsmbclient-raw-samba4.so","${router}/samba4/bin/default/source4/libcli/libsmbclient-raw-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libhx509-samba4.so.5","${router}/samba4/bin/default/source4/heimdal_build/libhx509-samba4.so.5", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libsamba-passdb.so.0","${router}/samba4/bin/default/source3/libsamba-passdb.so.0", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libhcrypto-samba4.so.5","${router}/samba4/bin/default/source4/heimdal_build/libhcrypto-samba4.so.5", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libcli-smb-common-samba4.so","${router}/samba4/bin/default/libcli/smb/libcli-smb-common-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libldb.so.2","${router}/samba4/bin/default/lib/ldb/libldb.so.2", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libgssapi-samba4.so.2","${router}/samba4/bin/default/source4/heimdal_build/libgssapi-samba4.so.2", "", $samba_libs);
#genSO("${root}/usr/lib/libdcerpc.so.0","${router}/samba4/bin/default/source4/librpc/libdcerpc.so.0", "", $samba_libs);
#genSO("${root}/usr/lib/libgensec-samba4.so","${router}/samba4/bin/default/auth/gensec/libgensec-samba4.so", "", $samba_libs);
#genSO("${root}/usr/lib/libldbsamba-samba4.so","${router}/samba4/bin/default/lib/ldb-samba/libldbsamba-samba4.so", "", $samba_libs);
#genSO("${root}/usr/lib/libsamdb-common-samba4.so","${router}/samba4/bin/default/source4/dsdb/libsamdb-common-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libgse-samba4.so","${router}/samba4/bin/default/source3/libgse-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libsamba-hostconfig.so.0","${router}/samba4/bin/default/lib/param/libsamba-hostconfig.so.0", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libdcerpc-binding.so.0","${router}/samba4/bin/default/librpc/libdcerpc-binding.so.0", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libauth-samba4.so","${router}/samba4/bin/default/source3/auth/libauth-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libwind-samba4.so.0","${router}/samba4/bin/default/source4/heimdal_build/libwind-samba4.so.0", "${stripshared}", $samba_libs);
#enSO("${root}/usr/lib/libmsrpc3-samba4.so","${router}/samba4/bin/default/source3/libmsrpc3-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libsamba-security-samba4.so","${router}/samba4/bin/default/libcli/security/libsamba-security-samba4.so", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libndr-nbt.so.0","${router}/samba4/bin/default/librpc/libndr-nbt.so.0", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libhdb-samba4.so.11","${router}/samba4/bin/default/source4/heimdal_build/libhdb-samba4.so.11", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libndr.so.0","${router}/samba4/bin/default/librpc/libndr.so.0", "${stripshared}", $samba_libs);
#genSO("${root}/usr/lib/libsamdb.so.0","${router}/samba4/bin/default/source4/dsdb/libsamdb.so.0", "${stripshared}", $samba_libs);

#genSO("${root}/usr/lib/libgnutls.so.30","${router}/gnutls/lib/.libs/libgnutls.so.30", "${stripshared}", "-L${router}/gmp/.libs");  
#genSO("${root}/usr/lib/libtirpc.so.3","${router}/libtirpc/src/.libs/libtirpc.so.3", "${stripshared}");

genSO("${root}/usr/lib/libz.so.1", "${router}/zlib/libz.a");
#genSO("${root}/usr/lib/libogg.so.0", "${router}/libogg/src/.libs/libogg.a");
#genSO("${root}/usr/lib/libvorbis.so.0", "${router}/libvorbis/lib/.libs/libvorbis.a", "", "-L${router}/libogg/src/.libs");
#genSO("${root}/usr/lib/libid3tag.so.0", "${router}/libid3tag/.libs/libid3tag.a", "", "-L${router}/zlib");
#genSO("${root}/usr/lib/libexif.so.12", "${router}/libexif/libexif/.libs/libexif.a");
#genSO("${root}/usr/lib/libFLAC.so.8", "${router}/flac/src/libFLAC/.libs/libFLAC.a", "", "-L${router}/libogg/src/.libs");
#genSO("${root}/usr/lib/libavcodec.so.52", "${router}/ffmpeg/libavcodec/libavcodec.a", "", "-L${router}/ffmpeg/libavutil -L${router}/zlib");
#genSO("${root}/usr/lib/libavutil.so.50", "${router}/ffmpeg/libavutil/libavutil.a", "-L${router}/zlib");

genSO("${root}/usr/lib/liblzo2.so.2", "${router}/lzo/src/.libs/liblzo2.a", "${stripshared}");
genSO("${root}/usr/lib/libshared.so", "${router}/shared/libshared.a", "${stripshared}");
genSO("${root}/usr/lib/libnvram.so", "${router}/nvram_arm/libnvram.so", "${stripshared}");
genSO("${root}/usr/lib/libusb-1.0.so.0", "${router}/libusb10/libusb/.libs/libusb-1.0.a", "${stripshared}");
#shibby
genSO("${root}/usr/lib/libcurl.so.4", "${router}/libcurl/lib/.libs/libcurl.a", "${stripshared}", "-L${router}/openssl-1.1 -L${router}/zlib");
genSO("${root}/usr/lib/libevent-2.1.so.7", "${router}/libevent/.libs/libevent.a", "${stripshared}");
genSO("${root}/usr/lib/libdaemon.so.0", "${router}/libdaemon/libdaemon/.libs/libdaemon.a");
genSO("${root}/usr/lib/libiconv.so.2", "${router}/libiconv/lib/.libs/libiconv.a", "${stripshared}");
genSO("${root}/usr/lib/libnfnetlink.so.0", "${router}/libnfnetlink/src/.libs/libnfnetlink.a", "${stripshared}");
genSO("${root}/usr/lib/libsodium.so.23", "${router}/libsodium/src/libsodium/.libs/libsodium.a", "${stripshared}");
#genSO("${root}/usr/lib/libpng.so.3", "${router}/libpng/.libs/libpng.a", "${stripshared}", "-L${router}/zlib");
#genSO("${root}/usr/lib/libpng12.so.0", "${router}/libpng/.libs/libpng12.a", "${stripshared}", "-L${router}/zlib");
genSO("${root}/usr/lib/libjpeg.so", "${router}/jpeg/libjpeg.a", "${stripshared}");
genSO("${root}/usr/lib/libxml2.so.2", "${router}/libxml2/.libs/libxml2.a","${stripshared}", "-L${router}/zlib");
genSO("${root}/usr/lib/libipset.so.11", "${router}/ipset/lib/.libs/libipset.a", "${stripshared}");
genSO("${root}/usr/lib/libpcre.so.1", "${router}/pcre/.libs/libpcre.a", "${stripshared}");
genSO("${root}/usr/lib/libpcreposix.so.0", "${router}/pcre/.libs/libpcreposix.a", "${stripshared}");
genSO("${root}/usr/lib/libsqlite3.so.0", "${router}/sqlite/.libs/libsqlite3.a", "${stripshared}");
genSO("${root}/usr/lib/libext2fs.so.2", "${router}/e2fsprogs/lib/libext2fs.a", "${stripshared}", "-L${router}/e2fsprogs/lib");
genSO("${root}/usr/lib/libncurses.so.6", "${router}/libncurses/lib/libncurses.a", "${stripshared}");
genSO("${root}/usr/lib/libglib-1.2.so.0", "${router}/glib/.libs/libglib.a", "${stripshared}");
genSO("${root}/usr/lib/libiperf.so.0", "${router}/iperf/src/.libs/libiperf.a", "${stripshared}");
genSO("${root}/usr/lib/libebtc.so.0", "${router}/ebtables/.libs/libebtc.so.0.0.0", "${stripshared}");
genSO("${root}/usr/lib/libbcmcrypto.so", "${router}/libbcmcrypto/libbcmcrypto.so", "${stripshared}");
genSO("${root}/usr/lib/libnetfilter_conntrack.so.3", "${router}/libnetfilter_conntrack/src/.libs/libnetfilter_conntrack.so.3.7.0", "${stripshared}", "-L${router}/libnfnetlink/src/.libs -L${router}/libmnl/src/.libs");
genSO("${root}/usr/lib/libxtables.so.12", "${router}/iptables-1.8.x/libxtables/.libs/libxtables.so.12.4.0", "${stripshared}", "-L${router}/libnfnetlink/src/.libs");
genSO("${root}/usr/lib/mysql/libmysqlclient.so.16", "${router}/mysql/libmysql/.libs/libmysqlclient.so.16.0.0", "${stripshared}", "-L${router}/openssl-1.1 -L${router}/zlib -L${router}/libncurses/lib");
genSO("${root}/usr/lib/mysql/libmysqlclient_r.so.16", "${router}/mysql/libmysql_r/.libs/libmysqlclient_r.so.16.0.0", "${stripshared}", "-L${router}/openssl-1.1 -L${router}/zlib -L${router}/libncurses/lib");
genSO("${root}/usr/lib/libavahi-common.so.3", "${router}/avahi/avahi-common/.libs/libavahi-common.a", "${stripshared}");
genSO("${root}/usr/lib/libavahi-core.so.7", "${router}/avahi/avahi-core/.libs/libavahi-core.a", "${stripshared}", "-L${router}/avahi/avahi-common/.libs");
genSO("${root}/usr/lib/libbcm.so", "${router}/libbcm/libbcm.so", "${stripshared}");
genSO("${root}/usr/lib/libblkid.so.1", "${router}/e2fsprogs/lib/libblkid.a", "${stripshared}", "-L${router}/e2fsprogs/lib");
genSO("${root}/usr/lib/libcom_err.so.2", "${router}/e2fsprogs/lib/libcom_err.a", "${stripshared}");
genSO("${root}/usr/lib/libe2p.so.2", "${router}/e2fsprogs/lib/libe2p.a", "${stripshared}");
genSO("${root}/usr/lib/libexpat.so.1", "${router}/expat/.libs/libexpat.a", "${stripshared}");
genSO("${root}/usr/lib/libform.so.6", "${router}/libncurses/lib/libform.a", "${stripshared}");
genSO("${root}/usr/lib/libip4tc.so.2", "${router}/iptables-1.8.x/libiptc/.libs/libip4tc.so.2.0.0", "${stripshared}", "-L${router}/libnfnetlink/src/.libs");
genSO("${root}/usr/lib/libip6tc.so.2", "${router}/iptables-1.8.x/libiptc/.libs/libip6tc.so.2.0.0", "${stripshared}", "-L${router}/libnfnetlink/src/.libs");
genSO("${root}/usr/lib/libmenu.so.6", "${router}/libncurses/lib/libmenu.a", "${stripshared}");
genSO("${root}/usr/lib/libmnl.so.0", "${router}/libmnl/src/.libs/libmnl.so.0.2.0", "${stripshared}");
genSO("${root}/usr/lib/libnetfilter_log.so.1", "${router}/libnetfilter_log/src/.libs/libnetfilter_log.so.1.1.0", "${stripshared}");
genSO("${root}/usr/lib/libnetfilter_queue.so.1", "${router}/libnetfilter_queue/src/.libs/libnetfilter_queue.so.1.4.0", "${stripshared}");
genSO("${root}/usr/lib/libpanel.so.6", "${router}/libncurses/lib/libpanel.a", "${stripshared}");
genSO("${root}/usr/lib/libpng16.so.16", "${router}/libpng/.libs/libpng16.a", "${stripshared}");
genSO("${root}/usr/lib/libuuid.so.1", "${router}/e2fsprogs/lib/libuuid.a", "${stripshared}");
genSO("${root}/usr/lib/libuuid.so.1", "${router}/e2fsprogs/lib/libuuid.a", "${stripshared}");
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
genSO("${root}/usr/lib/libglib-2.0.so.0", "${router}/glib2/staged/usr/lib/libglib-2.0.so.0", "${stripshared}", "-L${router}/libiconv/lib/.libs -L${router}/libffi/.libs -L${router}/zlib");

print LOG "\r--- Finished genSO...\r\r";

print LOG "\n--- end ---\n\n";

close(LOG2);
close(LOG);
exit(0);
