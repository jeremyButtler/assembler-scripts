#!/bin/bash


################################################################################
# Use: Runs the input though metaquast and grabs data I am intrested from the
#      report.csv file for the indivdual and combined references
# input: 
#     -i: String with the directory holding the assemblies (should be .fasta)
#         File name format: prefix--coveragex-assembler-polisher--sufix.fasta
#                 prefix: starting name of the file (seperate by -- or __)
#                 Coverage: read depth (if none use NAx)
#                 assembler: is the assembler used to build the assembly
#                 polisher: is the polisher used on the assembly (if none leave
#                           blank or use NA) 
#                 suffix: and ending to the file (seperate by -- or __)
#             Ex: voltrax--10x-raven-medaka--01.fasta
#         Required: yes
#     -r: String with the directory holding the reference genomes
#         Required: yes
#     -p: String with the prefix to name everything
#         Default: metaQuast
#     -t: Integer with the number of theads to use
#         Default: 16
# output:
#     Directory: 
#         Name: prefix--metaQuast
#         Location: Working directory, or path in the prefix 
#         Holds: Reports, metaquast output (as directory), and logs
#     Directory: 
#         Name: metaQuast-output
#         Location: prefix--metaQuast
#         Holds: contains all of metaquasts output
#     File: 
#         Name: prefix--metaStats-combined.csv
#         Location: prefix--metaQuast
#         Contents: The stats from the combined ref transposed_report.csv
#     File: 
#         Name: prefix--metaStats-isolet.csv
#         Location: prefix--metaQuast
#         Contents: The stats from each isolet transposed_report.csv
#     File: 
#         Name: prefix--meta-log.txt
#         Location: prefix--metaQuast
#         Contents: Logged output, incuding metaQuast version, input paramters,
#                   and the filters used
# reqiures:
#     metaquast.py + dependcys to run metaquast.py
#     checkInputFun.sh
#     metaQuastExtract.awk
################################################################################


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-0: Table of contents (TOC)
#     sec-1: Variables used in the script
#     sec-2: Get user input and build file and directoy names
#     sec-3: Check user input and create nesscary files and directories
#     sec-4: Extract data from metaQuast reports
#     sec-5: Final logging (end date/time) and exit
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-1: Variables used in the script (including hardcoded variables)
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# other files (one directory up)
source "$(dirname "$0")/../checkInputFun.sh" # input check functions

# input
asmbStr=""; # assebmlys to use metaQuast on
refStr=""; # directory with references to use with metaquast
threadsInt=16;
prefStr=""; # prefix (-p)

# output file names
outDirStr="--metaQuast"; # prefix added on in section 2 (output directory)
outCombFileStr="--metaStats-combined.csv"; # name to append for the stats
outIsoFileStr="--metaStats-isolet.csv"; # name to append for the stats
logStr="--meta-log.txt";
quastDirStr="metaquast-output"; # place to store the metaquast output

# locations of files with the stats from metaquast
grabFileStr="transposed_report.tsv";
isoletPathStr="runs_per_reference"; # assembly stats for each isolet
combPathStr="combined_reference/$grabFileStr";
    # average assembly stats (all isolets averaged together)

# Location of scripts used in this script (mainly awk)
scriptDirStr="$(dirname "$0")";

# taks keeping variables
nameStr=""; # name for each isolet
loopBool=0; # is this the first loop

# program version variables
versionStr="$(metaquast.py --version | sed 's/,//g')";

# help message
helpStr="$(basename "$0") -i <assembly-directory> -r <reference-directory>
Use: Uses metaQuast and reference genomes to get statistics on input assemblies.
Input: 
    -i: Directory holding the assemblies (should be .fasta) [Required].
        Name format: prefix--Coveragex-assembler-polisher--sufix.fasta
            EX: voltrax--10x-redbean-wtpoa-medaka--1.fasta (2 or more polishers)
            EX: voltrax--10x-redbean-medaka--Something.fasta (one polisher)
            EX: voltrax--10x-redbean--10-go.fasta (no polisher)
    -r: Directory holding the reference genomes [Required]
    -p: Prefix to name everything [Default: metaQuast]
    -t: Number of theads [Default: 16]
Output:
    prefix--metaQuast: Holds all output. (in the working directory)
    metaQuast-output: Holds the output from metaQuast (in prefix--metaQuast)
    prefix--metaStats.csv: File with assembly stats (in prefix--metaQuast)
    prefix--meta-log.txt: Log file for $(basename "$0") (this script)
";


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-2: Get user input and create file and directory names
#     sub-1: Get user arguments
#     sub-2: Set up directory and file names
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-2 Sub-1: get the user input
#*******************************************************************************

while getopts ':i:r:f:h:p:t:x' option; do
# loop to read in user input

    case "$option" in
        i ) asmbStr="$OPTARG";;
        r ) refStr="$OPTARG";;
        f ) filtStr="$OPTARG";;
        h ) echo "$helpStr" >&2; exit;;
        p ) prefStr="$OPTARG";;
        t ) threadsInt=$OPTARG;;
        x ) printf "\-x is not a valid option\n%s\n" "$helpStr" >&2; exit 1;;
        : ) printf "\-%s requires an agurment (\-h shows optons)" "$OPTARG" \
			>&2; exit 1;;
        ? ) printf "\-%s is not a valid option\n%s\n" "${OPTARG}" "$helpStr" \
			>&2; exit 1;;
    esac

done # loop to read in user input

#*******************************************************************************
# Sec-2 Sub-2: set up directory and file names
#*******************************************************************************

prefStr="${prefStr%/}"; # remove any trailing slashes

# build file and dir names (the ends of the file names were set up in section 1)
outDirStr="$prefStr$outDirStr";
isoletStr="$outDirStr/$prefStr$isoletStr";
globStr="$outDirStr/$prefStr$globStr"; 
outCombFileStr="$outDirStr/$prefStr$outCombFileStr";
outIsoFileStr="$outDirStr/$prefStr$outIsoFileStr";
logStr="$outDirStr/$prefStr$logStr";

# set the meta quast paths up
quastDirStr="$outDirStr/$quastDirStr";
combPathStr="$quastDirStr/$combPathStr";
isoletPathStr="$quastDirStr/$isoletPathStr";


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-3: Check user input and create nesscary files and directories
#     sub-1: Check assembly input is a directory that has fasta files (>=1)
#     sub-2: Check reference input is a directory with fasta files (>=1)
#     sub-3: Check if output directory, log, and filter file already exists
#     sub-4: update log with (created sub 3) user inputs
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-3 Sub-1: Check if input assemblies is a dir with fasta files
#*******************************************************************************

asmbStr="${asmbStr%/}"; # remove trailing /'s (Just bugs me)

checkFastxDir "$asmbStr" "a" "assembly directory" 0 1; # source checkFastxDir
    # checkFastxDir assemblyDirectory checkFastaOnly errorMessage \
    #     doNotGiveNumberFasta printErrors

if [[ $? < 1 ]]; then
    exit; # checkFastxDir prints out the error
fi # if no fasta files in the directory exit

#*******************************************************************************
# Sec-3 Sub-2: Check if reference input is a dir of fastas
#*******************************************************************************

refStr="${refStr%/}"; # remove trailing /'s (Just bugs me)

checkFastxDir "$refStr" "a" "reference directory" 0 1; # source checkFastxDir
    # checkFastxDir referenceDirectory checkFastaOnly errorMessage \
    #     doNotGiveNumberFasta printErrors

if [[ $? < 1 ]]; then
    exit; # checkFastxDir prints out the error
fi # if no fasta files in the directory exit

#*******************************************************************************
# Sec-3 Sub-3: Check if output dir, log file, and filter file already exist
#*******************************************************************************

outDirStr="${outDirStr%/}"; # remove trailing slash (from autocomplete)
checkOutDirLog "$outDirStr" "$logStr"; # source checkInputFun.sh
    # checkOutDirLog outputDirectoryToCheck nameOfLogToMake noTimeLog

if [[ $? < 1 ]]; then
    exit; # checkOutDirLog prints error message
fi # if no directory was made

#*******************************************************************************
# Sec-3 Sub-4: Update log with user input parameters
#*******************************************************************************

# print the input paramters to the log
{
    printf "metaQuast version:%s\n" "$versionStr";
    printf "\nInput parmaters to %s:\n" "$(basename "$0")";
    printf "\t-i: %s\n\t-r: %s\n" "$asmbStr" "$refStr";
    printf "\t-p: %s\n\t-t %i\n\n" "$prefStr" "$threadsInt";
} >> "$logStr";


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-4: Extract data from metaQuast reports
#     sub-1: run metaquast
#     sub-2: extract data from the combined reference report
#     sub-3: extract data from the isolet reference reports
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-4 Sub-1: run metaquast
#*******************************************************************************

if [[ ! -f "$combPathStr" ]] ;then
# if do not have the combined stats file run metaquast

    # put the metaquast call in the log
    {
        printf "\n\nmetaquast settings\n:\tmetaquast.py";
        printf " --threads %s --use-input-ref-order" "$threadsInt";
        printf " -r %s %s/*.fasta{,.gz}" "$refStr" "$asmbStr";
        printf  "--output-dir %s" "$quastDirStr";
    } >> "$logStr";

    # run metaquast
    metaquast.py --threads "$threadsInt" --use-input-ref-order -r "$refStr" \
		"$asmbStr"/*.fasta* --output-dir "$quastDirStr";

fi # if do not have the combined stats file run metaquast

#*******************************************************************************
# Sec-4 Sub-2: extract stats from the combined reference reports
#*******************************************************************************

if [[ ! -f "$outCombFileStr" ]]; then
# if no stats have been extracted yet

    printf "Getting combined stats for each asssembly\n";
    printf "Getting combined stats for each asssembly\n" >> "$logStr";

    # grab data of interest and transpose so one assembly per row
    gawk -f "$scriptDirStr/metaQuastExtract.awk" -v verStr="$versionStr" \
		-v isoStr="all" < "$combPathStr" > "$outCombFileStr";
    # need gawk to grab for using variables with gensub

# if no stats have been extracted yet

else
# else already extracted the stats for the combined file yet

    printf "Combinded stats already in %s\n" "$outCombFileStr";
    printf "Combinded already in %s\n" "$outCombFileStr" >> "$logStr";

# else already extracted the stats for the combined file yet
fi # check if the combined stats need to be extracted

#*******************************************************************************
# Sec-4 Sub-3: extract stats from the isolet reference reports
#*******************************************************************************

if [[ ! -f "$outIsoFileStr" ]]; then
# if the isolet stats have not been extracted yet

    printf "Getting isolet stats for each asssembly\n";
    printf "Getting isolet stats for each asssembly\n" >> "$logStr";
    loopBool=1; # print header (first loop)

    for dirInStr in ./"$isoletPathStr"/*; do
    # loop go though all isolet reports and grab assembler data of intrest

        if [[ ! -d "$dirInStr" ]]; then
            continue;
        fi # if on the null case ignore

        # grab the name of isolate and remove the _complete_genome ending
        nameStr="$(basename "$dirInStr")";
        nameStr="${nameStr//_complete_genome/}"; 

        # extract stats for the individual isolets
        gawk -f "$scriptDirStr/metaQuastExtract.awk" -v verStr="$versionStr" \
			-v isoStr="$nameStr" -v printHead="$loopBool" \
			< "$dirInStr/$grabFileStr" >> "$outIsoFileStr";

        loopBool=0;

    done # loop go though all isolet reports and grab assembler data of intrest

# if the isolet stats have not been extracted yet

else
# else isolet stats have already been extracted

    printf "Isolet stats already in %s\n" "$outIsoFileStr";
    printf "Isolet already in %s\n" "$outIsoFileStr" >> "$logStr";

# else isolet stats have already been extracted
fi # check if need to extract the isolet stats


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-5: exit
#     Sub-1: Report date to log and exit
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-5 Sub-1: Report date to log and exit
#*******************************************************************************

printf "Stats saved in %s\n" "$outDirStr/$outFileStr";
printf "END:\t%s" "$(date +"%Y%m%d-%H:%M:%S")" >> "$logStr";

exit; # finshed
