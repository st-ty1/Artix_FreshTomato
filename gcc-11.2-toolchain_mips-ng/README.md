toolchain with gcc-11.2, binutils-2.37, uclibc-ng 1.0.40 and kernel headers of FT-sources:
(DNS poisoning patch https://mailman.openadk.org/mailman3/hyperkitty/list/devel@uclibc-ng.org/message/T5K75RFTNQV24FSQHMRP6UCMMJVIQSYX/attachment/4/20220511-FullPatch-DnsLookup-Configurable-dnsQueryId-generation-includi.patch not integrated yet)

Start building FT with build_ft-mips-2021.11.1_RT-AC.sh script. (Paths in this script can be changed to your needs; script only available for RT-AC routers, yet.) 
Checked with Asus RT-N66U AIO-Version: working (i.e. no reboot-loop and no errors in syslog), only tested basic functions.

BR
st-ty1
