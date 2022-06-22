#!/bin/bash

################################################################################
# Name: ontPolishWrapper
# Use: Uses ont_polish_v4.sh script to used racon + medaka to polish a directory 
#      of asssemblies
# Input: 
#     -i: String with directory of fasta assemblies to polish
#         Required: Yes
#     -l: String with the path to a *--time-log.txt file made by 
#         runAssemblers.sh. 
#         Use: Is used to find the reads that belonged to an assembly
#         Format: col1=reads.fastq, col2=assembly.fasta, col3=readDepth, 
#                 col4=assembler, col5=polisher (if other polishers used)
#         Blank entries: NA
#         Deliminator: tabs
#         Required: Yes
#     -r: String with directory of reads (fastq) to polish the assemblies with
#         Required: Yes
#     -h: print help message and exit
#     -n: Integer with the number of rounds to run racon
#         Default: 1
#     -p: String with the prefix for the output directory and log files
#         Defualt: prefix
#     -t: Integer with number of threads to use
#         Default: 16
# Output:
#     Dir: 
#         Name: prefix--polishingRun
#         Location: current working directory
#         Contents: files and directories made by ont_polish_v4.sh
#     File:
#         Name: assemblyPreadsix--depthx-assembler-polisher-medaka--assemblySufix.fasta
#         Location: In the assembly directory
#         Contents: The assemby polished by medaka
#     File:
#         Name: prefix--time-log.tsv 
#         Location: prefix--polishingRun
#         Contents: time Log with with how long it took to polish
#     File:
#         Name: prefix--log.txt 
#         Location: prefix--polishingRun
#         Contents: Log (start time, script output, end time)
################################################################################


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-0: TOC (table of contents)
#     section-1: Variables and any files holding functions
#     section-2: Get and check user input
#     section-3: Run ont-polish
#     section-4: final log and exit
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-1: Variables and files holding functions used in script
#     sub-1: Files that have functions used in script
#     sub-2: Variables holding user input or file names
#     sub-3: help message variable
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-1 Sub-1: files that have functions used in script
#*******************************************************************************

#source checkInputFun.sh; # input checks

#*******************************************************************************
# Sec-1 Sub-2: Variables holding usre input or file names
#*******************************************************************************

# variables holding user input
readsDirStr="";
asmbDirStr="";
asmbMetaDataStr=""; # meta data (time log) from the assembly run
logStr="ontPolishWrapper";
timeLogStr=""; # records the times for each polish
numRaconInt=1;
threadsInt=16;
prefStr="prefix"; # prefix fo the output directory and log files

# Variables holding file names
polAsmbStr=""; # polished assembly name
asmbPrefStr=""; # prefix of the unpolished assembly
asmbMidStr=""; # middle data for the input assembly (meta data section
asmbSufStr=""; # suffix of the input assembly
outDirStr=""; # holds the files made by ont-polish

#*******************************************************************************
# Sec-1 Sub-3: misc Variables
#*******************************************************************************

# varailbes holding commands (use eval with)
dateCmdStr="date +\"%Y%m%d-%H:%M:%S\""; # get time command

# misc variables
timeLogEntryStr=""; # holds a row from the time log (grabbing with grep)
readsStr=""; # readsence to use with an assembly file in polishing
polisherStr="medaka"; # polisher used ont_polish_v4.sh (add racon Sec-2 Sub-2)
orgDirStr="$(pwd)"; # working directory started in


#*******************************************************************************
# Sec-1 Sub-3: Help message
#*******************************************************************************

helpStr="$(basename "$0") -i <assembly-directory> -l <time-log-file> -r <read-directory>
Use: Polishes assemblies with medaka and racon
Input:
    -i: directory of assemblys to polish (fasta format) [Required]
    -l: tab delminated file (\t means tab) [Required]
        Each row: Reads-input\tAssembly\tCoverage\tAssembler\tPolisher
        Blanks: filled with NA
    -r: reads used to polish the assemblies with [Required]
    -h: print this help message an exit
    -n: number of rounds to polish with racon
    -p: prefix for the directory and log files
    -t: number of threads
Output: Polished assemblies in the directory with unpolished assemblies (-i)"


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-2: Get and check user input
#     sub-1: get user input
#     sub-2: set up names and make sure the time log input is a file
#     sub-3: adjust file paths + make and cd into working directory
#     sub-4: Make logs and input user input
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-1 Sub-1: Get user input
#*******************************************************************************

while getopts ':f:h:i:l:n:p:r:t:x' option; do

    case "$option" in
        f ) logStr="$OPTARG";;
        h ) printf "%s\n" "$helpStr"; exit;;
        i ) asmbDirStr="$OPTARG";;
        l ) asmbMetaDataStr="$OPTARG";;
        n ) numRaconInt="$OPTARG";;
        r ) readsDirStr="$OPTARG";;
        p ) prefStr="$OPTARG";;
        t ) threadsInt="$OPTARG";;
        x ) printf "-x is not a valid option\n%s\n" "$helpStr" >&2; exit 1;;
        : ) printf "-%s requires an argument\n%s\n" "$OPTARG" "$helpStr" >&2;
			exit 1;;
    esac

done # loop to read in user input

#*******************************************************************************
# Sec-2 Sub-2: set up names and make sure the time log input is a file
#*******************************************************************************

# make dir name and log names

logStr="$prefStr--log.txt"
timeLogStr="$prefStr--time-log.tsv";
outDirStr="$prefStr--polishingRun";

# add racon in with rounds

if [[ $numRaconInt -gt 0 ]]; then
    polisherStr="racon$numRaconInt""x-medaka";
fi # if need to add a racon polisher rounds in

# removing trailing slashes (just but me, should be no more then 1)
asmbDirStr="${asmbDirStr%/}"; # just do not like trailing slashes (so removing)
readsDirStr="${readsDirStr%/}";

if [[ ! -f "$asmbMetaDataStr" ]]; then
# if the time log was not a file (does not exist)

    printf "%s (-l) is not a file\n" "$asmbMetaDataStr";
    exit;

fi # if the time log was not a file (does not exist)

#*******************************************************************************
# Sec-3 Sub-3: Adjust file paths + make and cd into working directory
#*******************************************************************************

# check if the output directory exists
if [[ ! -d "$outDirStr" ]]; then
    mkdir "$outDirStr";
fi # if the output directory does not exist create

# check if need to adjust file names
if [[ "${asmbDirStr:0:1}" != '/' ]]; then
    asmbDirStr="../$asmbDirStr";
fi # if not an absolute path add ../ for moving into outDirStr

if [[ "${refDirStr:0:1}" != '/' ]]; then
    refDirStr="../$refDirStr";
fi # if not an absolute path add ../ for moving into outDirStr

if [[ "${asmbMetaDataStr:0:1}" != '/' ]]; then
    asmbMetaDataStr="../$asmbMetaDataStr";
fi # if not an absolute path add ../ for moving into outDirStr

# cd into directory to store temporary files

cd "$outDirStr" || exit;

#*******************************************************************************
# Sec-2 Sub-4: Make logs and input user input
#*******************************************************************************

# check if the log file already exists
if [[ ! -f "$logStr" ]]; then
    printf "Start:\t%s\n\n" "$(eval "$dateCmdStr")" >> "$logStr";
else
    printf "\n\nRe-start:\t%s\n" "$(eval "$dateCmdStr")" >> "$logStr";
fi # if to check if log made and add time 

if [[ ! -f "$timeLogStr" ]]; then
# if the time log does not exist make on with a header

    printf "Input-reads\tInput-assemby\tOutput\tCoverage" >> "$timeLogStr";
    printf "\tAssembler\tAssembler-version\tPolisher" >> "$timeLogStr";
    printf "\tUser-time\tSystem-time\tElapsed-time" >> "$timeLogStr";
    printf "\tMean-memory-kb\tMean-resident-memory" >> "$timeLogStr";
    printf "\tMax-resident-memory\tDate\n" >> "$timeLogStr";

fi # if the log file does not exist make one


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-3: Run polisher script
#     sub-1: Do checks and run the polisher script
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-3 Sub-1: Doe checks and run the polisher script
#*******************************************************************************

for strFasta in "$asmbDirStr"/*.fasta{,.gz}; do
# loop though all fasta files

    if [[ ! -f "$strFasta" ]]; then
        continue; 
    fi # if the loop on the null value just finsh 

    # grab the row the metadeta is at in the time log
    timeLogEntryStr="$(grep "$(basename "$strFasta")" < "$asmbMetaDataStr" | 
		awk 'BEGIN {FS=OFS="\t"}; {print $1"\t"$2"\t"$3"\t"$4"\t"$5}')";
        # grep grabs the line for the assembler
        # awk keeps only the meta data section (first five columns)
            # meta data has: Reads used, assembly output, Coverage, 
            # Assembler used, and Asssembler vesion

    # grab the readserence to use with the fasta file
    readsStr="${timeLogEntryStr//$'\t'*/}";
 
    if [[ ! -f "$readsDirStr/$readsStr" ]]; then
    # if there is no reads to polish with

        if [[ "${strFasta//*polished.fasta}" == "" ]]; then
            continue;
        fi # if the assembly has been polished before (ends in polished.fasta)
            # bash will leave the full string if no match

    
        printf "%s is build from %s, but" "$strFasta" "$readsStr";
        printf " %s does not exist\n" "$readsStr";

        printf "\t%s is build from %s," "$strFasta" "$readsStr" >> "$logStr";
        printf " but %s does not exist\n\n" "$readsStr" >> "$logStr";
   
        continue; # move to the next input

    fi # if there is no reads to polish with

    # make the output assembly file name
    # get the prefix of the old name
    asmbPrefStr="$(echo "$(basename "$strFasta")" | 
		sed 's/\(.*--\)[0-9]*[X,x].*/\1/')";

    # get the middle section of the old name (coveragex-assembler-polisher)
    asmbMidStr="$(echo "$(basename "$strFasta")" | 
		sed 's/\(.*--\)\([0-9]*[X,x].*\)--.*/\2/; s/\(^.*\)--.*/\1/')";

    # get the suffix name of the older assembler
    asmbSufStr="$(echo "$(basename "$strFasta")" | 
		sed 's/\(.*--\)\([0-9]*[X,x].*\)/\2/; 
			s/\(^.*\)\(--.*\)\.fasta.*/\2/')";

    polAsmbStr="$asmbPrefStr$asmbMidStr-medaka$asmbSufStr-polished.fasta";

    # input name into the correct position (third entery) in the time log line
    timeLogEntryStr="$(echo "$timeLogEntryStr" | 
		awk -v outStr="$polAsmbStr" -v polStr="$polisherStr" '
            BEGIN {FS=OFS="\t"};
            {print $1 "\t" $2 "\t" outStr "\t" $3 "\t" $4 "\t" $5 "\t" polStr}
         ')"
        # the polisher goes at the end (for know ignoring wtpoa since forgot
        # to add polisher catagory in orginal time logs
        # will split in R

    # do file check (Make sure not overwriting or already run)

    if [[ -f "$asmbDirStr/$polAsmbStr" ]]; then
    # if the polished assembly alread exists

        printf "The polished assembly %s" "$strFasta";
        printf " already exists as %s\n" "$polAsmbStr";

        printf "\tThe polished assembly %s" "$strFasta" >> "$logStr";
        printf " already exists as %s\n" "$polAsmbStr" >> "$logStr";

        continue;

    fi # if the polished assembly alread exists

    # print ont_polish_v4 settings and run
    printf "Runing ont polish on %s with %s\n" "$strFasta" "$readsStr";
    printf "bash ont_polish_v4.sh -s %s" "$strFasta" >> "$logStr";
    printf " -r %s -t %s " "$readsStr" "$threadsInt" >> "$logStr";
    printf " -a %s -p moveMe\n\n" "$numRaconInt" >> "$logStr";

    /usr/bin/time -o "$timeLogStr" -a \
		-f "$timeLogEntryStr\t%U\t%S\t%e\t%K\t%t\t%M\t$(eval "$dateCmdStr")" \
		bash ont_polish_v4.sh -s "$strFasta" -r "$readsDirStr/$readsStr" \
			-p "$asmbPrefStr$asmbMidStr$asmbSufStr" -t "$threadsInt" \
			-a "$numRaconInt";

    cp "$asmbPrefStr$asmbMidStr$asmbSufStr"*"medaka"*".fasta" \
	"$asmbDirStr/$polAsmbStr";

    # move the files from ont_polish_v4.sh to a directory
    mkdir "$asmbPrefStr$asmbMidStr$asmbSufStr";
    mv "medaka" *.{fai,mmi,fasta,report,paf} \
	"$asmbPrefStr$asmbMidStr$asmbSufStr";
    # move the polished assembly to the correct directory

done # loop though all fasta files


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-4: Report and exit
#     sub-1: Report and exit
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-4 Sub-1: Report and exit
#*******************************************************************************

printf "Done. Polished assemblies saved to %s\n" "$asmbDirStr";
printf "\nEnd:\t%s" "$(eval "$dateCmdStr")" >> "$logStr";

cd "$orgDirStr" || exit;

exit;