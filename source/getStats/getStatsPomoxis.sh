#!/bin/bash


################################################################################
# Name: getStatsPomoxis
# Use: Gets data of Q scores and coverage for an assembly using Pomoxis and 
#      if set creates a fasta file with contigs that mapped back to the
#      reference genome(s).
# Input:
#     -i: String with the assembly files
#         File name format: prefix--depthx-assembler-polisher--suffix.fasta
#             EX: test--10x-redbean-wtpoa-medianaka--01.fasta (wtpoa = polisher)
#             EX: test--10x-raven-medianaka--01.fasta
#         Note: Note more then one polisher can be listed so long as not 
#               seperated by a -- (see the first example)
#         Required: Yes
#     -r: String with a single fasta file containing all referencess
#         Required: yes
#     -m: Boolean to tell to extract the mapped contigs to a seperate fasta file 
#         If 0: Do not extract contigs 
#         If 1: Extract the contigs that mapped to a reference
#         Defualt: 0
#     -p: String with the prefix to add to the output directory and file names
#         Default: input (-i) fasta file name
#     -t: Integer with the number of threads
#         Default: 16
# Output: NEED TO UPDATE
#     Note: The suffix is the suffix of the input assembly file name
#     Dir: 
#        Name: prefix--depthx-assembler-polisher--sufix-pomoxis
#        Location: current working directory
#        Contents: All files produced by this script (including pomoxis files)
#     File:
#         Name: prefix--depthx-assembler-polisher--sufix-pomoxis-allQ.csv 
#         Location: prefix--depthx-assembler-polisher--suffix-pomoxis directory
#         Contents: Mean and median Q-scores (row1=header, row2 assembly, 
#                   cols=Qscores)
#     File:
#         Name: prefix--depthx-assembler-polisher--sufix-pomoxis-meanQ.csv 
#         Location: prefix--depthx-assembler-polisher--suffix-pomoxis directory
#         Contents: Mean Q scores for the assembly
#     File:
#         Name: prefix--depthx-assembler-polisher--sufix-pomoxis-medianQ.csv 
#         Location: prefix--depthx-assembler-polisher--suffix-pomoxis directory
#         Contents: Medain Q scores for the assembly
#     File:
#         Name: prefix--depthx-assembler-polisher--sufix-pomoxis-IsoletQ.csv
#         Location: prefix--depthx-assembler-polisher--suffix-pomoxis directory
#         Contents: Mean and median Q scores for each isolate (rows=isolet,
#                   cols=qscores)
#     File:
#         Name: prefix--detphx-assembler-polisher--sufix-pomoxis-IsoletCoverage.csv 
#         Location: prefix--depthx-assembler-polisher--suffix-pomoxis directory
#         Contents: Coverage scores for each isolet. (col1=isolet, 
#                   col2=coverate)
#     File:
#         Name: prefix-date-pomoxis-mappedContigs.fasta
#         Location: prefix--depthx-assembler-polisher--suffix-pomoxis directory
#         Contents: All contigs that mapped to the reference genome(s)
#     File: 
#         Name: prefix--depthx-assembler-polisher--suffix-pomoxis-contigsToKeep.txt
#         Location: prefix--depthx-assembler-polisher--suffix-pomoxis directory
#         Contents: A list of all contigs that mapped to teh reference genome
#                   Created: if -m is 1 
#                   Use: make the mappedContigs.fasta
#     File: 
#         Name: prefix--depthx-assembler-polisher--suffix-pomoxis--log.txt
#         Location: prefix--depthx-assembler-polisher--suffix-pomoxis directory
#         Contents: The log file for this script
# Requires:
#     Pomoxis (which requires minimap and other programs)
# Note:
#     Tab Width Used: 4 spaces
################################################################################


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-0: TOC (table of contents)
#     section-1: Variables used in this script
#     section-2: User input 
#     section-3: Get Q scores for the assembly
#     section-4: Get the stats (Q scores and coverage) for each isolet
#     section-5: Create fasta file with mapped contigs and exit
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-1:
# Script variables
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# input files
fastaStr="";
refStr="";

# output file names
nameStr="";
outStr="";
logStr="";

# output name componets
prefixStr="prefix"; # prefix to name files (and search for older files with)
depthStr=""; # get from assmebly file name
asmbStr=""; # get from assembly file name
polishStr=""; # get from assembly file name
suffixStr=""; # suffix from the file name (My runAsmbbler script uses numbers)

# command variables to use with eval
dateCmdStr="date +\"%Y-%m-%d %H:%M:%S\""; # command to get the date and time

# other script file locations
scriptDirStr="$(dirname "$0")";

# additional options
mapContigBool=0;

# house keeping variables
curDirStr="$(pwd)";
refListStr=""; # stores the name of each reference in the fasta file
threadsInt=16;
versionStr="NA"; # not sure how to get version so inputing NA

# help message
helpStr="$(basename "$0") -i <assembly.fasta> -r <reference.fasta> 
Input:
    -i: The assembly file (in fasta format) [Required]
        Format of file name: prefix--depthx-assembler-polisher--suffix.fasta
            EX: test--10x-raven-medaka--01.fasta
    -r: Fasta file with references [Required]
    -m: 1 or 0. [Default: 0]
        If 0: Do not extract contigs that mapped to the reference genomes
        If 1: Extract the contigs that mapped to the reference genomes
    -p: Prefix to add to the output directory and file names [Defualt: prefix]
    -t: number of threads [Default: 16]
Output: 
    Note: Suffix is the suffix from the assembly file
    Directory: prefix--depthx-assembler-polisher--sufix-pomoxis
        Contents: All output files (from pomixis and $(basename "$0") 
    File: prefix--depthx-assembler-polisher--sufix-pomoxis-allQ.csv 
        Contents: Mean and medain Q scores for the assembly
    File: prefix--depthx-assembler-polisher--sufix-pomoxis-IsoletQ.csv
        Contents: Mean and medain Q scores for each reference in the assembly
    File: prefix--sufix-pomoxis-IsoletCoverage.csv 
        Contents: Percent coverage for each refence in the assembly
    File: prefix-date-pomoxis-mappedContigs.fasta
        Contents: Contigs that mapped to the reference genomes"


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-2:
#     sub-1: Get user input
#     sub-2: check if user input a assembly and reference genome
#     sub-3: Build output directory and file names
#     sub-4: Check if output directory or log file exists
#     sub-5: Adjust file paths for output directory and cd into output directory
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

#*******************************************************************************
# Sec-2 Sub-1: get user input
#*******************************************************************************

while getopts ':i:h:m:p:r:t:x' option; do
# loop read in user input

    case "$option" in
        i ) fastaStr="$OPTARG";;
        h ) printf "%s\n" "$helpStr" >&2; exit;;
        m ) mapContigBool="$OPTARG";;
        p ) prefixStr="$OPTARG";;
        r ) refStr="$OPTARG";;
        t ) threadsInt="$OPTARG";;
        x ) printf "\-x is not a valid option\n%s\n" "$helpStr" >&2; exit 1;;
        : ) printf "\-%s requires an argument\n%s\n" "$OPTARG" "$helpStr" >&2;
			exit 1;;
        ? ) printf "\-%s is not a valid option\n%s\n" "${OPTARG}" "$helpStr" \
			>&2;
			exit 1;;
    esac # case decide input the user entered

done # loop read in user input

#*******************************************************************************
# Sec-2 Sub-2: Check if user input an assembly and reference genome
#*******************************************************************************

# check if the assembly file is valid
if [[ ! -f "$fastaStr" ]]; then
# if the user input assembly does not exist

    if [[ -d "$fastaStr" ]]; then
    # if the user input a directory instead of a fast file

        printf "Input assembly file %s is a directory," "$fastaStr" >&2;
        printf " please provide a fasta file instead\n" >&2;
        exit;

    # if the user input a directory instead of a fast file
   
    elif [[ "$fastaStr" == "" ]]; then
    # else if the user provided nothing

        printf "%s requires an assembly (as a fasta" "$(basename "$0")" >&2;
        printf " file) be provided with -i (for list of inputs use -h)" >&2;
        exit;

    fi # else if the user provided nothing

    printf "Input assembly file %s does not exist\n" "$fastaStr" >&2;
    exit;

fi # if the user input assembly does not exist

# check if the reference file is valid
if [[ ! -f "$refStr" ]]; then
# if the user input assembly does not exist

    if [[ -d "$refStr" ]]; then
    # if the user input a directory instead of a fast file

        printf "Input reference file %s is a directory," "$refStr" >&2;
        printf " please provide a fasta file instead\n" >&2;
        exit;

    # if the user input a directory instead of a fast file
   
    elif [[ "$refStr" == "" ]]; then
    # else if the user provided nothing

        printf "%s requires a reference (as a fasta" "$(basename "$0")" >&2;
        printf " file) be provided with -r (for list of inputs use -h)" >&2;
        exit;

    fi # else if the user provided nothing

    printf "Input reference file %s does not exist\n" "$refStr" >&2;
    exit;

fi # if the user input assembly does not exist

#*******************************************************************************
# Sec-2 Sub-3: Create the output file and directory names
#*******************************************************************************

# get the asssemlby stats from the file name (used for output and file names)
# (expected format prefix--depthx-assembler-polisher1-polisher2--suffix.fasta)
depthStr="$(printf "%s" "$(basename "$fastaStr")" |
	sed 's/\(^.*--\)\([0-9,NA]*\)[X,x].*/\2/')"; # get the read depth
asmbStr="$(printf "%s" "$(basename "$fastaStr")" |
	sed 's/\(^.*--\)\([0-9,NA]*[X,x]-\)\([^-]*\).*/\3/')"; # get the assembler
polishStr="$(printf "%s" "$(basename "$fastaStr")" |
	sed 's/\(^.*--\)\([0-9,NA]*[X,x]-\)\([^-]*-\)\(.*--\).*/\4/;
		s/^--.*//; 
		s/--$//')"; # get the polishers used (need to go till last --)
suffixStr="$(printf "%s" "$(basename "$fastaStr")" |
	sed 's/\(^.*--\)\([0-9,NA]*[X,x].*--\)\(.*\)\.fasta/\3/')";

# check if there was Coverage information in the file name
if [[ "$depthStr" == "$(basename "$fastaStr")" ]]; then 
    depthStr="NA";
fi # if there was no Coverage information in the file name

# check if there the assembler was in the file name
if [[ "$asmbStr" == "$(basename "$fastaStr")" ]]; then 
    asmbStr="NA";
fi # if there was no assembler in the file name

# check if there was a polisher or not
if [[ "$polishStr" == "$(basename "$fastaStr")" ]]; then 
    polishStr="NA";
fi # if there was no polisher in the file name

# check if there was a suffix or not
if [[ "$suffixStr" == "$(basename "$fastaStr")" ]]; then 
    suffixStr=""; # make sure the file name was not repeated
fi # if there was no suffix in the file name

# build the file and directory names
nameStr="$prefixStr--""$depthStr""x-$asmbStr-$polishStr--$suffixStr-pomoxis";
outStr="$nameStr";
logStr="$nameStr--log.txt";

#*******************************************************************************
# Sec-2 Sub-4: Check if output directory and log already exists (if not build)
#*******************************************************************************

# since there are multiple steps I will just check if the file already exists
# before running my commands
if [[ ! -d "$outStr" ]]; then
# if the output directory does not already exists

    mkdir "$outStr";
    cd "$outStr" || exit;
    printf "Start:\t%s\n" "$(eval "$dateCmdStr")" > "$logStr";

# if the output directory does not already exists

else
# else the output directory does exist (check if log file exists)

    cd "$outStr" || exit;

    # create or update the log file with the start time
    if [[ ! -f "$logStr" ]]; then # if the log file does not exists
        printf "Start:\t%s\n" "$(eval "$dateCmdStr")" > "$logStr";
    else # else the log file already exists
        printf "\n\nRe-start:\t%s" "$(eval "$dateCmdStr")" >> "$logStr";
    fi # check if log file exists

# else the output directory does exist (check if log file exists)
fi # check if the output directory exists

# print out the settings for the script
{ printf "Inputs (%s):\n" "$(basename "$0")";
  printf "\t-i %s\n\t-r %s\n\t-m %s\n" "$fastaStr" "$refStr" "$mapContigBool";
  printf "\t-o %s\n\t%s\n" "$outStr" "$threadsInt";
} >> "$logStr";


#*******************************************************************************
# Sec-2 Sub-5: Adjust file paths for working in the file directory
#*******************************************************************************

# Check and if needed adjust file paths for the new directory
    # ~/ is translated to /home/user before being send to this script

if [[ "${refStr:0:1}" != '/' ]]; then
    refStr="../$refStr"; # need to adujst for steping into the directory
fi # if-1 the reference path is not an absolute path

if [[ "${fastaStr:0:1}" != '/' ]]; then
    fastaStr="../$fastaStr"; # Need to adust for directory change (is no aboslute)
fi # if-1 the assmebly path is not an absolute path


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-3: Get the Q-scores for the assembly
#     sub-1: Run assess_assembly to make the assembly stats and summary file
#     sub-2: Get the Q-scores and coverage stats
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-3 Sub-1: Run assess_assembly to make the assembly stats and summary file
#*******************************************************************************

# set the pomoxis command entery in the log file
printf "Pomoxis commands:\n" >> "$logStr";

# get the stats for the assembly (if there is no summ file there will be no
# stat file (likely)
if [[ ! -f "$nameStr"-summ.txt ]]; then
# if assess_assembly has no been run (get assembly stats)

    # put assess_assembly settings in the log file
    printf "Running pomoxis asses_assembly\n";
    printf "\tassess_assembly -r %s -i %s" "$refStr" "$fastaStr" >> "$logStr";
    printf " -t %i -p %s\n" "$threadsInt" "$nameStr" >> "$logStr";

    # run assess_assembly to get stat and summ files
    assess_assembly -r "$refStr" -i "$fastaStr" -t "$threadsInt" -p "$nameStr";

    # renaming files due to pomoxis prefix command acting oddly sometimes
    # also get rid of underscores
    mv ./*.bam "$nameStr.bam"
    mv ./*.bam.bai "$nameStr.bam.bai";
    mv ./*_stats.txt "$nameStr-stats.txt";
    mv ./*_summ.txt "$nameStr-summ.txt";
        # for my settings pomoxis only produces 4 files, other settings add more

    # (clean up)  remove indexing files made in ref and assembly directories
    rm "$fastaStr.chunks"*;
    rm "$refStr.fai";
    rm "$refStr.mmi";

# if assess_assembly has no been run (get assembly stats)

else
# else assess_assembly has already been run (so summ and stats file exist?)

    printf "\tPomoxis assess_assembly has already been run\n";
    printf "\tPomoxis assess_assembly has already been run\n" >> "$logStr";

# else assess_assembly has already been run (so summ and stats file exist?)
fi # if-1 assess_assembly has no been run (get assembly stats)

#*******************************************************************************
# Sec-3 Sub-2: Get Q scores and coverage values
#*******************************************************************************

if [[ ! -f "$nameStr-Q.csv" ]]; then
# if need to make a spreed sheet with the Q scores and coverage

    printf "Getting Q scores and % coverages from %s-summ.txt\n" "$nameStr";
    printf "Getting Q scores and % coverage from %s-summ.txt\n" "$nameStr" \
	>> "$logStr";

    # get list of references (so can make sure all references in final report)
    refListStr="$(grep ">" < "$refStr" | sed 's/>//; s/^\s\+//; s/\s\+$//')";
        # grep grabs each entry in the reference file
        # sed removes the > and any leading or trailing white space

    awk -f "../$scriptDirStr/pomoxisIsoletQ.awk" -v depthStr="$depthStr" \
		-v asmbStr="$asmbStr" -v polStr="$polishStr" \
		-v allRefStr="$refListStr" -v inStr="$(basename "$fastaStr")" \
		-v verStr="$versionStr" < "$nameStr-summ.txt" > "$nameStr-Q.csv";

# if have not extracted the Q scores and coverage data yet

else
# else have already extracted the isolet coverage

    {
        printf "The Q scores and coverage for each isolet has already been" 
        printf "extracted\n";
    } >&2;

    {
        printf "The Q scores and coverage for each isolet has already been" 
        printf "extracted\n";
    } >> "$logStr";

# else have already extracted the isolet coverage
fi # check if need to extract the isolet coverage


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-5: Create fasta with mapped contigs and exit
#     sub-1: Create a fasta file with only contigs that mappped to the assembly
#     sub-2: Commands before exit
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-5 Sub-1: Make fasta file with contigs that mapped to the reference 
#*******************************************************************************

if [[ $mapContigBool == 1 ]]; then
# if-1 user wanted a fasta file with only the mapped contigs

    # Check if the mapped contigs have not been extracted yet
    if [[ -f "$nameStr-mappedContigs.fasta" ]]; then
    # if have already grabbed all the contigs of intrest
  
        printf "%s has already had the mapped contigs extracted (see %s)\n" \
			"$fastaStr" "$nameStr-mappedContigs.fasta";
        printf "%s has already had the mapped contigs extracted (see %s)\n" \
			"$fastaStr" "$nameStr-mappedContigs.fasta" >> "$logStr";

        cd "$curDirStr" || exit;
        exit; # this is the last command so good point to exit

    fi # if have already grabbed all the contigs of intrest
    
    printf "extracting contigs that mapped to the reference genomes\n";
    printf "\textracting contigs that mapped to the reference genomes\n" \
		>> "$logStr";

    # Find the contigs that mapped to my assembly
    tail -n+2 "$nameStr-stats.txt" | 
		awk 'BEGIN {FS=OFS="\t"}; {print $1}' | 
		sed 's/_chunk.*//g' |
		sort -u > "$nameStr-contigsToKeep.txt";
         # awk grabs the contig number, while sed removes the chunk information
         # added by pomoxis. Tail enures that we do not grab the header
         # sort removes the duplicate contigs (each was a chunk)

    # Filter out contigs that did not map to any references
    sed -z 's/\n/~/g; s/\(>[^~]*\)/\n\1\n/g; s/~//g' "$fastaStr" |
		tail -n+2 |
		grep -A 1 -f "$nameStr-contigsToKeep.txt" | 
		sed 's/--//g' > "$nameStr-mappedContigs.fasta";
		# sed makes sure the fasta has one line for each header and one line 
		# for each sequence
		# tail removes the extran new line at the top added by sed
		# grep grabs only the contigs that were mapped
		# last sed removes the -- added by grep (is a coman for grep to avoid)

fi # if-1 user wanted a fasta file with only the mapped contigs

#*******************************************************************************
# Sec-5 Sub-2: Finall commands and exit
#*******************************************************************************

# print the end time to the log
printf "End:\t%s" "$(eval "$dateCmdStr")" >> "$logStr";

cd "$curDirStr" || exit; # go back to the starting directory

exit;
