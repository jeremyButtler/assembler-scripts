#!/usr/bin/awk -f


################################################################################
# Name: rmExtraHeader.awk
# Use: Makes file with only the frist header line
# Input: 
#     headStr: String with the value first column of the header
#              Used to detect the header so does not print out
# Output:
#     Prints row one and every line without headStr in column 1 ($1)
################################################################################


BEGIN {

    {if(delimStr == ""){delimStr = ","}};
    {FS=OFS=delimStr};

} # Begin block

{if(NR == 1) 
     {print $0;} # if on the first row print (header to keep)
 else if($1 != headStr) 
     {print $0;} # else f not header line print row
}; # Check if on the first row or a later row
