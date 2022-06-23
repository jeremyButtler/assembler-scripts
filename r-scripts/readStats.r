library("data.table")
library("dplyr")     # Select function

namesAryStr = "";
readStatDf = read.csv("read-stats.tsv", header = TRUE, sep = "\t");

# get the headers
namesAryStr = sub("^X", "", names(readStatDf))[-1];
    # the first column just has replicate (want to remove)

#*****************************************************************************
# Add in the meta data
#*****************************************************************************

# Expand the existing data frame to add in meta data rows
readStatDf[seq(3,nrow(readStatDf)+2),]=readStatDf[seq(1,nrow(readStatDf)),];
    # seq is starting index at row 4 and adding two new rows to readStatDf
    # Setting row four of expand readStatDf to row two of original readStatDf
    # At this piont rows 2 and 3 are duplicates and can be replaced

# add in the depth and replicate metadata
readStatDf[1,] = c("depth", as.integer(sub("x.*", "", namesAryStr)));
readStatDf[2,] = c("replicate", as.integer(sub(".*x", "", namesAryStr)));

#*****************************************************************************
# Remove unneeded columns
#*****************************************************************************

colnames(readStatDf) = NULL;                  # remove the column names

# get the first column names (these are stats names)
readStatDf = readStatDf[seq(from = 1, to = 11, by = 1),];
                                               # removes Q># lines,
                                               # highest_Q_read lines, and
                                               # longest_read:2 to 5 lines
namesAryStr = readStatDf[,1];                  # get type of stat
namesAryStr = sub(":[0-9]*", "", namesAryStr); # remove :1 from longest_read:1

readStatDf = as.data.frame(t(readStatDf[,-1])); # do not transpose 1st column
                                                # First column has stat names
colnames(readStatDf) = namesAryStr;             # add in the column names

#*****************************************************************************
# Get mean values for each replicate
#*****************************************************************************

readStatDf = setDT(readStatDf);                  # datatable easier to work on

readStatDf[, mean(as.integer(number_of_reads)), by = c("depth")];
readStatDf[, sd(as.integer(number_of_reads)), by = c("depth")];

readStatDf[, mean(as.integer(n50)), by = c("depth")];
readStatDf[, sd(as.integer(n50)), by = c("depth")];

readStatDf[, mean(as.double(number_of_bases) / 1000000), by = c("depth")];
readStatDf[, sd(as.double(number_of_bases) / 1000000), by = c("depth") ];
# 200x read depth has more bases than int can handle, so using double (64 bit)
