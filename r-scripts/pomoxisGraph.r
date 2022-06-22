args = commandArgs(); # get command line input
library("stringr") # convert first letter to uppercase
source(paste(dirname(gsub("--file=", "", args[4])),"graphFunctions.r",sep="/"));
    # dirname grabs the directory and args[4] is the path to this script


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# TOC:
#     section-1: variables
#     section-2: Read in a prepare user input for graphing
#     section-3: Make the graphs
#     section-4: Column names in the data set
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-1: Variable declerations
#     sub-1: Variable declerations
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-1 Sub-1: Variable declerations
#*******************************************************************************

qData = NA;
statData = NA; # Medians and Means for each data point
subData = NA; # for subsampling qData

# graph variables
widthInt=700;
heightInt=400;

# misc variables
graphColAryStr = NA; # will hold columns to graph
nameStr = "";
maxAryDbl = NA;
infMarkInt = 5; # records how far inf values are above the max value
covAryStr = NA;
prefixStr = ""; # prefix for the file names
limitInt = 0; # max y-limit
minYInt = 10;
maxYInt = 54; 
sizeDbl = 1.45; # size of polished cross bar (marking medians)
widthDbl = 10;

# functions
qConvFun = (function(x) if(x < Inf){(1 - (1 / 10^(x/10))) * 100} else{x = 100});
    # converts Accuracys to accruarcy (log base 10)


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-2: Read in and prepare user input for graphing
#     sub-1: Read in user input
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-2 Sub-1: Read in user input
#*******************************************************************************

# Read in the csv file provided by the user
if(length(args) < 6)
{ # if user input some
    stop("A file to get data from must be provided");
} # if user did not input anything 

qData = read.csv(args[6], header = TRUE);

if(length(args) > 6) 
{prefixStr = args[7];} # get the prefix for the output graph names

# get the columns to graph (Median)
graphColAryStr = names(qData)[sapply(names(qData), 
                              FUN = function(x) 
                                    grepl("Median", x, fixed = TRUE))];
graphColAryStr = c(graphColAryStr,
                   names(qData)[sapply(names(qData), 
                                        FUN = function(x) 
                                        grepl("Mean", x, fixed = TRUE))]);


#*******************************************************************************
# Sec-2 Sub-2: Prepare user input for graphing
#*******************************************************************************

for(intCol in 1:length(graphColAryStr))
{ # loop find all max values
    # replace inf with maxvalue
    if(is.na(maxAryDbl[1]))
    { # if is the first loop and I need to clear the NA's
         maxAryDbl=max(qData[which(is.finite(qData[,graphColAryStr[intCol]])),]
                            [,graphColAryStr[intCol]]);
    } else
    { # else is a second loop build up the max values
         maxAryDbl=c(maxAryDbl,
                    max(qData[which(is.finite(qData[,graphColAryStr[intCol]])),]
                        [,graphColAryStr[intCol]]));
    } # else is a second loop build up the max values

    maxAryDbl=max(qData[which(is.finite(qData[,graphColAryStr[intCol]])),]
                            [,graphColAryStr[intCol]]);
} # loop find all max values

#infDbl = max(maxAryDbl) + infMarkInt;
infDbl = 50; # hardcoding since esier to put in

# fill in number NA's with 0, and set Infs to max value + 3
for(intCol in 1:length(graphColAryStr))
{ # loop though all catagories graphing and replace NA's with 0

    # replace NA's with 0
    qData[,graphColAryStr[intCol]]=replace_na(qData[,graphColAryStr[intCol]],0);

    # replace Inf with a value beyond the limit of the data
    qData[,graphColAryStr[intCol]] = sapply(qData[,graphColAryStr[intCol]],
                                            FUN = (function(x) 
                                            if(!is.finite(x))
                                              {x=infDbl}
                                            else{x=x}));

} # loop though all catagories graphing and replace all NA's with 0

#limitInt = infDbl + 10 - (infDbl % 10); # find the nearest power of 10

# replace NA's for polishers with none (so ggplot graphs)
qData$Polisher = replace_na(qData$Polisher, "No");

# replace medaka with polished label
qData$Polished = sapply(qData$Polisher, 
                        FUN = (function (x) ifelse(x=="medaka","Yes",x)));
qData$Organism = gsub(" .*", "", qData$Organism);

qData = qData[(qData$Polished == "Yes" | qData$Polished == "No"),];

# for isolet coverage replace NA's with 0
qData$Isolet.coverage = replace_na(qData$Isolet.coverage, 0);
qData$Gene.number = replace_na(qData$Gene.number, "");
qData$Isolate = paste(qData$Organism, qData$Gene.number, sep = " ");

# convert assembler names to upper case
qData$Assembler = sapply(qData$Assembler, FUN =  (function(x) str_to_title(x)));

# build factors for my catagorical variables
#qData$Coverage = factor(qData$Coverage, levels=sort(unique(qData$Coverage)));
qData$Assembler = factor(qData$Assembler, levels=sort(unique(qData$Assembler)));


qData$Polished = factor(qData$Polished, levels = c("Yes", "No"));
qData$Organism = factor(qData$Organism, levels = sort(unique(qData$Organism)));
qData$Isolate = factor(qData$Isolate, levels = sort(unique(qData$Isolate)));

# sort data by polisher, so data graphed correctly
qData = qData[order(qData$Polished, decreasing = TRUE),];

covAryStr = sort(unique(qData$Coverage)); # for looping


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-3: Make the graphs
#     sub-1: Median Graphs for total Q-scores (both chromosome and plasmid)
#     sub-2: Chromsome graphs for all depths
#     sub-3: Chromsome graphs for each read depth
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#*******************************************************************************
# Sec-3 Sub-1: Median Graph for total Q-scores
#*******************************************************************************
qData = qData[(qData$Polished == "No" | qData$Polished == "Yes"),];
subData = qData[qData$Genome.type == "all",];

if(tolower(prefixStr) == "chromosome")
{ # if looking at the chormosome data set (plasmids have broader range)
    minYInt = 20;
    maxYInt = 50;
    sizeDbl = 0.75; # Very clear for Chromosomes, but not plasmids
    widthDbl = 20;
} # if looking at the chormosome data set (plasmids have broader range)

print(paste(prefixStr, "All coverage Median accuracy graph"));

graph = ggplot(subData,
               aes(y = Median.accuracy,
                   x = Coverage,
                   fill = Polished,
                   shape = Polished
                  ) # aes block
); # graph the data

if(tolower(prefixStr) == "chromosome")
{ # if chromosome use column facets
    graph = graph + 
            facet_grid(cols = vars(!!as.symbol("Assembler")));
} else
{ # else if plasmid do row facets
    graph = graph + 
            facet_grid(rows = vars(!!as.symbol("Assembler")));
} # else if plasmid do row facets

graph = graph + geom_hline(aes(yintercept = 30), lty = 2);

# Do the more global formatting
graph = graph +
        ylab("Median Q-score") +
        xlab("Read depth") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0
        )) + 
        scale_shape_manual(values = c(21, 22)) +
        scale_fill_brewer(type = "qual", palette = "Set2"
); # Format the graph

# Color brewer set 2 pallete "#66C2A5" "#FC8D62" "#8DA0CB" "#E78AC3" "#A6D854"
#                            "#FFD92F" "#E5C494" "#B3B3B3"

graph = plotMedian(graph,
                   data = subData[subData$Polished == "Yes",],
                   yColStr = "Median.accuracy",
                   catAryStr = c("Coverage", "Assembler", "Polished"),
                   colorStr = "#A6D854",
                   sizeDbl = sizeDbl,
                   widthDbl = widthDbl
); # plot the polished data

graph = plotMedian(graph,
                   data = subData[subData$Polished == "No",],
                   yColStr = "Median.accuracy",
                   catAryStr = c("Coverage", "Assembler", "Polished"),
                   #colorStr = "#E78AC3",
                   colorStr = "BLACK",
                   alphaDbl = 0.5,
                   sizeDbl = 0.5,
                   widthDbl = widthDbl
); # plot the unpolished data

graph = applyTheme(graph);
graph = graph + theme(legend.position = "none");

graph = graph + 
        scale_y_continuous(breaks = seq(minYInt, maxYInt, by = 10), 
                           limits = c(minYInt, maxYInt), 
                           sec.axis = sec_axis(trans=~./10, 
                                               name = "Percent accuracy", 
                                               labels = (function(x) 
                                                         x = (1-1/10^(x)) * 100)
                          ));
saveGraph(paste(prefixStr, "--all-Median-accuracy", sep = ""));

#*******************************************************************************
# Sec-3 Sub-3: Graph for 200x median accuracy
#*******************************************************************************

subData = qData[qData$Genome.type != "all" &
                qData$Polished != "No" &
                qData$Coverage == 200,
]; # subsample data for Chromosome or Plasmid

# uncomment if just want community members of concern
#if(tolower(prefixStr) == "chromosome")
#{ # if looking at the chormosome data set
#    subData = subData[(subData$Organism == "Bacillus" |
#                       subData$Organism == "Escherichia" |
#                       subData$Organism == "Salmonella"),
#    ]; # Only keep community members of intestest for chromosome data
#} # if looking at the chormosome data set

graph = ggplot(subData,
               aes(y = Median.accuracy,
                   x = Isolate,
                   fill = Isolate,
                   shape = Isolate
                  ) # aes block
); # graph the data

graph = graph + 
        facet_grid(cols = vars(!!as.symbol("Assembler"))) +
        ylab("Median Q-score") +
        xlab("Community members") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0
        )) + 
        coord_cartesian(ylim = c(0, NA)) + # set y limit 0 to max y value
        scale_shape_manual(values = c(23, 25, 21, 24, 22, 21, 24)) +
        scale_fill_brewer(type = "qual", palette = "Set2");

graph = plotMedian(graph,
                   data = subData,
                   yColStr = "Median.accuracy",
                   catAryStr = c("Assembler", "Isolate"),
                   widthDbl = 1); # add median to graph,1=crossbar width
graph = applyTheme(graph);

print(paste(prefixStr, "--200x Median accuracy graph"));

graph = graph +
        theme(legend.title = element_blank()) +
        theme(axis.text.x = element_text(face = "bold.italic")) +
        theme(legend.position = "none"); # remove legend
graph = percAxis(graph, "Q-score");
saveGraph(paste(prefixStr, "--200x-Median-accuracy", sep = ""));

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Section-4: Column names in the data set
#     sub-1: Column names in the data set
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

#*******************************************************************************
# Sec-4 Sub-1: Column names in the data set
#*******************************************************************************

## "Input"
## "Coverage"
## "Assembler"    
## "Polisher"        
## "Id"
## "Isolet"
## "Organism"
## "Genome.Type"  
## "Gene.number"
## "Pomoxis.version" 
## "Mean.accuracy"   
## "Median.accuracy"
## "Mean.idenity"
## "Median.idenity" 
## "Mean.deletion"   
## "Median.deletion"
## "Mean.insertion"
## "Median.insertion"
## "Isolet.coverage" 
#
