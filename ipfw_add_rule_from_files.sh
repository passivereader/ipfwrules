#! /bin/sh -

# From sh(1): A “--” or plain ‘-’ will stop option processing

# This script lets you process multiple ipfw rule files.
# The rule files must contain plain ipfw rules.
# Correct ipfw syntax is required, check using ipfw -n.
# Example of a plain ipfw rule:
# add 65001 deny log ip from any to any via PREPROCESS_ME_USING_m4

IFS=$'\n'

files=$*
base_cmd="ipfw -q"

if [ $# -lt 1 ]; then
    echo "Usage: at least one file with plain ipfw rules as argument."
    exit 1
fi

for file in $files
do
    for line in $(grep -v ^# $file)
    do
        cmd="$base_cmd $line"
        eval $cmd
    done
done
