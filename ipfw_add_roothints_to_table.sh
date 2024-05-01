#! /bin/sh -
roothints=$(local-unbound-control list_stubs | grep -E -o "[0-9].*")
for hint in $roothints
do
    eval "ipfw set 0 table DNSROOTHINTS add $hint"
done
