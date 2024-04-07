#! /bin/sh -
# From sh(1): A “--” or plain ‘-’ will stop option processing
# set -vx
# set -x

### LINE BY LINE IPFW SYNTAX CHECKER ###
# This script expects files with plain ipfw rule syntax, examples:
# add deny log ip from any to any via INTERFACE_IS_NOT_CHECKED
# add 98765 deny log ip from any to any via BAD_RULENUMBER
# add 12345 deny log ip from any to an_error via WOULD_BE_CATCHED_BY_-n
#
# While there is ipfw -n for doing dry runs it stops at the first
# occurrence of a rule with bad syntax. This script processes the output
# of ipfw -n file_with_plain_rules and shows you everything ipfw -n would
# complain about in one single output.
# This script also indicates if there is no rule number in a syntactically
# correct rule as well as the presence of rules with a rule
# number >= 65535 the latter of which is not caught by ipfw -n

# Tested on FreeBSD 14.0

# NOTE: typical shell syntax such as {fwcmd} is not plain ipfw rule syntax.
# ipfw's -n option considers this as a syntax error.

# Saving all args (space separated) in case somehow the IFS problem can be solved
files=$*

# IFS defauls to having newlines, spaces and tabs as delimiters.
# Line-by-line ipfw rule processing requires limiting IFS to newlines.
# Otherwise the for-loops would consider each space-separated string in
# a line as an ipfw rule and ipfw's -n option doesn't like that.
IFS=$'\n' # see also: IFS-HATES-ME-PART below

tempname=$(basename $0) # tmpfile[123] created will be named after the scriptname

# tmpfile1: storage for single lines (one rule per line) during rule extraction
tmpfile1=$(mktemp -q /tmp/${tempname}.XXXXXX)
# tmpfile2: all extracted rules are accumulated here for the checks using grep
tmpfile2=$(mktemp -q /tmp/${tempname}.XXXXXX)
# ipfw -n's complaints collected from stderr, originating from tmpfile1
tmpfile3=$(mktemp -q /tmp/${tempname}.XXXXXX) # basically the original purpose of this script

if [ $# -lt 1 ]; then
    echo "Usage: at least one file containing plain ipfw rules as argument."
    exit 1
fi

if [ $# -gt 1 ]; then # IFS-HATES-ME-related
    echo "Usage: \$IFS hates this script so it can only process one file at a time."
    exit 1
fi

check_rules_line_by_line() {
    for file in $files # single rule extraction
    do
        ##### IFS-HATES-ME-PART #####
        # Not being able to change IFS on the fly prevents this
        # script from processing multiple rule files as per-line
        # rule processing requires a newline-only IFS delimiter.
        # See also lines marked as follows: IFS-HATES-ME-related 
        # Stuff tried:
        # IFS=$' ' and changing back to IFS=$'\n'
        # for line in $(IFS=: command cat $file)
        for line in $(cat $file)
        do # only one line with a single rule at a time... 
            echo $line > $tmpfile1 # ...in order to collect ipfw -n's complaints
            # main data to be processed is collected below, see also remarks at var definitions
            ipfw -n $tmpfile1 >> $tmpfile2 2>> $tmpfile3
        done
        ##### END OF IFS-HATES-ME-PART #####
        printf "\n"

        echo "Forgot rule number?"
        echo "ipfw -n (dry run) misleadingly assigns 00000 in this case."
        echo "00000 will be converted to the penultimate rule number."
        # actually adding a rule without rule number converts -n's 00000 to:
        # current penultimate rule number plus value of sysctl
        # net.inet.ip.fw.autoinc_step while making sure that the default
        # rule is not overridden. Max auto rule number is 65535 less the 
        # value of net.inet.ip.fw.autoinc_step.
        grep -E --color "^[0]{5,5}" $tmpfile2
        printf "\n"

        echo "Touching the default rule (65535) only works with ipfw -n!"
        echo "You'll get 'ipfw: getsockopt(IP_FW_XADD): Invalid argument'!"
        grep -E --color '^(65535)' $tmpfile2
        printf "\n"

        echo "No rule number greater than 65535 allowed! ipfw -n will not complain though:"
        rulemaxcheck=$(grep -E -o '^[0-9]{5,5}' $tmpfile2)
        for rulenumber in $rulemaxcheck
        do
            if [ $rulenumber -gt 65535 ]; then
                echo -e "\033[1;31mRule $rulenumber is greater than maximum number 65535.\033[0m"
            fi
        done
        printf "\n"

        echo -e "\033[1;36mCorrect below errors first.\033[0m This is what ipfw -n complains about."
        echo "Typically, ipfw -n complains about typos and shell syntax such as { or } or \$."
        echo -e "\033[1;36mThen run again to catch forgotten rule numbers and rule numbers >= 65535.\033[0m"
        sed -i"" -e "s/Line\ 1:/-->/g" $tmpfile3
        grep -E --color ".*.$" $tmpfile3
    done
    printf "\n"
    
    # Final remarks for the user of this script
    echo "Consider cleaning your /tmp directory."
    echo "Do ipfw -n file_with_rules as a final syntax check."
    echo -e "\033[1;36mNote that neither this script nor ipfw -n can find faulty rule semantics.\033[0m"
    echo "Rule files processed by this script:"
    realpath $files # IFS-HATES-ME-related
}

check_rules_line_by_line

# cleanup, tmpfile3 seems to remain untruncated in /tmp for whatever reason
truncate -s 0 $tmpfile1
truncate -s 0 $tmpfile2
truncate -s 0 $tmpfile3
rm $tmpfile1
rm $tmpfile2
rm $tmpfile3

# PSA 1: you can preprocess your rule file (with or without -n) like this:
# ipfw -n -p /usr/bin/m4 --define=CHANGE_THIS=TO_THIS /full/path/to/rulefile
# More than one --define is possible.

# PSA 2: run /usr/share/examples/ipfw/change_rules.sh in a tmux or screen session
# and reattach to the session running change_rules.sh, provided you did not lock
# yourself out (change_rules.sh would restore your old rules in this case).
