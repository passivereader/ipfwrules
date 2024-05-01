#! /bin/sh -
# check relevant sysctls!

# fw="ipfw -n" # dry-run first
fw="ipfw -q"
${fw} -f flush
${fw} -f table all destroy

# manually execute add_roothints_to_table.sh
${fw} -f set 0 table DNSROOTHINTS create type addr
${fw} /root/ipfwfiles/basic.rules
${fw} /root/ipfwfiles/ipfw.rules
