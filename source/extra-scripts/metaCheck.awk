#!/usr/bin/awk -f
# Input: numId and file
BEGIN{
    FS=OFS=","; 
    restSetOldIdInt = 0; # reset when move to different set of replicates
        # starting at 0, because loops add 1
    oldIdInt = restSetOldIdInt; # should start index of 1
    idInt = -1;
    prefStr = "";
    sufStr = "";
    lineStr = ""; # temporarly holds the blank input name

    # Number of NA's needed to cover each column from metaQuast
    NaLineStr = "NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA";
    NaLineStr = NaLineStr ",NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA";
    NaLineStr = NaLineStr ",NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA";

    lastLineStr = ""; # holds the metadata from the last row
    lastPrefStr = ""; # holds the prefix and metadata parts of the file name 
    lastSufStr = ""; # holds the non id part of the suffix (idStr[2])
    nameStr = "";
    {if(numIdInt == ""){numIdInt = 12}};
}; # begin block 

{if(NR != 1)
 { # if not on the first row

    # get the prefix
    prefStr = $1;
    gsub(/--[0-9]*-polished.fasta/, "", prefStr);
    gsub(/--[0-9]*\.fasta/, "", prefStr);

    # get the number and suffix
    idInt = $1;
    gsub(/.*--/, "", idInt);
    sufStr = idInt;
    gsub(/[0-9]*/, "", sufStr);
    gsub(/\..*/, "", idInt);
    gsub(/-.*/, "", idInt);
    idInt = idInt + 0;
    
    # set up blank line except for the assembler input
    lineStr = $2 "," $3 "," $4 "," $5 "," $6 "," $7 "," $8;

    {if(NR == 2)
     { # else if on the first replicate, set last pref
        lastLineStr = lineStr;
        lastPrefStr = prefStr;
        lastSufStr = sufStr;
     }
     else if(prefStr != lastPrefStr)
     { # if starting a new replicate, make sure all old replicate present
         for(intId = oldIdInt + 1; intId <= numIdInt; intId++)
         { # print out blanrk rows till at the row with data
             # check if need to add a 0 to the number
             {if(intId < 10){nameStr = lastPrefStr "--0" intId lastSufStr;} 
              else{nameStr = lastPrefStr "--" intId lastSufStr;}}
             printf "%s,%s,%s\n", nameStr, lastLineStr,  NaLineStr;
         } # print out blank rows till at the row with data

         oldIdInt = restSetOldIdInt; # starting new line
         lastLineStr = lineStr;
         lastPrefStr = prefStr;
         lastSufStr = sufStr;
    }}  # if starting a new replicate, make sure all old replicate present
   
    for(intId = oldIdInt + 1; intId < idInt; intId++)
    { # print out blank rows till at the row with data
        # check if need to add a 0 to the number
        {if(intId < 10) {nameStr = prefStr "--0" intId sufStr;}
         else {nameStr = prefStr "--" intId sufStr;}}
        printf "%s,%s,%s\n", nameStr, lineStr, NaLineStr;
    } # print out blank rows till at the row with data

     oldIdInt = idInt;
 } # if not on the first row
} # check if on the frist row

{print $0};
