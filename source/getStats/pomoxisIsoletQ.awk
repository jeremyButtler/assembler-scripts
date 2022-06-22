#!/usr/bin/gawk -f

# ref list needs to by the names in the fasta file (what pomoxis uses)
#     Likely pomoxis trims spaces so avoid spaces

# Input:
#    depthStr: String with the read depth of the assembly
#        Default: NA
#    asmbStr: String with the assembler used
#        Default:NA 
#    polStr: String with the polished used
#        Default: NA
#    allRefStr: String with a list of references that should be in the assembly
#               Each reference should be seperated by '\n' (new line)
#        If input will input lines for references missing from the report.
#        Note: Make sure there are no spaces in the reference names
#        Note: if plasmid or chromosome is in the name the program will also
#              output the genome type (otherwise genome type is NA)
#            All stats will be filled with NA's to mark missing
#        Default: NA
#    inStr: String with the assembly file name
#        Default: NA
#    verStr: String with the version number of the assembly
#        Default: NA
# Output: Tsv file with the assembly stats (Mean + median Q-score + coverage)
################################################################################


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-1: Begining settings
#     sub-1: declare variables used in script
#     sub-2: Check input and parse reference names
#     sub-3: print out the header
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


BEGIN { # begin block
    
    #***************************************************************************
    # Sec-1 Sub-1: variable declerations
    #***************************************************************************

    # arrays to use
    {delete refsInStr[0]}; # just declaring to make sure no scope issues
    {delete bactAryStr[0]}; # holds the name
    {delete genTypeAryStr[0]}; # holds the genome type
    {delete covAryStr[0]}; # holds the coverage for all isolets
    {delete refAryStr[0]}; # holds the reference in the summ.txt file

  
    # temporary variables
    {indexInt = 0};
    {genTypeStr = ""}; # holds genome type was (so I can <M-j>
    {lenInt = 0}; # hols lenght of an array or string

    # genome types to search for
    {genListStr[1] = "plasmid"}; 
    {genListStr[2] = "chromosome"};

    # task keeping variables
    {numRefInt = 0}; # number of references found
    {intCov = 0}; # counts how many coverage have extracted (equal to num ref)
    {matchInt = 0}; # for end statment holds a found match
    {startStr = ""}; # holds the user input meta data for each row
    {dataOnInt = 0}; # if 1 one data column until newline (^$)
    {metaStr = ""}; # just a temporary varaible to hold strings
    {nameStr = ""}; # to hold the reference name after extraction (temporaly)
                 
    #***************************************************************************
    # Sec-1 Sub-2: Check input and parse reference names
    #***************************************************************************

    {FS=" "; OFS=","};

    # check input metadata
    {if(polStr == ""){polStr = "NA"}}; # the polStrisher used
    {if(asmbStr == ""){asmbStr = "NA"}}; # the assembler used 
    {if(depthStr == ""){depthStr = "NA"}}; # coverage for the assembly
    {if(inStr == ""){inStr = "NA"}}; # path to the input fasta file (metadata)
    {if(verStr == ""){verStr = "NA"}}; # version for pomoxis
    {if(idStr == ""){idStr = "NA"}}; # id for the isolet

    # holds the frist 5 columns for each row of data (always same)
    {startStr = inStr "," depthStr "," asmbStr "," polStr "," idStr};

    # extract names and genome types for each reference
    {if(allRefStr != "")
     { # if user supplied a list of references

        # put each reference in an array
        split(allRefStr, refsInStr, "\n");
   
     } # if user supplied a list of references

     else {refsInStr[1] = "";} # no input run without references
    };

    #***************************************************************************
    # Sec-1 Sub-3: print out header of the document
    #***************************************************************************

    {printf "Input,Coverage,Assembler,Polisher,Id,Isolet,Organism"};
    {printf ",Genome-type,Pomoxis-version,Mean-accuracy,Median-accuracy"};
    {printf ",Mean-deletion,Median-deletion,Mean-insertion,Mean-idenity"};
    {printf ",Median-idenity,Median-insertion,Isolet-coverage\n"};

} # begin block 

       
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-2: Get Q-scores
#     sub-1: Determine data type and extrac information in the header
#     sub-2: Get stats (Q score and coverage)
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
              

{if($1 == "#")
 { # if on a data line

     #**************************************************************************
     # Sec-2 Sub-1: Determine data extracting and get header information if can
     #**************************************************************************

     if($3 == "Coverage")
         {dataOnInt = 1;} # if on the coverage line

     else if($2 == "Q")
     { # if on the Q-score line (combinined not ref)
        
         # Set track so I know what kind of data I am extracting
         dataOnInt = 2;

         # print metaData: (startStr has input, coverage, assembler, polisher)
         printf "%s,all,all,all,%s", startStr, verStr;

     } # if on q Qscore line

     else if($0 ~/Q Scores/)
     { # else if grabbing an isolets Q scores

         # set the type of data on (3 is isolet Q-scores)
         dataOnInt = 3;

         # Using metaStr so can use just one print statment
         metaStr = startStr "," $2; # $2 is the isolet name 
             # I am assuming there are no spaces in the name

         # keep track of the reference name to check for missing refs later
         numRefInt = numRefInt + 1;
         refAryStr[numRefInt] = $2; 
         nameStr = refAryStr[numRefInt];

         # get the genome type and isolet name without genome type from name
         {for(intGen = 1; intGen <= length(genListStr); intGen++)
          { # loop though all genome types to check

              indexInt = index(tolower(nameStr), genListStr[intGen]);

              # if was a match to our genome record the genome type
              {if(indexInt > 0)
               { # if found the genome type

                   # get the Organism name
                   {if(indexInt > 1) 
                        {nameStr = substr(nameStr, 0, indexInt - 1);}
                    else if(indexInt == 1) 
                        {nameStr = substr(nameStr, length(genListStr) + 1);}
                   } # if there is more then just the genome type

                   # convert common space replace characters to spaces
                   gsub(/[-,_,\.]/, " ", nameStr); 
                   sub(/^ */, "", nameStr); # get rid of leading spaces
                   sub(/ *$/, "", nameStr); # get rid of trailing spaces

                   metaStr = metaStr "," nameStr;
                   metaStr = metaStr "," genListStr[intGen]; # add genome type
                   break; # stop loop so I know I found a match

               }} # if found the genome type
         }} # loop though and check all genome types

        # if could not id the genome type
        {if(indexInt < 1) {metaStr = metaStr "," $2 ",NA";}} # no genome type 

         # print out the version number
         printf "%s,%s", metaStr, verStr;

     } # else if grabbing an isolets Q scores
 } # if on a data line

 #******************************************************************************
 # Sec-2 Sub-2: Get stats (Q score and coverage)
 #******************************************************************************

 else if($0 ~ /^$/){dataOnInt = 0;} # if on a new line (end of data section)
 else if(dataOnInt > 1) # if on a non coverage row
 { # else if on the combined Q-score line print out data of intrest
     
     if($1 == "err_ont") 
         {printf ",%s,%s", $2, $4;} # Q accuracy
     else if($1 == "iden") 
         {printf ",%s,%s", $2, $4;} # Q idenity
     else if($1 == "del") 
         {printf ",%s,%s", $2, $4;} # Q deletion
     else if($1 == "ins") 
     { # else if on the insertion line (last line)
    
         {if(dataOnInt < 3) 
             {printf ",%s,%s,NA\n", $2, $4;} # Q insertion
          else 
             {printf ",%s,%s,%s\n", $2, $4, covAryStr[numRefInt];}
         } # check if printing out isolet or combined Q-scores
             # Coverage has the same order of refs as Q-scores

     } # else if on the insertion line (last line)

 } # else if on the combined Q-score line print out data of intrest

 else if(dataOnInt == 1)
 { # else if on the coverage line

     intCov = intCov + 1; # counts how many refs grabbed
     covAryStr[intCov] = $2; # ref will be grabbed on isolet Q-score section

 } # else if on the coverage line
} # check if on a data line


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-3: Find and print missing references
#     sub-1: only subsection
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-3 Sub-1: Find and print missing references
#*******************************************************************************

END {

    {for(intAll = 1; intAll <= length(refsInStr); intAll++)
     { # loop though all references the user expected

         {for(intRef = 1; intRef <= numRefInt; intRef++)
          { # loop though all references found
              
              {if(refsInStr[intAll] == refAryStr[intRef])
                   {break;} # if found a match

               else if(intRef == numRefInt)
               { # else if there is no match 

                   nameStr = refsInStr[intAll]; # make life nicer
                   metaStr = startStr "," nameStr; 
  
                   # get the genome type and isolet name
                   {for(intGen = 1; intGen <= length(genListStr); intGen++)
                    { # loop though all genome types to check

                       indexInt = index(tolower(nameStr), genListStr[intGen]);

                       # if was a match to our genome record the genome type
                       {if(indexInt > 0)
                        { # if found the genome type

                           # get the Organism name
                           {if(indexInt > 1) 
                               {nameStr = substr(nameStr, 0, indexInt - 1);}
                           else if(indexInt == 1) 
                               {nameStr= substr(nameStr, length(genListStr)+1);}

                        } # if there is more then just the genome type

                          # convert comman space replacing characters to spaces
                          gsub(/[-,_,\.]/, " ", nameStr);
                          sub(/^ */, "", nameStr); # remove leading spaces
                          sub(/ *$/, "", nameStr); # remove trailing spaces
                          metaStr = metaStr "," nameStr;
                          metaStr = metaStr "," genListStr[intGen];
                          break; # stop loop so I know I found a match

                       }} # if found the genome type
                   }} # loop though and check all genome types

                   # if could not id the genome type
                   {if(indexInt < 1) 
                        {metaStr = metaStr ",NA,NA";}}

                   # put NA for all data entries
                   metaStr = metaStr "," verStr ",NA,NA,NA,NA,NA,NA,NA,NA,NA";

                   printf "%s\n", metaStr; # print out the missing isolet line

              }} # else if there is no match

         }} # loop though all references found
    }} # loop though all references the user expected

} # End block
