#!/bin/bash


################################################################################
# Use: Builds assemblys using Canu, Flye, Raven, and Redbean 
# input:
#    -g: string with the genome size (ex: 42m for 42 mega bases)
#        Required (for redbean and canu)
#    -r: string with path to directory with reads (fastq file) to buid the 
#        assembly from
#        Required
#    -a  string with the assembler to run
#        Default Flye
#    -b: boolean to keep the bam file used with redbean (0 no 1 yes)
#        Default: no
#    -d: integer with the read depth (Used in file and directory names)
#        Default: 0, which is converted to NAx in the file name
#    -p: string with the prefix for the directory name. 
#            - This will also be the prefix for the assembly and log file names
#        Default: prefix
#    -t: integer with the number of threads to use
#        Default: 16
# output:
#     Dir:
#         Name: prefix--assemblies
#         Location: Current working directory 
#         Contents: fasta files for containg the assemblies from each assembler
#                   Files name is in prefix--reaDepthx-assembler--number.fasta 
#                   format 
#                       - for redbean there will be -wtpoa between the assember 
#                         and the number
#     Dir: 
#         Name: prefix--assembler-output
#         Location: Current working directory
#         Contents: Directories with the output from each assembler
#                   Directories name prefix--readDepthx-assembler-number
#     File:
#         Name: prefix--readDepthx-assemblies--log.txt
#         Location: assembler-output
#         Contents:
#             Line 1: Start:\tyear-month-day\thour:minutes:seconds (start time)
#             Line 2: Assembly:\tassembly1-directory/output-assembly.fasta\tassembly2-directory/output-assembly.fasta\tassembly3-directory/output-assembly.fasta\t...
#             Note: For line 2 redbean will produce two files
#             Line 3 to 11: Input and defualt arguments
#             Line ? to ?: program output for each assembler
#                          Assembler-ID: assembler-name
#                                        log output for each assembler
#             Line end: End:\tyear-month-day\thour:minutes:seconts (end time)
# Dependencys:
#     runCanu.sh (reqiures canu)
#     runFlye.sh (requires flye)
#     runRaven.sh (requires raven)
#     runRedbean.sh (requires wtdb2 (redbean), minimap2 and samtools)
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
asmbDirStr=""; # stores all the files made by each assembler
fastaDirStr=""; # directory to copy the fasta files to (built assembly)
readsStr=""; # place to copy the fasta files to 
outFileStr=""; # holds path + name
logStr="";
timeLogStr=""; # holds times from each assembly run
combTimeLogStr=""; # holds the times for all runs

# Variables holding parts of file and directory names
prefixStr="prefix";
readDepthInt=0;
nameStr=""; # will hold the ouput file name (not path + name)
asmbStr="flye";
capAsmbStr=""; # will hold the captalized name of the assembler
valdAsmbStr=("canu" "flye" "raven" "redbean");
redPolishStr="wtpoa"; # redbean internal polisher
repStr=""; # stores repInt (house keeping), but in 00 format instead of 0

# paramter (input) variables for commands called
readsStr="";
threadsInt=16;
genSizeStr=""

# command variables
dateCmdStr="date +\"%Y-%m-%d %H:%M:%S\""; # command to get the date and time

# path to the scripts to run each assembler
scriptPathStr="$(dirname "$0")/assemblers"; 

# Flags
keepBamBool=0; # keep the bam file input into wtpoa-cns for polishing
validAsmbBool=0; # Used to find if user input a valid assembler

# house keeping variables
repInt=1; # the number of the fasta file on (so each assembly has a unique name)
numZeroStr=""; # stores the number of zeros to add to repStr
nextPowInt=10; # The next power of 10 (tells me when to removing a 0 in repStr)
numFastqInt=0; # stores the number of fastq files to process (for adding 0's)
    # -1 so first add goes to 0 (indexing by 0)
tmpStr=""; # just a temporary string to use as needed

# help message
helpStr="$(basename "$0") [-h] -r <fastq> -g <genomeSize>
    Use: Build an assembly using input reads and $capAsmbStr
    Input:
        -a: assembler to run (options: canu, flye, raven, redbean)
        -g: genome size (ex: 42m for 42 mega bases) [Required]
        -r: directory with with reads (fastq) to buid the assembly from [Required]
        -d: read depth for file and directory names [Default: NAx]
        -p: prefix for the assembly and directory name [Default: prefix]
        -t: number of threads to use [Default: 16]
     output:
         Directory: assemblies
             Contains: all assebmlies as fasta files
             File names: prefix--readDepthx-assembler.fasta
         Directory: assembler-output
               Contains: A directory for each assemblers output files
               Directory names: prefix--readDepthx-assembler
         File: prefix--readDepthx-assemblies--log.txt
               Is: the log file with times, input arguments, and file names
                   for each assembler";


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 2:
# Get user input and set up output file and directory names
#     Get user input with getopts and while loop
#     Build file and directory names (output directory, assembly files, and log)
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# get user input (need :x to avoid skipping the last argument (threads))
while getopts ':a:b:d:g:h:o:p:r:t:x' option; do
# loop and read in user input
    case "$option" in
        a ) asmbStr="$OPTARG";;
        b ) keepBamBool="$OPTARG";;
        d ) readDepthInt="$OPTARG";;
        g ) genSizeStr="$OPTARG";;
        h ) echo "$helpStr" >&2; exit;;
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

#*******************************************************************************
# Build the output and input directory names
#*******************************************************************************

# build the file name (if no read depth put NAx) (will add assembly later)
if [[ $readDepthInt -gt 0 ]]; then # if user provided the read depth
    nameStr="$prefixStr"--"$readDepthInt"x-"$asmbStr";
else
    nameStr="$prefixStr--NAx-$asmbStr";
fi # check if user supplied a read depth or not

# set up output directorys
asmbDirStr="$prefixStr--assembler-output";
fastaDirStr="$prefixStr--assemblies";

# make the output file name (will need to add assembler name on again)
outFileStr="$asmbDirStr/$nameStr"; 

# build logfile name
logStr="$asmbDirStr/logs/$nameStr--log.txt";
timeLogStr="$asmbDirStr/logs/$nameStr--time-log.txt";
combTimeLogStr="$asmbDirStr/$prefixStr--time-log-all.txt";

# make sure the assembler name is lower case
asmbStr="${asmbStr,,}"; # convert to lower case
capAsmbStr="${asmbStr^}"; # capatilize the first letter


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 3:
# input checking and intail logging:
#     Check if the user input a directory of fastq reads
#     Check if the program can run the user input assembler
#     Check if required user input genome size
#     Check if either output directory already exists
#     Start log (Date, Assembly line, input and default arguments)
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Check if user input a directory of fastq reads
#*******************************************************************************

# check if user input a directory 
if [[ ! -d "$readsStr" ]]; then
# if user input an indvidual fastq file or no direcotry

    printf "This script is needs a diretory of fastq files input\n";
	printf "If you provdied a fastq file instead please run one of the scripts";
	printf "called by this script (Likely run%s.sh)\n" "$capAsmbStr";
	exit;

fi # if user input an indvidual fastq file or no directory

readsStr="${readsStr%/}"; # remove the trailing slash (annoys me)

# check that directory has fastq files (will not catch 
for strFastq in "$readsStr"/*.fastq{,.gz}; do
# loop to see if there is at least one fastq file in the directroy

    # null case (file does not exist)
    if [[ ! -f "$strFastq" ]]; then
    # if input directory had no reads report and exit the script

        if [[ $numFastqInt -lt 1 ]]; then
        # if there were no fastq files

            printf "%s has no fastq files to build assemblys with\n" \
				"$readsStr";
            exit;

        fi # if there were no fastq files

    fi # if input directory had no reads report and exit the script

    # count all fastaq files so I know how many 0's to pad my output by
    numFastqInt=$((numFastqInt + 1)); 
    
done # loop  to see if there is at least one fastq file in the directory

#*******************************************************************************
# Check that a valid assembler (program can run) was input 
#*******************************************************************************

# check if the assembler input is valid to call
for strValid in "${valdAsmbStr[@]}"; do
# loop though assemblers the script can handle to check if input assembler valid

    if [[ "$asmbStr" == "$strValid" ]]; then
    # if the user input a valid assembler

        validAsmbBool=1; # script can run the assembler
        break;

    fi # if the user input a valid assembler

done # loop though assemblers can handle to check if input assembler is valid

if [[ $validAsmbBool -lt 1 ]]; then 
# if the user did not provide a valid assembler
	
    printf "%s is not a valid assembler\nValid assmelbers are:\n" "$asmbStr";

    for strAsmb in "${valdAsmbStr[@]}"; do 
        printf "\t%s\n" "$strAsmb";
	done # loop and print out all valid assemblers

	exit;

fi # if the user did not provide a valid assembler

#*******************************************************************************
# Check that the genome size was input
#*******************************************************************************

# check if user provided the required paramters (genome size and reads)
if [[ "$genSizeStr" == "" ]]; then
# if user did not input a genome size
    
    printf "%s requires a genomes size (-g), yet none was provided\n" \
		"$capAsmbStr";
        # sed command captalizes the first letter (& keep the first letter)
    exit;

fi # if check if genome size was provided

#*******************************************************************************
# Check if the directory for fastq files exists or not and start log
#*******************************************************************************

# check and see if the directory for fasta files exists
# doing a simpiler check since I will do checks at each assembler level
if [[ ! -d "$fastaDirStr" ]]; then 
    mkdir "$fastaDirStr";
fi # if the output directory does not exist

if [[ ! -d "$asmbDirStr" ]]; then
# if the directory for assembler output does not exists create and make log

    mkdir "$asmbDirStr";
    mkdir "$asmbDirStr/logs"; # make the logs directory
    printf "Start:\t%s\n" "$(eval "$dateCmdStr")" > "$logStr";
    printf "Assembly:\n" >> "$logStr"; # Completed assembly line
    printf "Assemblys in:\t%s\n"  "$fastaDirStr" >> "$logStr";
    printf "Input\tOutput\tCoverage\tAssembler\tVersion" > "$timeLogStr"; 
    printf "\tUser-time\tSystem-time\tElapsed-time\tMean-memory-kb" \
		>> "$timeLogStr";
    printf "\tMean-resident-memory-kb\tMax-resident-memory-kb\tDate\n" \
		>> "$timeLogStr";

# if the directory for assembler output does not exists create and make log

else
# else the directory for assembler output does exist, check if log exists

    if [[ ! -d "$asmbDirStr/logs" ]]; then
        mkdir "$asmbDirStr/logs"; # make the logs directory
    fi # if the log directory does not exist

    # Mark a new entry in the log file if it exists
    if [[ -f "$logStr" ]]; then
        printf "\n\nNext-Run:\t%s\n" "$(eval "$dateCmdStr")" >> "$logStr"; 
    else
    # else this is a new log

        printf "Start:\t%s\n" "$(eval "$dateCmdStr")" > "$logStr";
        printf "Assembly:\n" >> "$logStr"; # Completed assembly line

    # else this is a new log (likely an empty directory)
    fi # if a previous logfile exists

	if [[ ! -f "$timeLogStr" ]]; then 
    # if no time log I need to create one with a header

        printf "Input\tOutput\tCoverage\tAssembler\tVersion" > "$timeLogStr"; 
        printf "\tUser-time\tSystem-time\tElapsed-time" >> "$timeLogStr";
        printf "Mean-memory-kb\tMean-resident-memory-kb" >> "$timeLogStr";
        printf "\tMax-resident-memory-kb\tDate\n" >> "$timeLogStr";

    fi # if the time log does not exist (make with the header)

# else the directory for assembler output does exist, check if log exists
fi # if the directory for storing assembler output exists

if [[ ! -d "$fastaDirStr" ]]; then
    mkdir "$fastaDirStr";
fi # if the directory for holding the fasta file does not exist already

#*******************************************************************************
# Print out the user input to the log
#*******************************************************************************

# put the script settings to the log file
printf "\nSettings for:%s arguments\n" "$(basename "$0")" >> "$logStr";

if [[ $readDepthInt -gt 0 ]]; then
# if the user provided the read depth output it and other args to the log

    printf "\t-g %s\n\t-r %s\n\t-a %s\n\t-b %i\n\t-d %s\n\t-p %s\n\t-t %i\n\n" \
		"$genSizeStr" "$readsStr" "$asmbStr" "$keepBamBool" "$readDepthInt" \
		"$prefixStr" "$threadsInt" >> "$logStr";

# if the user provided the read depth output it and other args to the log

else
# else the user did not provide the read depth, output NA

    printf "\t-g %s\n\t-r %s\n\t-a %s\n\t-b %s\n\t-d %s\n\t-p %s\n\t-t %s\n\n" \
		"$genSizeStr" "$readsStr" "$asmbStr" "$keepBamBool" "NA" "$prefixStr" \
		"$threadsInt" >> "$logStr";

# else the user did not provide the read depth, output NA
fi # Output log entry based on if user provided the read depth


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 4:
# Set up 0 padding for name (so each assembly has a unique name, that can be
#     gotten if the asssemblys were input in the same order)
# Run checks to make sure the assembly has not been made before. If using old
#     data make sure input in the same order
# run the user selected assembler 
# Do ouput checking to make sure an assembly was made
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# figure out how many zeros to pad by for the ones case
while [[ $numFastqInt -gt 9 ]]; do
# loop till padded on all the nesscarry zeros

    numFastqInt=$((numFastqInt / 10));
    numZeroStr="$numZeroStr""0"; # add on a zero

done # loop till padded on all the nesscarry zeros

# for loop, sed is removing the / at the end if one (Know that directory input)
for strReads in "$readsStr"/*.fastq{,.gz}; do
# loop though all fastq files in the directory
 
    if [[ ! -f "$strReads" ]]; then
        continue;
    fi # if the file does not exists (the null case at the end for my search)
    # could break, but I will just let the loop stop it self since this is the
    # last round

    if [[ $repInt -ge $nextPowInt ]]; then
    # if need to remove a zero from numZeroStr (at next power of 10)

        numZeroStr="${numZeroStr%0}"; # remove the end zero
        nextPowInt=$((nextPowInt * 10)); # set up for the next power of 10

    fi # if need to remove a zero from numZeroStr (at next power of 10)

    # add the zero padding to the identifier for the assembler
    repStr="$numZeroStr$repInt";
 
   #****************************************************************************
   # Check if the fastq has already been run
   #****************************************************************************

   # grep -q does not give output, but tells if there was at least one match
   if [[ -f "$combTimeLogStr" ]]; then
   # if a master time log exists

       if grep -q "$(basename "$strReads").*$asmbStr" < "$combTimeLogStr"; then
       # if the fastq has already been ran

           # get the output file that wass assembled from the input fastq
           tmpStr="$(grep "$(basename "$strReads").*$asmbStr" \
						< "$combTimeLogStr" |
						awk '{print $2}')";

           printf "%s has already been assembled by %s\n\tAssembly: %s\n" \
				"$(basename "$strReads")" "$asmbStr" "$tmpStr" >> "$logStr";

           if [[ "$asmbStr" != "redbean" ]]; then
               continue;
           fi # if the assembler is not redbean coninue 

           if grep -q "$(basename "$strReads").*$asmbStr.*wtpoa" < "$combTimeLogStr"; then
           # if redbean has already made a polished assembly

               # get the output assembly polished by wtpoa for the input reads
               tmpStr="$(grep "$(basename "$strReads")$.*asmbStr.*wtpoa" \
						< "$combTimeLogStr" |
						awk '{print $2}')";

               printf "%s has already been polised by %s\n\tAssembly: %s\n" \
					"$(basename "$strReads")" "$asmbStr" "$tmpStr" >> "$logStr";

               continue;

           fi # if redbean has already made a polished assembly

       # if the fastq has already been ran

       else
       # else file has not been run (make sure id number has not been used)

           if [[ -f "$combTimeLogStr" ]]; then
           # if a log file already exists for all assemblies

               tmpStr="$(grep "$nameStr" "$combTimeLogStr" |
 					awk 'BEGIN {FS=OFS="\t"}; {print $2}' |
					sed 's/\(.*\)\(--\)\([0-9]*\).fasta/\3/' |
           			awk 'BEGIN {FS=OFS="\t"};
                         {if(NR==1){maxInt=0}}; # intalize maxInt
                         {if(maxInt < $1) {maxInt = $1}}; 
					    END{{print maxInt}}')";
 				    # grep grabs entries with same coverage and assember
 				    # awk gets the output file from the log
                    # sed removes everthing but the id number at the end 
                    # awk then finds which number is the greates and prints

               if [[ $tmpStr -ge $repInt ]]; then
                   repInt=$((tmpStr + 1));
               fi # if the id number is behind the max id in the log

                while [[ $repInt -ge $nextPowInt ]]; do
                # loop till then number of zeros is correct

                    numZeroStr="${numZeroStr%0}"; # remove the end zero
                    nextPowInt=$((nextPowInt * 10)); # next powe of 10

                done # loop till then number of zeros is correct


                # add the zero padding to the identifier for the assembler
                repStr="$numZeroStr$repInt";
       fi # check if the input file is already in the master time log
   fi # if a time log exists check if fastq was already ran

   #****************************************************************************
   # Do checks on each assembler (Just me being through, kinda done already)
   #****************************************************************************

    # check if the assembly already exist
    if [[ -f "$fastaDirStr/$nameStr--$repStr.fasta" ]]; then
    # if the assembler already built the assembly
   
        printf "%s already built an assembly\n" "$capAsmbStr";
        printf "%s already built an assembly\n" "$capAsmbStr" >> "$logStr";

		if [[ "$asmbStr" == "redbean" ]]; then
		# if the assembler is redbean check if the assembly is polished yet

            if [[ -f "$fastaDirStr/$nameStr-$redPolishStr--$repStr.fasta" ]]; 
			then
			# if the assembly has already been polished by wtpoa

	            printf "%s already built and polished the assembly with %s\n" \
					"$capAsmbStr" "$redPolishStr";
	            printf "%s already built and polished the assembly with %s\n" \
					"$capAsmbStr" "$redPolishStr" >> "$logStr";

                continue; # move onto the next fastq file

			fi # if the assembly has already been polished by wtpoa

		else # else there is no second assembly so just exit
            continue; # move onto the next fastq file
		fi # if the assembler is redbean check if the assembly is polished yet
    fi # if the assembler already built the assembly

    elif [[ -f "$asmbDirStr/$nameStr--$repStr/$nameStr.fasta" ]]; then
	# if assembly exits, but was not copied over for some reason

        printf "%s already built an assembly, but was not copied to %s\n" \
			"$capAsmbStr" "$fastaDirStr";
        printf "%s already built an assembly, but was not copied to %s\n" \
			"$capAsmbStr" "$fastaDirStr" >> "$logStr";

        # copy the assembly and update the log file (likely not in)
	    cp "$asmbDirStr/$nameStr-$repStr/$nameStr.fasta" \
            "$fastaDirStr/$nameStr--$repStr";

	    # update the log
        sed -i'' "s/\(Assembly:.*\)/\1\t$nameStr--$repStr.fasta/" "$logStr";

        printf "coppied assembly to %s\n" "$fastaDirStr";
        printf "coppied assembly to %s\n" "$fastaDirStr" >> "$logStr";

		if [[ "$asmbStr" == "redbean" ]]; then
		# if the assembler is redbean check if the assembly is polished yet

            if [[ -f "$fastaDirStr/$nameStr-$redPolishStr--$repStr.fasta" ]]; 
			then
			# if the assembly has already been polished by wtpoa

	            printf "%s already built and polished the assembly with %s\n" \
					"$capAsmbStr" "$redPolishStr";
	            printf "%s already built and polished the assembly with %s\n" \
					"$capAsmbStr" "$redPolishStr" >> "$logStr";

                # copy the assembly and update the log file (likely not in)
	            cp "$asmbDirStr/$nameStr--$repStr/$nameStr-$redPolishStr.fasta" \
					"$fastaDirStr/$nameStr-$redPolishStr--$repStr";

	            # update the log
                sed -i'' "s/\(Assembly:.*\)/\1\t$nameStr-$redPolishStr--$repStr.fasta/" \
					"$logStr";

                printf "coppied %s polished assembly to %s\n" "$fastaDirStr" \
					"$redPolishStr";
                printf "coppied %s polished assembly to %s\n" "$fastaDirStr" \
					"$redPolishStr" >> "$logStr";

                continue; # move onto the next fastq file

			fi # if the assembly has already been polished by wtpoa

		else # else there is no second assembly so just exit
            continue; # move onto the next fastq file
		fi # if the assembler is redbean check if the assembly is polished yet

	fi # if assembly exits, but was not copied over for some reason

    #***************************************************************************
    # Run the selected assembler
    #***************************************************************************

	# Run the assembler, there is some work to be done by my scripts

    printf "\nBuilding an assembly using %s\n" "$asmbStr";

    if [[ "$asmbStr" == "canu" ]]; then
	# if the assebler to run is canu call runCanu.sh
        bash "$scriptPathStr/"runCanu.sh -g "$genSizeStr" -r "$strReads" -d \
			"$readDepthInt" -p "$prefixStr" -t "$threadsInt";
	# if the assebler to run is canu call runCanu.sh

	elif [[ "$asmbStr" == "flye" ]]; then
	# else if the assemble to run was fly call runFlye.sh
	    bash "$scriptPathStr/"runFlye.sh -r "$strReads" -d "$readDepthInt" \
			-p "$prefixStr" -t "$threadsInt";
	# else if the assemble to run was fly call runFlye.sh

	elif [[ "$asmbStr" == "raven" ]]; then
	# else if the assembler to run was raven call runRaven.sh
        bash "$scriptPathStr/"runRaven.sh -r "$strReads" -d "$readDepthInt" \
			-p "$prefixStr" -t "$threadsInt";
	# else if the assembler to run was raven call runRaven.sh

    elif [[ "$asmbStr" == "redbean" ]]; then
	# else if the assembler to run was redbean call runRedbean.sh
        bash "$scriptPathStr/"runRedbean.sh -g "$genSizeStr" -r "$strReads" \
			-d "$readDepthInt" -p "$prefixStr" -t "$threadsInt";
	# else if the assembler to run was redbean call runRedbean.sh
    fi # check which assmbler to run

    #***************************************************************************
    # Check assembler output
    #***************************************************************************
   
    # add the replicate number to the created assembly directory name
    mv "$nameStr" "$asmbDirStr/$nameStr--$repStr";
         # that way do not overwrite with the next assembly

	if [[ ! -f "$asmbDirStr/$nameStr--$repStr/$nameStr.fasta" ]]; then
	# if the assembler did not build an assembly then make note in log

        # not reporting error for redbean due to wtpoa having polished
        if [[ "$asmbStr" != "redbean" ]]; then
        # if the assembler was not redbean report the error of no assembly

            printf "%s failed to build an assembly\n" "$capAsmbStr";
            printf "%s failed to build an assembly\n" "$capAsmbStr" >> \
                "$logStr";

        # if the assembler was not redbean report the error of no assembly

        elif [[ ! -f "$asmbDirStr/$nameStr--$repStr/$nameStr-$redPolishStr--$repStr.fasta" ]]; then
        # else if redbean did not build and polish an assembly

            printf "%s failed to build and polish a assembly with %s\n" \
                "$capAsmbStr" "$redPolishStr";
            printf "%s failed to build and polish a assembly with %s\n" \
                "$capAsmbStr" "$redPolishStr" >> "$logStr";

        # else if redbean did not build and polish an assembly
        fi # report if the assembly does not exist

	# if assembler did not build an assembly then make note in log

	else
	# else an assmelby was built, copy to fasta directory and update the log

        # update the master time log with the assembler time log
	    tail -n+2 < "$asmbDirStr/$nameStr--$repStr/$nameStr--time-log.txt" | 
			sed "s/\([^\t]*.\)\(.*\)\(\.fasta\)/\1\2--$repStr\3/" \
			>> "$timeLogStr";
            # tail with n+2 keeps everything but the last entery
            # sed adds the relicate/subsample number to the output file

        if [[ ! -f "$combTimeLogStr" ]]; then
            cp "$timeLogStr" "$combTimeLogStr";
        else
        # else just need to get the last 1-2 times

            if [[ "$asmbStr" == "redbean" ]]; then
                tail -n 2 "$timeLogStr" >> "$combTimeLogStr"; # get last 2 times
            else
                tail -n 1 "$timeLogStr" >> "$combTimeLogStr"; # get last time
            fi # copy the times to the time log (redbean 2, other 1)

        # else just need to get the last 1-2 times
        fi # if need to create the master time log

        # make sure the redbean assembly file does not exist in the master 
        # folder. This could happen with redbean, but not with any other 
        # assembler (to avoid coping the same assebmly twice)
        if [[ ! -f "$asmbDirStr/$nameStr--$repStr/$nameStr--$repStr.fasta" ]]; 
        then
        # if the assembly does not already exits (can occur only with redbean)

	        cp "$asmbDirStr/$nameStr--$repStr/$nameStr.fasta" \
			    "$fastaDirStr/$nameStr--$repStr.fasta";
            sed -i'' "s/\(Assembly:.*\)/\1\t$nameStr--$repStr.fasta/" "$logStr";

        fi # if the assembly does not already exits (can occur with redbean)

        if [[ "$asmbStr" == "redbean" ]]; then
        # if the assembler was redbean check for and copy the polished assembly

            if [[ ! -f "$asmbDirStr/$nameStr--$repStr/$nameStr-$redPolishStr.fasta" ]]; 
            then
            # if redbean did not use wtpoa to polish an assembly

                printf "%s failed to polish a %s-%s.fasta with %s\n" \
                    "$capAsmbStr" "$asmbStr" "$redPolishStr" "$redPolishStr";
                printf "%s failed to polish a %s-%s.fasta with %s\n" \
                    "$capAsmbStr" "$asmbStr" "$redPolishStr" "$redPolishStr" \
                    >> "$logStr";

            # if redbean did not use wtpoa to polish an assembly

            else
            # else redbean did polish the assembly with wtpoa

                # copy to the assembly directory and report in log
	            cp "$asmbDirStr/$nameStr--$repStr/$nameStr-$redPolishStr.fasta" \
			        "$fastaDirStr/$nameStr-$redPolishStr--$repStr.fasta";
                sed -i'' "s/\(Assembly:.*\)/\1\t$nameStr-$redPolishStr--$repStr.fasta/" \
                    "$logStr";

            fi # else redbean did polish the assembly with wtpoa

        fi # report if the assembly does not exist


	# else an assembly was built , copy to fasta directory and update the log
	fi # if check if raven built an assembly

    # incurment the assembly number so do not overwrite the previous assembly
    repInt=$((repInt + 1)); 

done # loop though and build assemblies for all fastq files in the directory


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section 5:
# report and exit
#     Echo done and file locations to user and update logs
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Update logs with final information and report to user
#*******************************************************************************

printf "Saved-assembly:\t%s\n" "$fastaDirStr" >> "$logStr";
printf "End:\t%s\n" "$(eval "$dateCmdStr")" >> "$logStr";
printf "Assemblies completed and saved to %s\n" "$fastaDirStr";

exit;
