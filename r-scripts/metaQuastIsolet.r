args = commandArgs(); # get command line input
library("tidyr") # for replace_na
library("ggplot2") # for ggplot
library("data.table"); # for applying functions to data frames by groups
library("stringr") # convert first letter of assembler name to upper case
source(paste(dirname(gsub("--file=", "", args[4])),"graphFunctions.r",sep="/"));
    # dirname grabs the directory and args[4] is the path to this script

# Variables (data frames)
qData = NA; # load when processing user input
subData = NA; # holds subsets of qData
tmpData = NA; # holds a tempory subset of subData
statData = NA; # holds the stas for each assembler

# graph variables
widthInt=700;
heightInt=600;

# General use
covAryStr = NA;

# variables to make graphs for or name graphs
catAryStr = c("X..contigs", "Genome.fraction....", "X..misassemblies");
nameStr = c("contigs", "genFrac", "missAssemble");
yLabStr = c("Number of contigs", 
            "Genome fraction (%)", 
            "Number miss-assemblies");


# Read in the csv file provided by the user
if(length(args) < 6)
{ # if user input some
    stop("A file to get data from must be provided");
} else if(length(args) > 6)
{ stop("Multiple files input, but this script only uses one file");}

qData = read.csv(args[6], header = TRUE);

#*******************************************************************************
# Set up data for graphing
#*******************************************************************************

# set up arrays
isoAryStr = unique(qData$Isolet);

# replace NA's for polishers with none (so ggplot graphs)
qData$Polisher = replace_na(qData$Polisher, "No");
qData$Genome.fraction.... = replace_na(qData$Genome.fraction...., 0);
qData$X..contigs = replace_na(qData$X..contigs, 0);
qData$X..misassemblies = replace_na(qData$X..misassemblies, -1);
qData$Gene.number = replace_na(qData$Gene.number, "");

# convert assembler names to upper case
qData$Assembler = sapply(qData$Assembler, FUN =  (function(x) str_to_title(x)));

# replace medaka with polished label
qData$Polished = sapply(qData$Polisher, 
                        FUN = (function (x) ifelse(x=="medaka","Yes",x)));
qData$Organism = gsub(" .*", "", qData$Organism);

qData$Source = paste(qData$Organism, qData$Gene.number, sep = " ");

# just getting column names (at bootom of document now)
#print(names(qData)); stop("done");

# make graphs

# set up factors
# build factors for my catagorical variables
#qData$Coverage = factor(qData$Coverage, levels=sort(unique(qData$Coverage)));
qData$Assembler = factor(qData$Assembler, levels=sort(unique(qData$Assembler)));
qData$Organism = factor(qData$Organism, levels = sort(unique(qData$Organism)));
qData$Source = factor(qData$Source, levels = sort(unique(qData$Source)));
qData$Polished = factor(qData$Polished, levels = c("No", "Yes"));
subData = qData[qData$Polished == "No" | qData$Polished == "Yes",];

# set up array of read depths to cycle through (sort for sanity)
covAryStr = sort(unique(subData$Coverage));

#*******************************************************************************
# Chromosome meta genome fraction
#*******************************************************************************

subData = qData[qData$Genome.Type == "chromosome" &
                qData$Polished == "Yes" &
                !is.na(qData$Polished),]; # red bean wtpoa polished

print("chromosome meta-genome fraction for all replicates at all depths graph");

# Find the number of bases aligned to the reference
subData$numRefBases=subData$Reference.length*(subData$Genome.fraction..../100);
   # number of references bases in the comunity member

conData = getDataSum(subData,
                     "numRefBases",
                     c("Input", "Coverage", "Assembler", "Polished")
); # get the total number of refernce bases per replicate

# get the metagenome length (remove duplicates and sum lengths)
metaRefLenInt = sum(subData[!duplicated(subData$Organism),]$Reference.length);
    # duplicated is grabbing all rows that are duplicates
    # !dulicated is reversing it so only non duplicated rows are grabbed

# Get the meta genome fraction
conData$metaGenFracDbl = (conData$sumCol / metaRefLenInt) * 100 # aligned bases / meta ref length

graph = ggplot(conData,
               aes(y = metaGenFracDbl,
                   x = Coverage,
                   fill = as.character(cut(as.numeric(Coverage),
                                            breaks = c(0, 10, 20, 30, 50, 100, 200),
                                            labels = c(10, 20, 30, 50, 100, 200)
                                       )), # convert read depth to character
                   shape = as.character(cut(as.numeric(Coverage),
                                            breaks = c(0, 10, 20, 30, 50, 100, 200),
                                            labels = c(10, 30, 20, 50, 100, 200)
                                       )) # convert read depth to character
                  ) # aes block
); # graph the data

graph = graph + 
        facet_grid(cols = vars(!!as.symbol("Assembler"))) +
        ylab("Meta-genome fraction") +
        xlab("Read depth") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0
        )) + 
        scale_shape_manual(values = c(24, 21, 23, 25, 22, 21)) +
        scale_fill_brewer(type = "qual", palette = "Set2");

graph = plotMedian(graph,
                   data = conData,
                   yColStr = "metaGenFracDbl",
                   catAryStr = c("Assembler", "Coverage"),
                   widthDbl = 20
); # add median to graph, 20=crossbar width

graph = applyTheme(graph);
graph = graph + theme(legend.position = "none");
saveGraph("Chromosome-meta-genFrac");

#*******************************************************************************
# Chromosome 200x genome fraction graph
#*******************************************************************************

subData = subData[subData$Polished == "Yes",]; #& # only keep certian memebers
#                  (subData$Organism == "Bacillus" | 
#                   subData$Organism == "Escherichia" |
#                   subData$Organism == "Salmonella"),];

print("makeing 200x genome fraction graph");

#tmpData = subData[subData$Coverage == depthAryInt[intDepth],];
graph = ggplot(subData[subData$Coverage == 200 &
                       !is.na(subData$Assembler),
                      ],
               aes(y = Genome.fraction....,
                   x = Organism,
                   fill = Organism,
                   shape = Organism,
                  ) # aes values for graph
); # graph the data

graph = plotMedian(graph,
                   data = subData[subData$Coverage == 200 &
                                  !is.na(subData$Assembler),],
                   yColStr = "Genome.fraction....",
                   catAryStr = c("Assembler", "Organism"),
                   widthDbl = 1
); # add median to graph, 1=crossbar width

graph = graph +
        facet_grid(cols = vars(!!as.symbol("Assembler"))) +
        ylab("Genome fraction") +
        xlab("Community member") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0,
        )) +
        coord_cartesian(ylim = c (0, NA)) + # set ylim from 0 to max ylim
        scale_shape_manual(values = c(23, 25, 21, 24, 22, 21, 24)) +
        scale_fill_brewer(type = "qual", palette = "Set2");

graph = applyTheme(graph); # apply my theme to the graph
graph = graph + theme(axis.text.x = element_text(face = "bold.italic")); # italize
graph = graph + theme(legend.position = "none") # remove legend

saveGraph("Chromosome--200x--Genome-fraction");

#*******************************************************************************
# Chromosome 200x misassembly graph
#*******************************************************************************

print("making Chromosome 200x read depth miss-assemblies graph");

#tmpData = subData[subData$Coverage == depthAryInt[intDepth],];
graph = ggplot(subData[subData$Coverage == 200 &
                       !is.na(subData$Assembler),
                      ],
               aes(y = X..misassemblies,
                   x = Organism,
                   fill = Organism,
                   shape = Organism,
                  ) # aes values for graph
); # graph the data

graph = plotMedian(graph,
                   data = subData[subData$Coverage == 200 &
                                  !is.na(subData$Assembler),],
                   yColStr = "X..misassemblies",
                   catAryStr = c("Assembler", "Organism"),
                   widthDbl = 1
); # add median to graph, 1=crossbar width

graph = graph +
        facet_grid(cols = vars(!!as.symbol("Assembler"))) +
        ylab("Number of misassemblies") +
        xlab("Community member") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0,
        )) +
        coord_cartesian(ylim = c (0, NA)) + # set ylim from 0 to max ylim
        scale_shape_manual(values = c(23, 25, 21, 24, 22, 21, 24)) +
        scale_fill_brewer(type = "qual", palette = "Set2");

graph = applyTheme(graph); # apply my theme to the graph
graph = graph + theme(axis.text.x = element_text(face = "bold.italic")); # italize
graph = graph + theme(legend.position = "none") # remove legend

saveGraph("Chromosome--200x--misassembly");


#*******************************************************************************
# Plasmid graph for meta-genome fraction
#*******************************************************************************

subData = setDT(qData[qData$Genome.Type == "plasmid" &
                qData$Polished == "Yes",
]); # subset my dataset

# for meta-genome fraction, just use the polished data
subData$Genome.fraction.... = replace_na(subData$Genome.fraction...., 0);
subData$Reference.length = replace_na(subData$Reference.length, 0);

# Get the number of reference bases in each assembly
subData$numRefBases=subData$Reference.length*(subData$Genome.fraction..../100);

conData = subData[, data.frame(metaGenFracDbl = sum(numRefBases)),
                    by = c("Input", "Coverage", "Assembler")
]; # get the total number of aligned bases per replicate

metaRefLenInt = sum(subData[!duplicated(subData$Source) &
                            !is.na(subData$Source),
                           ]$Reference.length
); # get the acutal metagenome length

# Get the metagenome fraction (aligned bases / meta ref length)
conData$metaGenFracDbl = (conData$metaGenFracDbl / metaRefLenInt) * 100;
conData = conData[!(is.na(conData$Assembler)),]; # remove empty rows

print("plasmid meta-genome fraction Median replicate at all depths graph");
graph = ggplot(conData,
               aes(y = metaGenFracDbl,
                   x = Coverage,
                   fill = as.character(cut(as.numeric(Coverage),
                                            breaks = c(0, 10, 20, 30, 50, 100, 200),
                                            labels = c(10, 20, 30, 50, 100, 200)
                                       )), # convert read depth to character
                   shape = as.character(cut(as.numeric(Coverage),
                                            breaks = c(0, 10, 20, 30, 50, 100, 200),
                                            labels = c(10, 30, 20, 50, 100, 200)
                                       )) # convert read depth to character
)); # graph the data

graph = graph + 
        facet_grid(cols = vars(!!as.symbol("Assembler"))) +
        ylab("Meta-genome fraction") +
        xlab("Read depth") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0
        )) + 
        scale_shape_manual(values = c(24, 21, 23, 25, 22, 21)) +
        scale_fill_brewer(type = "qual", palette = "Set2");

graph = plotMedian(graph,
                   data = conData,
                   yColStr = "metaGenFracDbl",
                   catAryStr = c("Assembler", "Coverage"),
                   widthDbl = 20
); # add median to graph, 20=crossbar width

graph = applyTheme(graph);
graph = graph + theme(axis.text.x = element_text(face = "bold.italic")); # italize
graph = graph + theme(legend.position = "none");
saveGraph("Plasmid-metaGenFrac");

#*******************************************************************************
# Plasmid graph for the 200x genome fraction
#*******************************************************************************

print("Making graph for genome fraction at 200x read depth");
graph = ggplot(subData[subData$Coverage == 200 &
                       ! is.na(subData$Assembler),
                      ],
               aes(y = Genome.fraction....,
                   x = Source,
                   fill = Source,
                   shape = Source,
)); # graph the data

graph = graph +
        facet_grid(cols = vars(!!as.symbol("Assembler"))) +
        ylab("Genome fraction") +
        xlab("Community member") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0,
        )) +
        coord_cartesian(ylim = c (0, NA)) + # set ylim from 0 to max ylim
        scale_shape_manual(values = c(24, 21, 23, 25, 22, 21)) +
        scale_fill_brewer(type = "qual", palette = "Set2");

graph = plotMedian(graph,
                   data = subData[subData$Coverage == 200 &
                                  ! is.na(subData$Assembler),],
                   yColStr = "Genome.fraction....",
                   catAryStr = c("Assembler", "Source"),
                   widthDbl = 1
); # add median to graph, 1=crossbar width

graph = applyTheme(graph); # apply my theme
graph = graph + theme(axis.text.x = element_text(face = "bold.italic")); # italize
graph = graph + theme(legend.position = "none"); # remove the legened (not needed)
saveGraph("Plasmid--200x--genome-fraction");

#*******************************************************************************
# Plasmid graph for 50x genome fraction
#*******************************************************************************

print("Making graph for genome fraction at 50x read depth");
graph = ggplot(subData[subData$Coverage == 50 &
                       !is.na(subData$Assembler),
                      ],
               aes(y = Genome.fraction....,
                   x = Source,
                   fill = Source,
                   shape = Source,
)); # graph the data
graph = graph +
        facet_grid(cols = vars(!!as.symbol("Assembler"))) +
        ylab("Genome fraction") +
        xlab("Community member") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0,
                                             ) # jitter
        ) + # geom_piont
        coord_cartesian(ylim = c (0, NA)) + # set ylim from 0 to max ylim
        scale_shape_manual(values = c(24, 21, 23, 25, 22, 21)) +
        scale_fill_brewer(type = "qual", palette = "Set2");

graph = plotMedian(graph,
                   data = subData[subData$Coverage == 50 &
                                  !is.na(subData$Assembler),],
                   yColStr = "Genome.fraction....",
                   catAryStr = c("Assembler", "Source"),
                   widthDbl = 1
); # add median to graph, 1=crossbar width

graph = applyTheme(graph); # apply my theme
graph = graph + theme(axis.text.x = element_text(face = "bold.italic")); # italize
graph = graph + theme(legend.position = "none"); # remove the legened (not needed)
saveGraph("Plasmid--50x--genome-fraction");

#*******************************************************************************
# Plasmid graph for 30x genome fraction
#*******************************************************************************

print("Making graph for genome fraction at 30x read depth");
graph = ggplot(subData[subData$Coverage == 30 &
                       !is.na(subData$Assembler),
                      ],
               aes(y = Genome.fraction....,
                   x = Source,
                   fill = Source,
                   shape = Source,
)); # graph the data
graph = graph +
        facet_grid(cols = vars(!!as.symbol("Assembler"))) +
        ylab("Genome fraction") +
        xlab("Community member") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0,
                                             ) # jitter
        ) + # geom_piont
        coord_cartesian(ylim = c (0, NA)) + # set ylim from 0 to max ylim
        scale_shape_manual(values = c(24, 21, 23, 25, 22, 21)) +
        scale_fill_brewer(type = "qual", palette = "Set2");

graph = plotMedian(graph,
                   data = subData[subData$Coverage == 30 &
                                  !is.na(subData$Assembler),],
                   yColStr = "Genome.fraction....",
                   catAryStr = c("Assembler", "Source"),
                   widthDbl = 1
); # add median to graph, 1=crossbar width


graph = applyTheme(graph); # apply my theme
graph = graph + theme(axis.text.x = element_text(face = "bold.italic")); # italize
graph = graph + theme(legend.position = "none"); # remove the legened (not needed)
saveGraph("Plasmid--30x--genome-fraction");

#*******************************************************************************
# Plasmid graph for 20x genome fraction
#*******************************************************************************

print("Making graph for genome fraction at 20x read depth");
graph = ggplot(subData[subData$Coverage == 20 &
                       !is.na(subData$Assembler),
                      ],
               aes(y = Genome.fraction....,
                   x = Source,
                   fill = Source,
                   shape = Source,
)); # graph the data
graph = graph +
        facet_grid(cols = vars(!!as.symbol("Assembler"))) +
        ylab("Genome fraction") +
        xlab("Community member") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0,
                                             ) # jitter
        ) + # geom_piont
        coord_cartesian(ylim = c (0, NA)) + # set ylim from 0 to max ylim
        scale_shape_manual(values = c(24, 21, 23, 25, 22, 21)) +
        scale_fill_brewer(type = "qual", palette = "Set2");

graph = plotMedian(graph,
                   data = subData[subData$Coverage == 20 &
                                  !is.na(subData$Assembler),],
                   yColStr = "Genome.fraction....",
                   catAryStr = c("Assembler", "Source"),
                   widthDbl = 1
); # add median to graph, 1=crossbar width


graph = applyTheme(graph); # apply my theme
graph = graph + theme(axis.text.x = element_text(face = "bold.italic")); # italize
graph = graph + theme(legend.position = "none"); # remove the legened (not needed)
saveGraph("Plasmid--20x--genome-fraction");

#*******************************************************************************
# Plasmid graph for 20x misassemblies
#*******************************************************************************

print("Making graph for misassemblies at 20x read depth");
graph = ggplot(subData[subData$Coverage == 200 &
                       !is.na(subData$Assembler),
                      ],
               aes(y = X..misassemblies,
                   x = Source,
                   fill = Source,
                   shape = Source,
)); # graph the data
graph = graph +
        facet_grid(cols = vars(!!as.symbol("Assembler"))) +
        ylab("Misassemblies") +
        xlab("Community member") +
        geom_point(alpha = 0.5,
                   cex = 4,
                   position = position_jitter(width = 0.3,
                                              height = 0,
                                             ) # jitter
        ) + # geom_piont
        coord_cartesian(ylim = c (0, NA)) + # set ylim from 0 to max ylim
        scale_shape_manual(values = c(24, 21, 23, 25, 22, 21)) +
        scale_fill_brewer(type = "qual", palette = "Set2");

graph = plotMedian(graph,
                   data = subData[subData$Coverage == 200 &
                                  !is.na(subData$Assembler),],
                   yColStr = "X..misassemblies",
                   catAryStr = c("Assembler", "Source"),
                   widthDbl = 1
); # add median to graph, 1=crossbar width


graph = applyTheme(graph); # apply my theme
graph = graph + theme(axis.text.x = element_text(face = "bold.italic")); # italize
graph = graph + theme(legend.position = "none"); # remove the legened (not needed)
saveGraph("Plasmid--200x--misAssemblies");




##*******************************************************************************
## Plasmid graphs for each read depth
##*******************************************************************************
#
#subData = subData[subData$Polished == "Yes",];
#
#makeGraphLev(subData,
#             yColStr = catAryStr,
#             xColStr = "Assembler",
#             gridColStr = "Source",
#             levColStr = "Coverage",
#             nameStr = paste("Plasmid", nameStr, sep = "-"),
#             colorColStr = "Source",
#             yLabStr = yLabStr,
#             yInterceptInt = c(1, NA, 0),
#             rmFacuetBool = 1);
#
##*******************************************************************************
## Variables in the metaQuast file
##*******************************************************************************
#
## Input
## Coverage
## Assembler
## Polisher
## Isolet
## Organism
## Genome.Type
## metaQuast.version
## X..contigs.....0.bp.
## X..contigs.....1000.bp.
## X..contigs.....5000.bp.
## X..contigs.....10000.bp.
## X..contigs.....25000.bp.
## X..contigs.....50000.bp.
## Total.length.....0.bp.
## Total.length.....1000.bp.
## Total.length.....5000.bp.
## Total.length.....10000.bp. 
## Total.length.....25000.bp.
## Total.length.....50000.bp. 
## X..contigs
## Largest.contig
## Total.length
## Reference.length
##GC....
##Reference.GC....
## N50
## N90
## L50
## L90
## X..misassemblies
## X..misassembled.contigs
## Misassembled.contigs.length
## X..local.misassemblies
## X..scaffold.gap.ext..mis.
## X..scaffold.gap.loc..mis.
## X..unaligned.mis..contigs
## X..unaligned.contigs
## Unaligned.length
## Genome.fraction....
## Duplication.ratio
## X..N.s.per.100.kbp
## X..mismatches.per.100.kbp
## X..indels.per.100.kbp
## Largest.alignment
## Total.aligned.length
## NA50
## NA90
## LA50
## LA90
#
## What is in the args variable
#   # for args 1 is R call location
#   #          2 --no-echo # not sure what is
#   #          3 --no-restore # not sure what is
#   #          4 script name # --file=name
#   #          5 --args # thinks start of args
#   #          6 and > user input arguments
#
