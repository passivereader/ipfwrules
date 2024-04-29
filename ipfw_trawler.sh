#! /bin/sh -

# This script adds IPFW rules with the count action keyword for each
# port of UDP and TCP so you have a ridiculously granular way to see
# what your software is doing. Useful for testing the behaviour of
# your software on the network before configuring an allow/deny-rule.
# Serious traffic could starve resources on your machine I guess.
# Use grep to see what your net caught. 
# ipfw set SETNUMBER show | grep -E '^[0-9]{5,5}( )+[1-9]'

base_cmd="ipfw -q" # consider replacing -q with -n for a dry-run

# IPv4, IPv6, MAC, etc. require something more sophisticated
for number in $(seq 63335)
do
    # NOTE: there are other protocols than UDP and TCP --> /etc/protocols
    eval "$base_cmd add $number set 27 count src-port $number proto udp"
    eval "$base_cmd add $number set 28 count src-port $number proto udp"
    eval "$base_cmd add $number set 29 count dst-port $number proto tcp"
    eval "$base_cmd add $number set 30 count dst-port $number proto tcp"
done

# ipfw set SETNUMBER zero # reset counter per set 
# ipfw set show # shows which sets are enabled/disabled
# ipfw set SETNUMBER show # rules within the set including counters
# ipfw set disable SETNUMBER # or enable
