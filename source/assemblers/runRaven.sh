#!/bin/bash


################################################################################
# Use: Use raven with plasmid and metagenomics settings to build an assembly 
#      from input reads
# input:
#    -r: string with path to reads (fastq file) to buid the assembly from
#        Required
#    -d: integer with the read depth (Used in file and directory names)
#        Default: 0, which is converted to NAx in the file name
#    -o: string with the output direcotry to save the output from raven to
#            - includes intermediate files made by raven
#        Default: prefix--readDepthx-raven
#    -p: string with the prefix for the directory name. 
#            - This will also be the prefix for the assembly and log file names
#        Default: prefix
#    -t: integer with the number of threads to use
#        Default: 16
# output:
#     Dir:
#         Name: User provided (-o) [prefix--readDepthx-raven]
#         Location: Current working directory (unless path provided in name)
#         Contents: Files produced by raven
#     File: 
#         Name: prefix--readDepthx-raven.fasta 
#         Location: output directory (-o) [prefix--readDepthx-raven]
#         Contents: The un-polished raven assembly
#     File:
#         Name: prefix--readDepthx-raven--log.txt
#         Location: output directory (-o) [prefix--readDepthx-raven]
#         Contents:
#             Line 1: Start:\tyear-month-day\thour:minutes:seconds (start time)
#             Line 2: Assembly:\toutput-assembly-name.fasta
#             Line 3 to 11: Input and defualt arguments
#             Line ? to ?: program output + output from the time command
#             Line before end: Saved-assembly:\toutput-directory/assembly.fasta
#             Line end: End:\tyear-month-day\thour:minutes:seconts (end time)
# Dependencys:
#     Flye
#     Samtools
#     Minimap2
################################################################################


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 1:
# variables
#    Output variables (directories or files)
#    file name variables (used in building the file or directory names)
#    assembler input variables (inputs to provide to the assembler)
#    command variables (holds commands to be issued latter)
#    help message
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# output directories and files
outDirStr=""; # dir to store the assembler output
outFileStr=""; 
logStr="";
timeLogStr=""; # stores time output for raven

# Variables holding parts of file and directory names
prefixStr="prefix";
assemblerStr="raven"; # used for file names (here so I can easly change later)
capAsmbStr="$(echo "$assemblerStr" | sed 's/./\u&/')"; # capital assembler name
readDepthInt=0;
depthStr=""; # temporary variable to hold NA if no read depth provided
nameStr=""; # will hold the ouput file name (not path + name)

# paramter (input) variables for commands called
readsStr="";
threadsInt=16;

# command variables
dateCmdStr="date +\"%Y-%m-%d %H:%M:%S\""; # command to get the date and time

# Variables only used for log input
versionStr="$($assemblerStr --version)"; # get the version of the assembler

# help message
helpStr="$(basename "$0") [-h] -r <fastq> -g <genomeSize>
    Use: Build an assembly using input reads and $capAsmbStr
    Input:
        -r: fastq with the reads to buid the assembly from [Required]
        -d: read depth for file and directory names [Default: NAx]
        -o: output directory [Default: prefix--readDepthx-$assemblerStr]
        -p: prefix for the assembly and directory name [Default: prefix]
        -t: number of threads to use [Default: 16]
     output:
         Directory: prefix--readDepthx-$assemblerStr 
                    Contains: all output from $assemblerStr and $(basename "$1")
         File: prefix--readDepthx-$assemblerStr.fasta 
               Is: the un-polished assembly
         File: prefix--readDepthx-$assemblerStr--txt.log
               Is: the log file with times, input arguments, and file names";


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 2:
# Get user input and set up output file and directory names
#     Get user input with getopts and while loop
#     Build file and directory names (output directory, assembly files, and log)
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# get user input (need :x to avoid skipping the last argument (threads))
while getopts ':d:g:h:o:p:r:t:x' option; do
# loop and read in user input
    case "$option" in
        d ) readDepthInt="$OPTARG";;
        h ) echo "$helpStr" >&2; exit;;
        o ) outDirStr="$OPTARG";;
        p ) prefixStr="$OPTARG";;
        r ) readsStr="$OPTARG";;
        t ) threadsInt="$OPTARG";;
        x ) printf "-x is not a valid option\n" &>2; exit;;
        ? ) printf "Option -%s is not valid.\n" "${OPTARG}" >&2; 
			printf "%s\n" "$helpStr" >&2;
			exit 1;;
        : ) printf "-%s requires an argument.\n" "$OPTARG" >&2; exit 1;;
    esac
done # loop and read in user input


# Build the output directory name

# build the file name (if no read depth put NAx)
if [[ $readDepthInt -gt 0 ]]; then # if user provided the read depth
    depthStr="$readDepthInt";
else
    depthStr="NA";
fi # check if user supplied a read depth or not

# set the name
nameStr="$prefixStr--"$depthStr"x-$assemblerStr";

# check if the user provided an output directory
if [[ "$outDirStr" == "" ]]; then # if user did not give an output directory
    outDirStr="$nameStr";
fi # if using defualt output directory name (user did not provide)

# make the output file name
outFileStr="$outDirStr/$nameStr"; 

# build logfile name
logStr="$outFileStr--log.txt";
timeLogStr="$outFileStr--time-log.txt";


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 3:
# input checking and intail logging:
#     Check if output directory exists
#     Check if required input exists (reads and  genome size)
#     Check which (if any) assemblies have already been run
#     Start log (Date, Assembly line, input and default arguments)
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


if [[ "$readsStr" == "" ]]; then
# if user did not input a genome size
    
    printf "No reads provided to build an assembly with (-r)\n";
    exit;

fi # if check if genome size was provided


# check and see if the output directory alread exists


if [[ ! -d "$outDirStr" ]]; then 
# if the output directory does not exist

    printf "%s does not exist, makeing %s\n" "$outDirStr" "$outDirStr";
    mkdir "$outDirStr";
    printf "Start:\t%s\n" "$(eval "$dateCmdStr")" > "$logStr";
    printf "Assembly:\n" >> "$logStr"; # Completed assembly line
    printf "%s version:\t%s" "$capAsmbStr" "$versionStr" >> "$logStr";

    printf "Input\tOutput\tCoverage\tAssembler\tVersion\tUser-time" \
		> "$timeLogStr";
    printf "\tSystem-time\tElapsed-time\tMean-memory-kb" >> "$timeLogStr";
    printf "\tMean-resident-memory-kb\tMax-resident-memory-kb\tDate\n" \
		>> "$timeLogStr";

# if the output directory does not exist

else
# else the output directory already exists
   
    # Mark a new entry in the log file if it exists
    if [[ -f "$logStr" ]]; then
        printf "\n\nNext-Run:\t%s\n" "$(eval "$dateCmdStr")" >> "$logStr";
    else
    # else this is a new log

        printf "Start:\t%s\n" "$(eval "$dateCmdStr")" > "$logStr";
        printf "Assembly:\n" >> "$logStr"; # Completed assembly line
            # the assembly line will be in the old log

    # else this is a new log (likely an empty directory)
    fi # if a previous logfile exists

    if [[ ! -f "$timeLogStr" ]]; then 
    # if the time log does not exist (make with the header)
        printf "Input\tOutput\tCoverage\tAssembler\tVersion\tUser-time" \
			> "$timeLogStr";
        printf "\tSystem-time\tElapsed-time\tMean-memory-kb" \
			>> "$timeLogStr";
        printf "\tMean-resident-memory\tMax-resident-memory\tDate\n" \
			>> "$timeLogStr";

    fi # if the time log does not exist (make with the header)

    printf "%s already exists. Assuming %s is empty\n" "$outDirStr" \
		"$outDirStr"; # Letting user know just in case a mistake

    printf "%s already exists. Assuming %s is empty\n" "$outDirStr" \
		"$outDirStr" >> "$logStr";

    if [[ -f "$outFileStr.fasta" ]]; then
    # if the assembly already exists

        printf "%s has already been used to create an assembly\n" \
			"$capAsmbStr";
        exit;

    fi # if the assembly already exists

# else the output directory already exists
fi # if the output directory does not exist


# put the script settings to the log file
printf "\nSettings for:%s arguments\n" "$(basename "$0")" >> "$logStr";

printf "\t-r %s\n\t-d %s\n\t-o %s\n\t-p %s\n\t-t %i\n\n" "$readsStr" \
	"$depthStr" "$outDirStr" "$prefixStr" $threadsInt >> "$logStr";


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 4:
# run raven
#     Build fasta file with the assembly
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# put the raven command I will run in the log file 
printf "Assembler command:\n\t%s --threads %i %s > %s\n\n" "$assemblerStr"  \
	$threadsInt "$readsStr" "$outFileStr.fasta" >> "$logStr";

# run raven (Not using eval for this since user input is used)
/usr/bin/time -o "$timeLogStr" -a \
		-f "$(basename "$readsStr")\t$(basename "$outFileStr.fasta")\t$depthStr\t$assemblerStr\t$versionStr\t%U\t%S\t%e\t%K\t%t\t%M\t$(date +"%Y%m%d")" \
	"$(command -v "$assemblerStr")" "$readsStr" --threads $threadsInt \
	> "$outFileStr.fasta";
	# bash has own time command that does not support -o, so need to run the 
	# time command in /usr/bin
	    # -o is output to file
        # -1 is for append (so I do not overwrite my header)
        # -f is for format: 
            # %u: is the user time (CPU seconds in user mode)
            # %s: is the system time (CPU sec in kernal mode) (%s+%u = cpu time)
            # %e: is how long the program run (e for seconds E for human)
            # %K: average total memory used in kb
            # %t: average resident size in kb
            # %M: max resident memory size (Memory used?) in kb
    # "$(command -v "$assemblerStr")" tells time were the assembler binary is
        # /usr/bin/time does not look for local installs and so errors out
        # so need to provide with an absolute path (command -v does this)
        

# Raven poduces a raven.ceral file in the working directory. Need to move
printf "%s\n" "$(pwd)";
mv "raven.cereal" "$outDirStr/raven.cereal";

# check for errors and append the name of the output assembly file to the log
if [[ -f "$outFileStr.fasta" ]]; then
# if made the assembly
    sed -i'' "s/\(Assembly:.*\)/\1\t$nameStr.fasta/" "$logStr";

else
# else something errored out
        
    printf "ERROR: %s did not build an assembly\n" "$assemblerStr";
    printf "ERROR: %s did not build an assembly\n" "$assemblerStr" >> "$logStr";
    exit;

# else something errored out
fi # if check if assembly made


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 5:
# clean up and exit
#     Remove the bam file (space)
#     Echo done and file locations to user
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


printf "Assembly complete and saved to %s.fasta\n" "$outFileStr";


# update log (file names and end time)
printf "Saved-assembly:\t%s.fasta\n" "$outFileStr" >> "$logStr";
printf "End:\t%s\n" "$(eval "$dateCmdStr")" >> "$logStr";

exit;
