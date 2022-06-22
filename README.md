# Assembler-scripts #

Scripts I used to run assemblers for the 2021 benchmarking study

## How to use ##

1. Modify runAllSubsamples.sh:
    - Variables at top hold the location of the files
    - -d parameter is the read depths testing
    - -p parameter is the prefix to use for file name
2. bash runAllSubsamples.sh

## Adding an assembler ##

1. Modify runAssemblers.sh to recognize the runAssemblerName.sh script
    - Line 84 add your assembler to the list of recongnized assemblers (valdAsmbStr variable)
    - Line 586 Add an if statement to check for your assembler
2. Adds script to run your assembler in the source/assembler directory
    - If copying assembler script from source/assembler
    - Assembler call: Section 4
    - Get user arguments: Section 2

## Other usefull scripts (in extra-scripts) ##

1. metaQuastAddBlank.sh adds a blank entry for replicates that were detected less than 12 times
    - Use: metaQuastAddBlank.sh prefix--metaStats-combined.csv
    - Can be changed from 12 to any other number by changing numIdInt=12 paramter on line 
    - Is needed to avoid ggplot error of unequal numbers of replicates for each sequence
    - Will not detect refences that were completey missed
