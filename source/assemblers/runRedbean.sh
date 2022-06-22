#!/bin/bash


################################################################################
# Use: Use Redbean with plasmid and metagenomics settings to build an assembly 
#      from input reads
# input:
#    -g: string with the genome size (ex: 42m for 42 mega bases)
#        Required
#    -r: string with path to reads (fastq file) to buid the assembly from
#        Required
#    -b: boolean to keep the bam file used in polishing or not (0 no 1 yes)
#        Default: no
#    -d: integer with the read depth (Used in file and directory names)
#        Default: 0, which is converted to NAx in the file name
#    -o: string with the output direcotry to save the output from redbean to
#            - includes intermediate files made by redbean
#        Default: prefix--readDepthx-redbean
#    -p: string with the prefix for the directory name. 
#            - This will also be the prefix for the assembly and log file names
#        Default: prefix
#    -t: integer with the number of threads to use
#        Default: 16
# output:
#     Dir:
#         Name: User provided (-o) [prefix--readDepthx-redbean]
#         Location: Current working directory (unless path provided in name)
#         Contents: Files produced by redbean
#     File: 
#         Name: prefix--readDepthx-redbean.fasta 
#         Location: output directory (-o) [prefix--readDepthx-redbean]
#         Contents: The un-polished redbean assembly
#     File:
#         Name: prefix--readDepthx-redbean--log.txt
#         Location: output directory (-o) [prefix--readDepthx-redbean]
#         Contents:
#             Line 1: Start:\tyear-month-day\thour:minutes:seconds (start time)
#             Line 2: Assembly:\toutput-assembly-name.fasta
#             Line 3 to 11: Input and defualt arguments
#             Line ? to ?: program output + output from the time command
#             Line before end: Saved-assembly:\toutput-directory/assembly.fasta
#             Line end: End:\tyear-month-day\thour:minutes:seconts (end time)
# Dependencys:
#     Redbean
#     Samtools
#     Minimap3
# NOTES: UPDATE FILES
#        for time log versions formate is wtdbg2--wtpoa-cns
################################################################################


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 1:
# variables
#    Output variables (directories or files)
#    file name variables (used in building the file or directory names)
#    assembler input variables (inputs to provide to the assembler)
#    command variables (holds commands to be issued latter)
#    Flags (to determin if I need to run certain steps or not)
#    help message
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# output directories and files
outDirStr=""; # dir to store the assembler output
outFileStr=""; # holds path + name
logStr="";
timeLogStr=""; # stores time output for raven

# Variables holding parts of file and directory names
prefixStr="prefix";
assemblerStr="redbean"; # used for file names (here so I can easly change later)
capAsmbStr="$(echo "$assemblerStr" | sed 's/./\u&/')"; # capital assembler name
readDepthInt=0;
depthStr=""; # temporary variable to hold NA if no read depth provided
nameStr=""; # will hold the ouput file name (not path + name)

# paramter (input) variables for commands called
readsStr="";
threadsInt=16;
genSizeStr=""
polisherStr="wtpoa";

# command variables
dateCmdStr="date +\"%Y-%m-%d %H:%M:%S\""; # command to get the date and time

# Variables only used for log input
versionStr="$(wtdbg2 --version | awk -F " " '{print $2}')"; # assembler version
verWtpoaCnsStr="$(wtpoa-cns --version | 
	grep "Version" | # grep grabs the version line
	awk 'BEGIN {FS=" "}; {print $2}')"; # version number is at the 2nd space
verMiniMapStr="$(minimap2 --version)";
verSamStr="$(samtools --version | head -n 1 | sed 's/.* //g')";

# Flags
nonPolishBool=0; # 0 means that the non-polished assembly has not been made yet
keepBamBool=0; # keep the bam file input into wtpoa-cns for polishing

# help message
helpStr="$(basename "$0") [-h] -r <fastq> -g <genomeSize>
    Use: Build an assembly using input reads and $capAsmbStr
    Input:
        -g: genome size (ex: 42m for 42 mega bases) [Required]
        -r: fastq with the reads to buid the assembly from [Required]
        -d: read depth for file and directory names [Default: NAx]
        -o: output directory [Default: prefix--readDepthx-$assemblerStr]
        -p: prefix for the assembly and directory name [Default: prefix]
        -t: number of threads to use [Default: 16]
     output:
         Directory: prefix--readDepthx-$assemblerStr 
                    Contains: all output from $assemblerStr and $(basename "$0")
         File: prefix--readDepthx-$assemblerStr.fasta 
               Is: the un-polished assembly
         File: prefix--readDepthx-$assemblerStr--log.txt
               Is: the log file with times, input arguments, and file names";


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 2:
# Get user input and set up output file and directory names
#     Get user input with getopts and while loop
#     Build file and directory names (output directory, assembly files, and log)
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# get user input (need :x to avoid skipping the last argument (threads))
while getopts ':b:d:g:h:o:p:r:t:x' option; do
# loop and read in user input
    case "$option" in
        b ) keepBamBool="$OPTARG";;
        d ) readDepthInt="$OPTARG";;
        g ) genSizeStr="$OPTARG";;
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


# check if user provided the required paramters (genome size and reads)
if [[ "$genSizeStr" == "" ]]; then
# if user did not input a genome size
    
    printf "%s requires a genomes size (-g), yet none was provided\n" \
		"$capAsmbStr";
        # sed command captalizes the first letter (& keep the first letter)
    exit;

fi # if check if genome size was provided

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
    printf "%s version:\t%s\n" "$capAsmbStr" "$versionStr" >> "$logStr";
    printf "Wtpoa-cns version:\t%s\n" "$verWtpoaCnsStr" >> "$logStr";
    printf "Minimap2 version:\t%s\n" "$verMiniMapStr" >> "$logStr";
    printf "Samtools version:\t%s\n" "$verSamStr" >> "$logStr";

    printf "Input\tOutput\tCoverage\tAssembler\tVersion" \
		> "$timeLogStr";
    printf "\tUser-time\tSystem-time\tElapsed-time\tMean-memory-kb" \
		>> "$timeLogStr";
    printf "\tMean-resident-memory\tMax-resident-memory\tDate\n" \
		>> "$timeLogStr";

# if the output directory does not exist

else
# else the output directory already exists
   
    # Mark a new entry in the log file if it exists
    if [[ -f "$logStr" ]]; then
    # if the log file does not exist create

        printf "\n\nNext-Run:\t%s\n" "$(eval "$dateCmdStr")" >> "$logStr"; 

        printf "%s version:\t%s\n" "$capAsmbStr" "$versionStr" >> "$logStr";
        printf "Wtpoa-cns version:\t%s\n" "$verWtpoaCnsStr" >> "$logStr";
        printf "Minimap2 version:\t$s\n" "$verMiniMapStr" >> "$logStr";
        printf "Samtools version:\t%s\n" "$verSamStr" >> "$logStr";

    # if the log file does not exist create

    else
    # else this is a new log

        printf "Start:\t%s\n" "$(eval "$dateCmdStr")" > "$logStr";
        printf "Assembly:\n" >> "$logStr"; # Completed assembly line
        printf "%s version:\t%s\n" "$capAsmbStr" "$versionStr" >> "$logStr";
        printf "Wtpoa-cns version:\t%s\n" "$verWtpoaCnsStr" >> "$logStr";
        printf "Minimap2 version:\t%s\n" "$verMiniMapStr" >> "$logStr";
        printf "Samtools version:\t%s\n" "$verSamStr" >> "$logStr";
            # the assembly line will be in the old log

    # else this is a new log (likely an empty directory)
    fi # if a previous logfile exists

    if [[ ! -f "$timeLogStr" ]]; then 
    # if the time log does not exist (make with the header)

        printf "Input\tOutput\tCoverage\tAssembler\tVersion" \
			> "$timeLogStr";
        printf "\tUser-time\tSystem-time\tElapsed-time\tMean-memory-kb" \
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

        # let the user know the assembly already exists
        printf "%s has already built an assembly." "$assemblerStr";
        printf " Only doing polishing with %s\n" "$polisherStr";

        printf "%s has already built an assembly." "$assemblerStr" >> "$logStr";
        printf " Only doing polishing with %s\n" "$polisherStr" >> "$logStr";

        nonPolishBool=1; # so I know to only do the polishing step

        if [[ -f "$outFileStr-$polisherStr.fasta" ]]; then
        # if the created assembly has also been polished

            printf "%s has already built and polished with %s" "$assemblerStr" \
				"$polisherStr";

            printf "%s has already built and polished with %s" "$assemblerStr" \
				"$polisherStr" >> "$logStr";

            exit;
        fi # if the created assembly has also been polished
    fi # if the assembly file already exists

# else the output directory already exists
fi # if the output directory does not exist


# put the script settings to the log file
printf "\nSettings for:%s arguments\n" "$(basename "$0")" >> "$logStr";

printf "\t-g %s\n\t-r %s\n\t-b %s\n\t-d %s\n\t-o %s\n\t-p %s\n\t-t %i\n\n" \
	"$genSizeStr" "$readsStr" "$keepBamBool" "$depthStr" "$outDirStr" \
	"$prefixStr" $threadsInt >> "$logStr";


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 4:
# run redbean
#     Build fasta file with the assembly
#     Polish the assembly with wtpoa
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# build the assembly with redbean (needs two commands)
if [[ $nonPolishBool == 0 ]]; then
# if there is no previous assembly

    printf "Running wtdbg2 and wtpoa-cns to build the assembly\n";
    printf "\nAssembler command:\n\twtdbg2 -t %i -x ont" $threadsInt \
		>> "$logStr";
	printf " -g %s -i %s -fo %s &&\n" "$genSizeStr" "$readsStr" "$outFileStr" \
		>> "$logStr"
     printf "\twtpoa-cns -t %i -i %s.ctg.lay.gz -fo %s.fasta\n\n" $threadsInt \
	 	"$outFileStr" "$outFileStr" >> "$logStr";

   # bulding the assembly (need to run both commands together
    /usr/bin/time -o "$timeLogStr" -a \
			-f "$(basename "$readsStr")\t$(basename "$outFileStr.fasta")\t$depthStr\t$assemblerStr\t$versionStr\t%U\t%S\t%e\t%K\t%t\t%M\t$(date +"%Y%m%d")" \
    	"$(command -v wtdbg2)" -t $threadsInt -x ont -g "$genSizeStr" \
			-i "$readsStr" -fo "$outFileStr" && 
		"$(command -v wtpoa-cns)" -t $threadsInt -i "$outFileStr.ctg.lay.gz" \
				-fo "$outFileStr.fasta";
    
		# bash has own time command that does not support -o, so need to run the 
		# time command in /usr/bin
	    	# -o is output to file
        	# -1 is for append (so I do not overwrite my header)
        	# -f is for format: 
            	# %u: is the user time (CPU sec in user mode)
            	# %s: is the system time (CPU sec in kernal mode) 
					# (%s+%u = cpu time)
            	# %e: is how long the program run (e for seconds E for human)
            	# %K: average total memory used in kb
            	# %t: average resident size in kb
            	# %M: max resident memory size (Memory used?) in kb
    	# "$(command -v "$assemblerStr")" tells time were the assembler binary
        	# is /usr/bin/time does not look for local installs and so errors
        	# out. need to provide with an absolute path (command -v does this)

    # check if successfull (outFileStr is outDirStr/nameStr. log in outDirStr)
    if [[ -f "$outFileStr.fasta" ]]; then # if an assemby was built
        sed -i'' "s/\(Assembly:.*\)/\1\t$nameStr.fasta/" "$logStr";
    else
	# else no assembly was built

        printf "ERROR: %s did not build an assembly\n" "$assemblerStr";
        printf "ERROR: %s did not build an assembly\n" "$assemblerStr" >> \
		"$logStr";
        exit;

	# else no assembly was built
	fi # check if assembly was made (if not exit)

fi # if there is no previous assembly
# put the redbean command I will run in the log file


# use wtpoa (redbeans polisher) (needs 2 commands)

printf "Polishing assembly with %s\n" "$polisherStr";
printf "\nPolishing assembly with %s\n" "$polisherStr" >> "$logStr"

# check and see if a previous run has already made the bam file for polishing
if [[ ! -f "$outFileStr.ctg.bam" ]]; then
# if the bam file does not exist


    printf "Making bamfile with minimap2 and polising assembly with wtpoa\n";
    printf "\tminimap2 -t %i -x map-ont -a %s.fasta  %s |\n" $threadsInt \
		"$outFileStr" "$readsStr" >> "$logStr";
    printf "\t\tsamtools sort > %s.ctg.bam &&\n" "$outFileStr" >> "$logStr"
	printf "\t\tsammtools view %s.ctg.bam |\n" "$outFileStr" >> "$logStr"
	printf "\t\twtpoa-cns -t %i -d %s.fasta -i - -fo %s-%s.fasta\n\n" \
		$threadsInt "$outFileStr" "$outFileStr" "$polisherStr" >> "$logStr";

    /usr/bin/time -o "$timeLogStr" -a \
			-f "$(basename "$readsStr")\t$(basename "$outFileStr-$polisherStr.fasta")\t$depthStr\t$assemblerStr\t$versionStr\t%U\t%S\t%e\t%K\t%t\t%M\t$(date +"%Y%m%d")" \
    	"$(command -v minimap2)" -t $threadsInt \
			-x map-ont -a "$outFileStr.fasta" "$readsStr" | \
			"$(command -v samtools)" sort > "$outFileStr.ctg.bam" && \
			"$(command -v samtools)" view "$outFileStr.ctg.bam" | \
		"$(command -v wtpoa-cns)" -t $threadsInt -d "$outFileStr.fasta" -i - \
			-fo "$outFileStr-$polisherStr.fasta";
        # command -v allows me to input an absolute path for each program 
		# location, which allows time to work with local installs
        # for time command see the run wtdbg2 command (used to make fasta)


# if the bam file does not exist

else
# else user already buit a bam file

    printf "Bamfile already exists, so will not record time.\n" >> "$logStr";
	printf "Polishing the assembly with wtpoa-cns\n" >> "$logStr";
	printf "Polishing the assembly with wtpoa-cns\n";

    # polish the assembly with wtpoa-cns (first print out command to log)
    printf "\tsamtools view %s.ctg.bam |\n" "$outFileStr" >> "$logStr";
    printf "\t\twtpoa-cns -t %i -d %s.fasta -i - -fo %s-%s.fasta\n" \
		$threadsInt "$outFileStr" "$outFileStr" "$polisherStr" >> "$logStr";

    samtools view "$outFileStr.ctg.bam" | 
		wtpoa-cns -t $threadsInt -d "$outFileStr.fasta" -i - \
			-fo "$outFileStr-$polisherStr.fasta";

# else user already buit a bam file
fi # if the bam file does not exist

# check if the assembly was polished
if [[ -f "$outFileStr-$polisherStr.fasta" ]]; then # if succussfull polish
    sed -i'' "s/\(Assembly:.*\)/\1\t$nameStr-$polisherStr.fasta/" "$logStr";
else
# else something errored out
      
    printf "ERROR: %s did not polish %s.fasta\n" "$polisherStr" "$nameStr";
    printf "ERROR: %s did not polish %s.fasta\n" "$polisherStr" "$nameStr" >> \
		"$logStr";
    exit;

# else something errored out
fi # check if polished the assembly


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 5:
# clean up and exit
#     Remove the bam file (space)
#     Echo done and file locations to user
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# remove the bam file unless the user wanted to keep it (saves space)
if [[ $keepBamBool == 0 ]]; then 
    rm "$outFileStr.ctg.bam" 
fi # if not keeping the bam file

printf "Assembly complete and saved to %s.fasta\n" "$outFileStr";


# update log (file names and end time)
printf "Saved-assembly:\t%s.fasta\n" "$outFileStr" >> "$logStr";
printf "End:\t%s\n" "$(eval "$dateCmdStr")" >> "$logStr";

exit;
