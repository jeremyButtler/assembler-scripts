#!/bin/bash

################################################################################
# Use: Hold input checking functions for my assembler scripts
# Functions:
#     checkFastxDir: 
#         Use: Check if directory has fasta or fastq files
#     checkOutDirLog:
#         Use: Check if directory exists and create log and time--log files
# Notes:
#     $?: Gets the return value from the function
#     Call: source checkInputFun.sh # near top of main script
################################################################################

################################################################################
# Name: checkFastxDir
# User: Checks if input is a directory that has fasta or fastq (user specifies)
# Input:
#    $1: String with path to the directory to check
#    $2: Char with q, a, or b to decide what type of file to search for
#        q: search for fastq
#        a: search for fasta
#        b: search for fastq and fasta
#    $3: String with the prefix of the error message to pring
#        Message format: Input <user prefix> <Input directory> is a file...
#        Messege format: Input <user prefix> <Input directory> does not exist...
#    $4: Boolean (0 or 1) telling if to return the number of fastx files
#        0: Loop will stop at frist fastx file and return 1
#        1: loop will count how many fastx files in directory and return the
#           number
#    $5: Boolean (0 or 1) to supress error messages (1) or print messages (0)
# Output:
#     Return > 0: Fastx files found (if > 1 then the number of fastx files)
#     Return 0: No fastx files found
#     Print: Prints out error message to user if not a directory with fastx
#            (user specifies if x is a, q, or a and q)
# Note:
#     This script will check for .gz files
################################################################################

checkFastxDir () 
{ # checkFastxDir function (NOTE IN FUTURE TRY GETOPTS LOOP)

    asmbDirStr="$1"; # directory with fasta files
    errorPrefStr="$3"; # kinda prefix to error message
    fastxStr=""; # 
    choiceChar="${2,}";
    printErrorBool="$5";
    numFastxInt=0;

    # check what file type the user is inputing
    if [[ "$choiceChar" == "q" ]]; then
        fastxStr=("fastq" "fastq.gz");
    elif [[ "$choiceChar" == "a" ]]; then
        fastxStr=("fasta" "fasta.gz");
    elif [[ "$choiceChar" == "b" ]]; then
        fastxStr=("fasta" "fasta.gz" "fastq" "fastq.gz"); # look for both
    else
    # else non valid input entered

        if [[ $printErrorBool -le 0 ]]; then
        # if printing out error messages

            printf "Error: checkFasta function in %s" "$(basename "$0")";
            printf " only accepts q (fastq), or a (fasta) for argument 3\n";

        fi # if printing out error messages

        return 0;

    # else non valid input entered
    fi # check if valid input for $2
    
    if [[ ! -d "$asmbDirStr" ]]; then
    # if the input assembly is not a directory

        if [[ -f "$asmbDirStr" ]]; then
        # if the input assembly is a fasta file
 
            if [[ $printErrorBool -le 0 ]]; then
            # if printing out error messages

                printf "Input %s %s is a file," "$errorPrefStr" "$asmbDirStr";
                printf " please input a directory\n";

            fi # if printing out error messages

            asmbDirStr="$(echo "$asmbDirStr" | sed 's/.*\.fast/fast/;s/.gz//')";

            if [[ "$asmbDirStr" == ".fasta" ]]; then
                return 0;
            elif [[ "$asmbDirStr" == ".fastq" ]]; then
                return 0;
            else
                return 0;
            fi # check if input file was a fastx

        fi # if the input assembly is a fasta file

        if [[ $printErrorBool -le 0 ]]; then 
            printf "Input %s %s does not exist\n" "$errorPrefStr" "$asmbDirStr";
        fi # if printing out error messages

        return 0;

    fi # if the input assembly is not a directory

    # fastxStr is uncommented do to konwing there are no spaces and needing
    # the expansion for the both case
    for fileTypeStr in "${fastxStr[@]}"; do
    # loop though all file types to search for

        for strFasta in "$asmbDirStr"/*".$fileTypeStr"; do
        # loop though all fasta or fasta.gz files in the assembly directory

            if [[ ! -f "$strFasta" ]]; then
            # if the only file found was the null case exit (no fasta files)

            if [[ $printErrorBool -le 0 ]]; then 
                printf "%s has no %s files\n" "$asmbDirStr" "${fastxStr[@]}";
            fi # if printing errors
            return 0;
     
            fi # if the only file found was the null case exit (no fasta files)

            numFastxInt=$((numFastxInt + 1));

            if [[ $4 -lt 1 ]]; then
                break; # there is at least on fasta file
            fi # if use does not want a count of the number of fastx files

        done # loop though all fasta or fasta.gz files in the assembly directory 

        if [[ $4 -lt 1 && numFastxInt -gt 0 ]]; then
            break; # there is at least one fasta file
        fi # if only checking if at least one fasta file

    done # loop though all search paternts (fastx, fastx.gz)

    return 1;
} # checkFastxDir function


################################################################################
# Name: checkOutDir
# Use: Checks if a directory exists or not, and if the directory does not exist
#      it creates it. This will also create a log file and if specified a
#      time log file.
# Input:
#     $1: String with the path to the directory to check
#     $2: String with log name (either the prefix or have end in log.txt)
#         Note: bash seems to pass with by val.
#     $3: String with header for the time log (if none do not make time log)
# Output: 
#     Return: 0 if directory path did not exist
#     Return: 1 made a directory
#     Return: 2 directory already existed
#     Prints error message if the directory alread exists
#     Dir:
#         Name: $1 
#         Location: in working directory or path provided in $1
#         Contents: log file and possably a time log file
#     File:
#         Name: $2-log.txt
#         Location: $1
#         Contents:
#             If does not already exist: Start:\tYearMonthDay Hour:Minute:Sec
#             If already exists, append: Re-start\tYearMonthDay Hour:Minute:Sec
#     File
#         Name: $2--time-log.txt
#         Location: $1 if user input y to $3
#         Contents: User input header ($3)
################################################################################

checkOutDirLog () 
{ # checkOutDirLog function
    
     dirStr="$1";
     logStr="$2";
     timeLogStr="";
     timeHeadStr="$3";
     dateStr="$(date +"%Y%m%d %H:%M:%S")";

     if [[ "$(dirname "$logStr")" != "$dirStr" ]]; then
         logStr="$dirStr/$logStr";
     fi # if user did not provide the path name
     
     # check if user provided an extnesion (time log makes a handy holder
     timeLogStr="$(printf "%s" "$logStr" | sed 's/\(.*\)\(log.txt\)/\2/')";

     # make sure log.txt is not in the log file (if so just remove)
     if [[ "$timeLogStr" == "log.txt" ]]; then
     # if user provided an the time extension
         timeLogStr="$(printf "%s" "$logStr" | sed 's/\(.*\)-log.txt/\1/')";
         timeLogStr="$timeLogStr-time-log.txt";
     # if user provided an the time extension
     
     else
     # else need to add extension

         timeLogStr="$logStr-time-log.txt";
         logStr="$logStr-log.txt";

     # else need to add extension
     fi # check if need to add extenions to log file names

     if [[ ! -d "$dirStr" ]]; then
     # if the directory does not exist

         if [[ ! -d "$(dirname "$dirStr")" ]]; then
         # if the path to the directory does not exist

             printf "The path to %s does not exist\n" "$dirStr";
             printf "Unable to create direcotry\n";
             return 0;

         fi # if the path to the directory does not exist

         mkdir "$dirStr";
         printf "Start:\t%s\n" "$dateStr" >> "$logStr";

         if [[ "$timeHeadStr" != "" ]]; then
             printf "%s\n" "$timeHeadStr" >> "$timeLogStr";
         fi # if need to create a time log

         return 1;
     fi # if the directory does not exist

     if [[ ! -f "$logStr" ]]; then
         printf "Start:\t%s\n" "$dateStr" >> "$logStr";
     else
          printf "Re-start:\t%s\n\n" "$dateStr" >> "$logStr";   
     fi # check if the log file already exists

     if [[ "$timeHeadStr" != "" ]]; then
     # if makeing a time log

         if [[ ! -f "$timeLogStr" ]]; then
             printf "%s\n" "$timeHeadStr" >> "$timeLogStr";
         fi # check if the time log file already exists

     fi # if makeing a time log

     return 2;
} # checkOutDirLog function
