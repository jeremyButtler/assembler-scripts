#! /usr/bin/gawk -f

################################################################################
# Name: metaQuastExtract.awk
# Use: Extracts assembly stats from transposed_report.tsv that metaQuast makes
# Input:
#     file by <: transposed_report.tsv from metaQuast
#         Assembly names in report should have dashes (-) or underscores (_)
#         prefix--Coveragex-assembler-polisher--suffix.fasta format
#         EX: voltrax--10x-raven--01.fasta (no polisher)
#         EX: voltrax--50x-flye-medaka--good.fasta (one polisher)
#         EX: voltrax--10x-redbean-wtpoa-medaka--yay.fasta (>= 2 polishers)
#     verStr: String with the version of metaQuast
#         Default: NA
#     isoStr: String with the isolet used to make the report
#         If using all references: Input "all"
#         Default: NA
#     printHead: Boolean (0 or 1) telling if to print the header or not
#         0: do not print header
#         1: print header  
#         Default: 1
# Output:
#     Prints processed file to the command line (stdout)
#         Input,Coverage,Assembler,Polisher,Isolet,metaQuast-version
#         ,stats-from-metaQuast
################################################################################


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-0: TOC
#     section-1: set deliminators, declare variables, and check input
#     section-2: Get and print meta data and stats
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-1: Begin block, set deliminators, declare variables, and check input
#     sub-1: Declare varialbes
#     sub-2: set deliminators
#     sub-3: check input
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


BEGIN {

    #***************************************************************************
    # Sec-1 Sub-1: Declare variables
    #***************************************************************************

    # start building the header
    headStr = "Input,Coverage,Assembler,Polisher,Isolet";
    headStr = headStr ",Organism,Genome-Type,metaQuast-version";

    entryStr = ""; # store the row before printing

    # genome types to search for
    {genListStr[1] = "plasmid"}; 
    {genListStr[2] = "chromosome"};

    #***************************************************************************
    # Sec-1 Sub-2: Set deliminators
    #***************************************************************************

    FS="\t";
    OFS=",";

    #***************************************************************************
    # Sec-1 Sub-3: Check user input
    #***************************************************************************

    # set some variables to safe defaults if no user input
    {if(verStr == ""){verStr = "NA"}};
    {if(isoStr == ""){isoStr = "NA"}}; 
    {if(printHead == ""){printHead = 1}}; # default print header
 
} # Begin block


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-2: Get and print meta data and stats
#     sub-1: Print out the header
#     sub-2: Get metaData from name (Input, Coverage, Assembler, Polisher)
#     sub-3: Use isolet name (isoStr) to get Organism and Genome-Type
#     sub-4: Grab stats from the report and print
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-2 Sub-1: Print out the header information
#*******************************************************************************

# grab the assembly information from the file name
{if(NR == 1) 
 { # if on the header row (first row)
     
     {if(printHead == 1)
      { # if printing out the header

         # put each entry in the header (column 1 is assembly (already in))
         {for(strCol = 2; strCol <= NF; strCol++)
             {headStr = headStr "," $strCol;}} 
              
          printf "%s\n", headStr; 
     }} # if printing out the header

 } # if on the header row (first row)

 #******************************************************************************
 # Sec-2 Sub-2: Get metaData from name (Input, Coverage, Assembler, Polisher)
 #******************************************************************************

 else
 { # else on an entry and need to print out

     # convert common spaces characters to dashes
     gsub(/[_,\., ]/, "-", $1); # meta quast replaces dashes with underscores 
         # weakness here is that user file names will be impossible to 
         # reconstruct unless they used dashes. However, metaQuast replaces
         # -'s with underscores anyways, so file names are lost

     # Remove the prefix (and the x for coverage)
     metaStr = gensub(/(^.*)(--)([0-9]*)([X,x])/, "\\3", "g", $1);
     # remove the suffix
     metaStr = gensub(/(--.*)/, "", "g", metaStr);
     # Convert the meta data from a string to an array
     split(metaStr, metaAryStr, "-");

     {if(length(metaAryStr) > 1)
      { # if I extracted something

         # put the meta data in the starting line
         entryStr = $1 ".fasta," metaAryStr[1] "," metaAryStr[2];

         # add the polisher information
         {if(length(metaAryStr) > 2)
          { # if have polisher information to extract
              entryStr = entryStr"," metaAryStr[3];

              # if more then one polisher add other polishers with loop 
              for(intPol = 4; intPol <= length(metaAryStr); intPol++)
                  {entryStr = entryStr "-" metaAryStr[intPol];}

          } # if have polisher information to extract

          else 
              {entryStr = entryStr ",NA";}
         } # check if need to add the polisher or NA

      } # if I can extract something

      else 
          {entryStr = $1 ".fasta,NA,NA,NA";} # else nothing to extract use NA's
     } # check if I can extract meta data or not (Input, Coverage, Assembler)

     # add the isolet information in
     entryStr = entryStr "," isoStr;

     #**************************************************************************
     # Sec-2 Sub-3: Use isolet name (isoStr) to get Organism and Genome-Type
     #**************************************************************************

     # get the genome type and isolet name without genome type from name
     {for(intGen = 1; intGen <= length(genListStr); intGen++)
      { # loop though all genome types to check

          indexInt = index(tolower(isoStr), genListStr[intGen]);

          # if was a match to our genome record the genome type
          {if(indexInt > 0)
           { # if found the genome type

               # get the Organism name
               {if(indexInt > 1) 
                    {nameStr = substr(isoStr, 0, indexInt - 1);}
                else if(indexInt == 1) 
                    {nameStr = substr(isoStr, length(genListStr) + 1);}
               } # if there is more then just the genome type

               # convert common space replace characters to spaces
               gsub(/[-,_,\.]/, " ", nameStr); 
               sub(/^ */, "", nameStr); # get rid of leading spaces
               sub(/ *$/, "", nameStr); # get rid of trailing spaces
               gsub(/  */, "", nameStr); # get rid of double spaces


               entryStr = entryStr "," nameStr;
               entryStr = entryStr "," genListStr[intGen]; # add genome type
               break; # stop loop so I know I found a match

          }} # if found the genome type

     }} # loop though and check all genome types

     # if could not id the genome type
     {if(indexInt < 1) 
      { # if did not find a genome type
        
          {if(isoStr == "all")
               {entryStr = entryStr ",all,all";} # if using all refs
           else
               {entryStr = entryStr ",NA,NA";} # no genome type 
          } # check if user told me there using all refs

     }} # if did not find a genome type


     # add the version number
     entryStr = entryStr "," verStr;

    #***************************************************************************
    # Sec-2 Sub-4: Grab stats and print
    #***************************************************************************

     # get the stats 
     {for(intData = 2; intData <= NF; intData++)
         {entryStr = entryStr "," $intData}};

     printf "%s\n", entryStr; # print out the row

}} # else on an entry and need to print out
