#!/bin/bash

################################################################################
# Use: Holds functions for use with getStatMetaQuast.sh, getStatsPomoxis 
#      scripts, and other getStats.sh scripts
# Functions:
#     getAsmb:
#         Use: get the assembler from a file name using dashes.
#         File format: prefix--depthx-assembler-polisher1-polisher2-suffix.fasta
#     getDepth:
#         Use: get the read depth from a file name using dashes.
#         File format: prefix--depthx-assembler-polisher1-polisher2-suffix.fasta
#     getId:
#         Use: get the idenity from an assemlby file name with dashes
#         Format: prefix--depthx-assembler-polisher1-polisher2--id-suffix.fasta
#     getPrefix:
#         Use: get the prefix from a file name using dashes.
#         File format: prefix--depthx-assembler-polisher1-polisher2-suffix.fasta
#     getPolisher:
#         Use: get the polisher from a file name using dashes.
#         File format: prefix--depthx-assembler-polisher1-polisher2-suffix.fasta
#     getSuffix:
#         Use: get the suffix from a file name using dashes.
#         File format: prefix--depthx-assembler-polisher1-polisher2-suffix.fasta
# Notes:
#     $?: Gets the return value from the function
#     Call: source statsFun.sh # near top of main script
################################################################################


################################################################################
# Name: getAsmb
# Use: get the assembler from a file name using dashes.
# Input:
#     $1: String with the assembly file name to get the assembler from
#         Format: prefix--depthx-assembler-polisher1-polisher2-suffix.fasta
# Output: String with the assembler used or NA (if no assembler)
################################################################################
getAsmb()
{ # getAsmb function
    asmbStr="$(printf "%s" "$(basename "$1")" |
		sed 's/\(^.*--\)\([0-9,NA]*[X,x]-\)\([^-]*\).*/\3/')";

    # check if there the assembler was in the file name
    if [[ "$asmbStr" == "$(basename "$1")" ]]; then 
        asmbStr="NA";
    fi # if there was no assembler in the file name

	printf "%s" "$asmbStr";
} # getAsmb function


################################################################################
# Name: getDepth
# Use: get the read depth from a file name using dashes.
# Input:
#     $1: String with the assembly file name to get the read depth from
#         Format: prefix--depthx-assembler-polisher1-polisher2-suffix.fasta
# Output: String with Integer with the read depth used or NA (if no assembler)
################################################################################
getDepth()
{ # getDepth function
    depthStr="$(printf "%s" "$(basename "$1")" |
		sed 's/\(^.*--\)\([0-9,NA]*\)[X,x].*/\2/')"; # get the read depth

    # check if there was the read depth in the file name
    if [[ "$depthStr" == "$(basename "$1")" ]]; then 
        depthStr="NA";
    fi # if there was the read depth in the file name

	printf "%s" "$depthStr";
} # getDepth function

################################################################################
# Name: getId
# Use: get the id from an assembly file name using dashes.
# Input:
#     $1: String with the assembly file name to get the id from
#         Format: prefix--depthx-assembler-polisher1-polisher2--id-suffix.fasta
# Output: String with the id used or NA (if no assembler)
################################################################################
getId()
{ # getAsmb function
    idStr="$(printf "%s" "$(basename "$1")" |
			sed 's/\(^.*--[0-9,NA]*[X,x].*--\)\([0-9]*\).*/\2/')";

    # check if there the assembler was in the file name
    if [[ "$idStr" == "$(basename "$1")" ]]; then 
        idStr="NA";
    fi # if there was no assembler in the file name

	printf "%s" "$idStr";
} # getAsmb function


################################################################################
# Name: getPrefix
# Use: get the prefix from a file name using dashes.
# Input:
#     $1: String with the assembly file name to get the prefix from
#         Format: prefix--depthx-assembler-polisher1-polisher2-suffix.fasta
# Output: String with the prefix used or "prefix" (if no assembler)
################################################################################
getPrefix()
{ # getPrefix function
    prefStr="$(printf "%s" "$(basename "$1")" |
		sed 's/\(^.*\)--[0-9,NA]*[X,x].*/\1/')"; # get the prefix

    # check if there was a prefix in the file name
    if [[ "$prefStr" == "$(basename "$1")" ]]; then 
        prefStr="prefix";
    fi # if there was a prefix in the file name

	printf "%s" "$prefStr";
} # getPrefix function


################################################################################
# Name: getPolisher
# Use: get the polisher from a file name using dashes.
# Input:
#     $1: String with the assembly file name to get the polisher from
#         Format: prefix--depthx-assembler-polisher1-polisher2-suffix.fasta
# Output: String with the polisher used or NA (if no assembler)
################################################################################
getPolisher()
{ # getFileNameDash function
    polStr="$(printf "%s" "$(basename "$1")" |
		sed 's/\(^.*--\)\([0-9,NA]*[X,x]-\)\([^-]*-\)\(.*--\).*/\4/;
			s/^--.*//; 
			s/--$//')"; # get the polishers used (need to go till last --)

    # check if there the polisher was in the file name
    if [[ "$polStr" == "$(basename "$1")" ]]; then 
        polStr="NA";
    fi # if there was no polisher in the file name

	printf "%s" "$polStr";
} # getFileNameDash function


################################################################################
# Name: getSuffix
# Use: get the suffix from a file name using dashes.
# Input:
#     $1: String with the assembly file name to get the suffix from
#         Format: prefix--depthx-assembler-polisher1-polisher2-suffix.fasta
# Output: String with the suffix used or NA (if no assembler)
################################################################################
getSuffix()
{ # getFileNameDash function
    sufStr="$(printf "%s" "$(basename "$1")" |
		sed 's/\(^.*--\)\([0-9,NA]*[X,x].*--\)\(.*\)\.fasta/\3/')";

    # check if there the polisher was in the file name
    if [[ "$sufStr" == "$(basename "$1")" ]]; then 
        sufStr="NA";
    fi # if there was no polisher in the file name

	printf "%s" "$sufStr";
} # getFileNameDash function



# build the file and directory names
nameStr="$prefixStr--""$depthStr""x-$asmbStr-$polishStr--$suffixStr-pomoxis";
outStr="$nameStr";
logStr="$nameStr--log.txt";

