# Note unix OS only
args = commandArgs(); # get command line input
library("tidyr") # for replace_na
library("ggplot2") # for ggplot
library("stringr") # for str_to_title (so can capitalize assembler names)
source(paste(dirname(gsub("--file=", "", args[4])),"graphFunctions.r",sep="/"));
    # dirname grabs the directory and args[4] is the path to this script

qData = NA;
subData = NA; # for subsampling qData

# Read in the csv file provided by the user
if(length(args) < 6)
{ # if user input some
    stop("A file to get data from must be provided");
} else if(length(args) > 6)
{ stop("Multiple files input, but this script only uses one file");}

qData = read.csv(args[6], header = TRUE);

# replace NA's for polishers with none (so ggplot graphs)
qData$Polisher = replace_na(qData$Polisher, "none");
# convert assembler names to upper case
qData$Assembler = sapply(qData$Assembler, FUN = (function(x) str_to_title(x)));

# make graphs

# Run time for the assemblers only
subData = qData[(qData$Polisher == "none"),]; # remove polishers
# convert time to minutes
subData$Elapsed.time = subData$Elapsed.time/60; 
subData$cpuTime = (subData$System.time + subData$User.time)/60; 

graph = pointGraph(subData, 
                  yColStr = "Elapsed.time", 
                  xColStr = "Coverage", 
                  yLabStr = "Time to build assembly in minutes", 
                  xLabStr = "Read depth", 
                  colorColStr = "Assembler", 
                  #shapeColStr = "Assembler", 
                  plotStatBool = 0,
                  jitXDbl = 4);
saveGraph("elapsedTime");

graph = pointGraph(subData, 
                  yColStr = "cpuTime", 
                  xColStr = "Coverage", 
                  yLabStr = "Cpu time to build assembly in minutes", 
                  xLabStr = "Read depth", 
                  colorColStr = "Assembler", 
                  #shapeColStr = "Assembler", 
                  plotStatBool = 0,
                  jitXDbl = 4);
saveGraph("cpuTime");


# convert memory to gigabytes
subData$Max.resident.memory.kb = subData$Max.resident.memory.kb / 1000000;

graph = pointGraph(subData, 
                  yColStr = "Max.resident.memory.kb", 
                  xColStr = "Coverage", 
                  yLabStr = "Max memory used to build assembly (in gigabytes)", 
                  xLabStr = "Read depth", 
                  colorColStr = "Assembler", 
                  #shapeColStr = "Assembler", 
                  plotStatBool = 0,
                  jitXDbl = 4);
saveGraph("maxMemory");
