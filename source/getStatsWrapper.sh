#!/bin/bash

################################################################################
# Use: Uses pomoxis and metaQuast to get stats on input assemblies
# Input:
#     -i: String with the path to a directory with input assemblies (as fasta)
#         File Name Format: prefix--depthx-assembler-polisher--suffix.fasta
#             EX: voltrax--10x-raven--01.fasta 
#             EX: voltrax--10x-redbean-wtpoa--run.fasta
#         Required: Yes
#     -r: String with the path to the input reference(s) directory (as fasta)
#         Required: Yes
#     -h: print the help message and exit
#     -m: Boolean (0 or 1) that tells getStatsPomoxis.sh to make a fasta file
#         containg only the mapped contigs. 
#         Use: The mapped contig fasta file will then be used with 
#              getStatsMetaQuast.sh
#         If 0: Do not create a fasta file with the mapped contigs
#         If 1: Create a fasta file with the mappped contigs
#         Default: 0
#     -p: String with the prefix of the output directories and file names 
#         Default: prefix
#     -t: Integer with the number of threads to use
#         Default: 16
# Output:
#     Dir:
#         Name: prefix--assemblyStats
#         Location: working directory
#         Contents: Files produced by this script, metaQuast, and pomoxis
#     Dir:
#         Name: prefix--pomoxis
#         Location: prefix--assemblyStats
#         Contents: holds the files and directories made by getStatsPomoxis.sh
#     Dir:
#         Name: metaQuast--output
#         Location: prefix--assemblyStats
#         Contents: files ad directories maded by getStatsMetaQuast.sh
#     Dir:
#         Name: prefix--mappedContigs
#         Location: prefix--assemblyStats
#         Contents: fasta files with only mapped contigs to a reference for each 
#                   assembly (fastas made with getStatsPomoxis.sh)
#         Note: Only made if -m 1 is used
#     File:
#         Name: prefix--pomoxis-Q.tsv
#         Location: prefix--assemblyStats
#         Contents: Mean and medain Q scores for the assembly (as a whole)
#         From: getStatsPomoxis.sh
#     File:
#         Name: prefix--pomoxis-Isolet.tsv
#         Location: prefix--assemblyStats
#         Contents: Coverage, Mean Q score, and medain Q score for each isolet
#         From: getStatsPomoxis.sh
#     File:
#         Name: prefix--metaStats-combined.tsv
#         Location: prefix--assemblyStats
#         Contents: combined assembly stats extracted with metaQuast
#         From: getStatsMetaQuast.sh
#     File:
#         Name: prefix--metaStats-Isolet.tsv
#         Location: prefix--assemblyStats
#         Contents: Stats from metaQuast for each isolet
#         From: getStatsMetaQuast.sh
#     File:
#         Name: prefix--assemblyStats--log.txt
#         Location: prefix--assemblyStats
#         Contents: log for this script
# Requires:
#     getStatsPomoxis.sh:
#         Uses: Pomoxis
#     rmExtraHeader.awk (for combing pomoxis output)
#     getStatsMetaQaust.sh:
#         Uses: metaQuast, checkInputFun.sh, metaQuastExtract.awk
# Notes:
#     Tab Width: set to 5 spaces
################################################################################


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-0: TOC (table of contents)
#     section-1: Variables
#         sub-1: loading in files that have functions (source file.sh)
#         sub-2: variables for user input and file names
#         sub-3: Varaibles to use with eval or misc variables
#         sub-4: help message
#     section-2: get and check user input
#         sub-1: get user input
#         sub-2: check if assembly input is valid (directory with fasta files)
#         sub-3: check if reference input is valid (directory with fasta files)
#         sub-4: create output directory and make log
#     section-3: get stats
#         sub-1: get stats with pomoxis
#         sub-2: get stats with medaka
#     section-4: final commands and exit
#         sub-1: update log (finsh time for now) and exit
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-1: Variables
#     sub-1: loading in files that have functions
#     sub-2: variables for user input and file names
#     sub-3: Varaibles to use with eval or misc variables
#     sub-4: help message
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-1 Sub-1: files that have functions used in script
#*******************************************************************************

source "$(dirname "$0")/checkInputFun.sh"; # input check functions

#*******************************************************************************
# Sec-1 Sub-2: variables for user input and file names
#*******************************************************************************

# user input variables
asmbStr=""; # input assembly
refStr=""; # input references
mapContigBool=0; # make a mappedContig.fast file?
prefStr=""; # prefix to use in directory and file names
threadsInt=16; # number of threads to use

# file name variables
dirStr=""; # output directory
logStr=""; # log file

#*******************************************************************************
# Sec-1 Sub-3: Varaibles to use with eval or misc variables
#*******************************************************************************

# Variables to use with eval (hold commands)
dateCmdStr="$(date +"%Y%m%d %H:%M:%S")";

# script file directory (holds getStatsPomoxis and getStatsMetaquast)
scriptDirStr="$(dirname "$0")/getStats";


# misc variables
oldDirStr="$(pwd)"; # holds the directory I started in
searchFastStr=("fasta" "fasta.gz");

#*******************************************************************************
# Sec-1 Sub-4: help message
#*******************************************************************************

helpStr="$(basename "$0") [-h] -i <assembly.fasta> -r <reference.fasta>
Use: Runs pomoxis and metaQaust to get assemblie statsitics
Input:
    -i: Directory with assemblies (as fasta) [Required] 
        File Name Format: prefix--depthx-assembler-polisher--suffix.fasta
            EX: voltrax--10x-raven--01.fasta 
            EX: voltrax--10x-redbean-wtpoa--run.fasta
    -r: Directory with the reference(s) (as fasta) [Required]
    -h: print this help message and exit
    -m: 0: Run metaQuast with the input reference files
        1: Create a fasta file with only mapped contigs to use with metaQuast
        Default: 0
    -p: Prefix of the output directories and file names [Default: $prefStr]
    -t: Number of threads to use [Default: 16]
Output:
    prefix--assemblyStats: Directory to hold everything
    prefix--pomoxis-Q.tsv: Assembly Q scores (entire assembly)
    prefix--pomoxis-Isolet.tsv: Assembly Q scores and coverage for each 
                                reference
    prefix--metaStats-combined.tsv: Stats extrated from metaQuast combined
                                reference report
    prefix--metaStats-Isolet.tsv: Stats extracted from the metaQuast report for
                                  each isolet"


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-2: get and check user input
#     sub-1: get user input
#     sub-2: check if assembly input is valid (directory with fasta files)
#     sub-3: check if reference input is valid (directory with fasta files)
#     sub-4: create output directory and make log
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-2 Sub-1: get user input
#*******************************************************************************

while getopts ':i:h:m:p:r:t:x' option; do
# loop get user input

    case "$option" in
        i ) asmbStr="$OPTARG";;
        h ) printf "%s\n" "$helpStr" >&2; exit;;
        m ) mapContigBool="$OPTARG";;
        p ) prefStr="$OPTARG";;
        r ) refStr="$OPTARG";;
        t ) threadsInt="$OPTARG";;
        x ) printf "-x is not a valid option\n%s\n" "$helpStr" >&2; exit 1;;
        : ) printf "-%s requires an argument\n%s\n" "$OPTARG" "$helpStr" >&2;
			exit 1;;
        ? ) printf "\-%s is not a valid option\n%s\n" "${OPTARG}" "$helpStr" \
			>&2; exit 1;;
    esac

done # loop get user input

#*******************************************************************************
# Sec-2 Sub-2: check if assembly input is valid (directory with fasta files)
#*******************************************************************************

asmbStr="${asmbStr%/}"; # if a trailing / get rid of (personal preference)

if checkFastxDir "$asmbStr" "a" "assembly (-i)" 0 0 -lt 1; then
    exit;
fi # if not fasta files in the assembly directory (checkFastxDir prints error)
    # source: checkInputFun.sh
    # checkFastaxDir fastaDir lookForFasta partOfErrorMessage \
        # DoNotReturnNumberFasta PrintErrorMessages

#*******************************************************************************
# Sec-2 Sub-3: check if reference input is valid (directory with fasta files)
#*******************************************************************************

refStr="${refStr%/}"; # if a trailing / get rid of (personal preference)

if checkFastxDir "$refStr" "a" "assembly (-i)" 0 0 -lt 1; then 
    exit; # checkFastxDir printed error message
fi # if not fasta files exit (also looks for fasta.gz)
    # source: checkInputFun.sh
    # checkFastaxDir fastaDir lookForFasta partOfErrorMessage \
        # DoNotReturnNumberFasta PrintErrorMessages

#*******************************************************************************
# Sec-2 Sub-4: create output directory, update file paths,  and make log
#*******************************************************************************

prefStr="${prefStr%/}"; # get rid of a trailing slash (otherwise no prefix)
    # will force user to do // to get no prefix, but is preffered
dirStr="$prefStr--assemblyStats";
logStr="$dirStr/$prefStr--assemblyStats--log.txt";

# checking and creating output directory (if can create)
if checkOutDirLog "$dirStr" "$logStr" "" -lt 1; then
    exit;  
fi # if the path to the directory does not exist (error already printed)
   # checkOutDirLog outDirName logNamePrefix noTimeLog; source checkInputFun.sh

# check changes log name to have directory on
logStr="$prefStr--assemblyStats--log.txt"; # ending added by checkOutDirLog

# two directorys back for pomoxis directory
if [[ "${refStr:0:1}" != '/' ]]; then
    refStr="../../$refStr";
fi # if the user did not provide an absolute path

if [[ "${asmbStr:0:1}" != '/' ]]; then
    asmbStr="../../$asmbStr";
fi # if the user did not provide an absolute path

cd "$dirStr" || exit; # move into the directory to work in

# print user input into the log
{
    printf "Input for %s:\n" "$(basename "$0")";
    printf "\t-i %s\n\t-r %s\n\t-m %s\n" "$asmbStr" "$refStr" "$mapContigBool";
    printf "\t-p %s\n\t-t %s\n\n" "$prefStr" "$threadsInt";
} >> "$logStr";


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-3: get stats
#     sub-1: get stats with pomoxis
#     sub-2: get stats with metaquast
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-3 Sub-1: get stats with pomoxis
#*******************************************************************************

if [[ ! -f "$prefStr--pomoxis" ]]; then
     mkdir "$prefStr--pomoxis";
fi # create pomoxis directory to hold pomoxis output

cd "$prefStr--pomoxis" || exit;
logStr="../$logStr";

# make a combined reference file (need to directory for metaQuast)
cat "$refStr"/*.fasta > ref.fasta; # do not want gz files (NEED TO CHECK FOR)

for strFileType in "${searchFastStr[@]}"; do
# loop though fasta and fasta.gz

    for strFasta in "$asmbStr"/*".$strFileType"; do
    # loop though all assemblys to run pomoxis
        
        if [[ ! -f "$strFasta" ]]; then
            continue;
        fi # if on null case just move on (is end of loop)

        # I am letting getStatsPomoxis.sh do my error checking for me
       # put script command in the log
        printf "Running getStatsPomoxis.sh\n";
        {
            printf "\tgetStatsPomoxis.sh\\\n\t\t-i %s\\\n" "$strFasta";
            printf "\t\t-r ref.fasta\\\n\t\t-m %s\\\n" "$mapContigBool";
            printf "\t\t-p %s\\\n\t\t-t %s\n\n" "$prefStr" "$threadsInt";
        } >> "$logStr";

        bash "../../$scriptDirStr/getStatsPomoxis.sh" -i "$strFasta" \
			-r "ref.fasta" -m "$mapContigBool" -p "$prefStr" -t "$threadsInt";
       
    done # loop though all assemblys to run pomoxis

done # loop though fasta and fasta.gz

rm ref.fasta; # this was just a temporary file

# combine all seperate data files into one data file
# awk makes sure only one header is input
cat ./**pomoxis/*Q.csv | 
	awk -f "../../$scriptDirStr/rmExtraHeader.awk" -v delimStr=","\
		-v headStr="Input" \
	>> "../$prefStr--pomoxis-Q.csv";

if [[ $mapContigBool == 1 ]]; then
# if created fasta files with just the mapped contigs

    asmbStr="$prefStr--mappedContigs"; # reseting for later analysis
    mkdir "../$asmbStr"; # so I do not have to reset asmbStr later
    cp ./**pomoxis/*mappedContigs.fasta "../$asmbStr";

fi # if created fasta files with just the mapped contigs

cd .. || exit; # move up to the working directory 

# remove one set of ../ to get to working dir
if [[ "${refStr:0:1}" != '/' ]]; then
    refStr="${refStr#../}";
fi # if the user did not provide an absolute path

if [[ "${asmbStr:0:1}" != '/' ]]; then
    asmbStr="${asmbStr#../}";
fi # if the user did not provide an absolute path

logStr="${logStr#../}";

#*******************************************************************************
# Sec-3 Sub-2: get stats with metaQuast
#*******************************************************************************

# metaQuast is eaiser to check then pomoxis
if [[ ! -f "$prefStr--metaQuast/$prefStr--metaStats-isolet.csv" ]]; then
# if have not run metaQuast completely yet (isoletStats is last file made)

    # put script command in the log
    printf "Running getStatsMetaQuast.sh\n";

    {
        printf "\tgetStatsMetaQuast.sh\\\n\t\t-i %s\\\n" "$asmbStr";
        printf "\t\t-r %s\\\n\t\t-p %s\\\n"  "$refStr" "$prefStr";
        printf "\t\t-t %s\n\n" "$threadsInt";
    } >> "$logStr";

    bash "../$scriptDirStr/getStatsMetaQuast.sh" -i "$asmbStr" -r "$refStr" \
		-p "$prefStr" -t "$threadsInt";

    cp "$prefStr--metaQuast/$prefStr--metaStats-isolet.csv" ./;
    cp "$prefStr--metaQuast/$prefStr--metaStats-combined.csv" ./;

# if have not run metaQuast completely yet (isoletStats is last file made)

else
# else metaQuast has already been run

    printf "metaQuast has already been run\n";
    printf "metaQuast has already been run\n" >> "$logStr";

# else metaQuast has already been run
fi # check if metaQuast has been run


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-4: final commands and exit
#     sub-1: update log (finsh time for now) and exit
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-4 Sub-1: update log and exit
#*******************************************************************************

printf "End:\t%s" "$(date +"%Y%m%d %H:%M:%S")" >> "$logStr";

cd "$oldDirStr" || exit;
exit;
