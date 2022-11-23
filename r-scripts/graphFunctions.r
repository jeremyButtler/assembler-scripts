library("ggplot2"); # graphing
library("data.table"); # for applying functions to data frames by groups
library("ggstatsplot") # for adding in medians (no longer used)
library("ggpubr") # theme_pubr() for ggplots
#library("viridis") # color blind pallets
library("RColorBrewer") # for quantative color scheme
library("tidyr") # for replace_na
#library("ggpubfigs") # color blind pallete and themes

################################################################################
# TOC
# Name: graphFunctions
# Use: graph functions needed for my assembly stats scripts
# Functions:
#     applyTheme: Apply my graph preferences to a graph
#     getDataSum: Does a sum by category (more for ease across scripts) 
#     getDataMed: Does a Median by category (more for ease across scripts) 
#     makeGraphLev: Wrapper for repeated call of pointGraph (saves graphs)
#     maViolinGraphLev: Wrapper for repeated call of pointGraph (saves graphs)
#     percAxis: Adds second y-axis and converts Q-score to percent
#     plotMedian: Plot the median using ggstatsplot
#     pointGraph: My graphing coding that uses ggplot
#                ISSUE: no default shape col acting up (deal with later)
#     boxPlotGraph: My graphing code to make a boxplot plot that ggplot
#                ISSUE: no default shape col acting up (deal with later)
#     saveGraph: Wrapper for ggsave (allows easy mass change graph options)
################################################################################

################################################################################
# Name: applyTheme
# Use: Apply my theme settings to a ggplot graph
# Input: ggplot graph object to apply the theme to
# Output: ggplot graph object with the applied theme
# Requires: ggpubr, ggplot2
################################################################################
applyTheme = function(graph, fontSizeInt = 10)
{ # applyTheme function
    graph = graph + 
        theme_pubr() + # nice clean theme to apply to my graph
        theme(panel.grid.major = element_blank(), # remove graph grid
              panel.grid.minor = element_blank(), # remove graph grid
              strip.background = element_blank(), # rm label shape in the faucet graph
#              strip.text = element_blank(, face = "bold"), # remove faucet labels likely faucet graph
#              strip.text = element_text(angle = 50, vjust = 0.4, face = "bold"),
              axis.text.x = element_text(angle = 90, vjust=0.7, face = "bold"),
              axis.text = element_text(size = fontSizeInt, face = "bold"), # axis tick labels
              axis.title.y = element_text(size = fontSizeInt, face = "bold"),
              axis.title.x = element_text(size = fontSizeInt, face = "bold"),
              legend.title = element_text(size = fontSizeInt, face = "bold"),
              legend.text = element_text(size = fontSizeInt, face = "bold"), # change the legend text
              strip.text = element_text(size = fontSizeInt, face = "bold"), # increase facet text size
                  # adjust x-axis text so at 45 degree angle
              #vvvvvvvvvvv-remove the background color-vvvvvvvvvvvvvvvvvvvvvvvvv
              panel.background = element_rect(color="WHITE", fill="WHITE"),
              plot.background = element_rect(color = "WHITE", fill = "WHITE"),
              #^^^^^^^^^^^-remove the background color-^^^^^^^^^^^^^^^^^^^^^^^^^
              axis.ticks = element_blank(), # remove the axis tick marks
              axis.line = element_line(color = "BLACK"), # axis line to black
              legend.background = element_rect(fill=NA)); 
                   # remove the legend background
#              legend.text = element_blank());
    return(graph);
} # applyTheme function


################################################################################
# Name: getDataSum
# Use: get the sum of a data frame column grouped by input columns
# Input: 
#     data: data frame with data to get sum for
#     sumCol: String with the column in the data frame to do the sum on
#     catAryStr: String array with the columns to group each row by for the sum
# Output:
#    data frame: with summary and columns in catAryStr
#        sumCol: Holds the summed results for each category
# Note: mainly here so takes less space in my code (not really used)
################################################################################
getDataSum = function(data, sumColStr, catAryStr)
{ # getDataSum function
    tmpData = setDT(data);
    return(tmpData[, data.frame(sumCol = sum(get(sumColStr))), 
                     by = catAryStr]);
} # getDataSum function

################################################################################
# Name: getDataMed
# Use: get the Median of a data frame column grouped by input columns
# Input: 
#     data: data frame with data to get sum for
#     medCol: String with the column in the data frame to do the Median on
#     catAryStr: String array with the columns to group each row by for the sum
# Output:
#    data frame: with median and columns in catAryStr
#        medCol: Holds the median for each category
# Note: mainly here so takes less space in my code (not really used)
################################################################################
getDataMed = function(data, medColStr, catAryStr)
{ # getDataMed function
    tmpData = setDT(data);
    return(tmpData[, data.frame(medCol = median(get(medColStr), rm.na = TRUE)), 
                     by = catAryStr]);
} # getDataMed function


################################################################################
# Name: makeGraphLev
# Use: Loops though an input column in a data frame and calls pointGraph for each
#      level in the column
# Input:
#     data: data frame with data to graph
#     yColStr: String with the column for the y-axis 
#         Note: Can be input as an array, but nameStr must be an array of at
#               least equal length
#     xColStr: string with the column for the x-axis
#     gridColStr: Sting with the column to use as columns for the faucet graph
#     levColStr: String with the column to make graphs for
#     NameStr: string with the prefix to name the graph
#         Note: If yColStr is an array this must be an array of equal length
#     yLabStr: String with the y-label to use for the y-axis
#         Default: Nothing
#     xLabStr: String with the x-axis label 
#         Default: NA (do not apply one, but use ggplots default)
#     colorColStr: String with the column to use for the color column
#         Default: Organism
#     shapeColStr: String with the column to use for the shapes
#         Default: Polisher
#     yInterceptInt: Integer array with the intercepts of horizontal lines for
#                    each graph. 
#         Note: Size must be equal to yColStr or equal to 1 (ignored if 1)
#         Default: No line
#     widthInt: Integer with width of graph in pixals? 
#         Defualt: 700
#     heightInt: Integer with the height of the graph in pixels?
#         Defualt: 600
#     rmFaucetXLabBool: integer with 1 or 0 to remove the faucet x labels from
#                       the graph.
#         Default: 0 (keep the labels)
#     scaleBool: Integer with 1 or 0. Decides if should scale graph at 0 or not
#         Default: 1 (scale graph). 0 means use ggplots default
#     statBeforeBool: integer with 1 or 0. If 1 plot the stat before adding 
#                     points
#         Default: 0
# Output:
#     png: with graph for each level in the levColStr
# Requires: pointGraph
################################################################################
makeGraphLev = function (data, yColStr, xColStr, gridColStr, levColStr, 
                         nameStr, yLabStr = "", xLabStr = NA, 
                         colorColStr = "Organism", shapeColStr = "Polisher", 
                         yInterceptInt = NA, widthInt = 700, heightInt = 600, 
                         rmFacuetBool = 0, scaleBool = 1, statBeforeBool = 0)
{ # makeGraphLev
    tmpData = NA;
    levAryStr = sort(unique(data[[levColStr]]));
        # using data[[leveColStr]] to grab just the column of intrest

    if(length(yColStr) < length(nameStr))
    {stop("for makeGraphLev the number of y columns must match number of names");}

    if(length(yColStr) < length(yLabStr))
    {stop("The number of y columns must match number of labels");}


    if(length(yInterceptInt) > 1 && length(yInterceptInt) < length(yColStr))
    {stop("number of intercepts must be 1 or equal the number of y columns");}

    for(intLen in 1:length(levAryStr))
    { # loop and make plasmid graphs for all coverages

        if(length(yColStr) < 2)
        { # if just making one graph
            print(paste(nameStr, levAryStr[intLen]));
            graph = pointGraph(data[data[[levColStr]] == levAryStr[intLen],],
                          yColStr = yColStr,
                          xColStr = xColStr,
                          gridColStr = gridColStr,
                          colorColStr = colorColStr,
                          yLabStr = yLabStr,
                          xLabStr = xLabStr,
                          rmFacuetBool = rmFacuetBool, 
                          scaleBool = scaleBool, 
                          statBeforeBool = statBeforeBool);
            graph = graph + theme(legend.title = element_blank());
            saveGraph(paste(nameStr, "-", covAryStr[intLen], sep = ""));
        } else
        { # else making multiple graphs
            tmpData = data[data[[levColStr]] == levAryStr[intLen],];

            for(intY in 1:length(yColStr))
            { # loop though all y columns to make graphs with
                print(paste(nameStr[intY], levAryStr[intLen]));

                if(length(yInterceptInt) > 1)
                { # if user wanted multiple y intercepts
                    graph = pointGraph(tmpData,
                                      yColStr = yColStr[intY],
                                      xColStr = xColStr,
                                      gridColStr = gridColStr,
                                      colorColStr = colorColStr,
                                      yLabStr = yLabStr[intY],
                                      xLabStr = xLabStr,
                                      yInterceptInt = yInterceptInt[intY],
                                      rmFacuetBool = rmFacuetBool, 
                                      scaleBool = scaleBool, 
                                      statBeforeBool = statBeforeBool);
                } # if user wanted multiple y intercepts

                graph = graph + theme(legend.title = element_blank());
                saveGraph(paste(nameStr[intY], 
                                "-", 
                                covAryStr[intLen], 
                                sep = ""));
            } # loop though all y columns to make graphs with
        } # else making multiple graphs
    } # loop and make plasmid graphs for all coverages
} # makeGraphLev

# Name: makeViolinGraphLev
# Use: Loops though an input column in a data frame and calls pointGraph for each
#      level in the column
# Input:
#     data: data frame with data to graph
#     yColStr: String with the column for the y-axis 
#         Note: Can be input as an array, but nameStr must be an array of at
#               least equal length
#     xColStr: string with the column for the x-axis
#     gridColStr: Sting with the column to use as columns for the faucet graph
#     levColStr: String with the column to make graphs for
#     NameStr: string with the prefix to name the graph
#         Note: If yColStr is an array this must be an array of equal length
#     yLabStr: String with the y-label to use for the y-axis
#         Default: Nothing
#     xLabStr: String with the x-axis label 
#         Default: NA (do not apply one, but use ggplots default)
#     colorColStr: String with the column to use for the color column
#         Default: Organism
#     shapeColStr: String with the column to use for the shapes
#         Default: Polisher
#     yInterceptInt: Integer array with the intercepts of horizontal lines for
#                    each graph. 
#         Note: Size must be equal to yColStr or equal to 1 (ignored if 1)
#         Default: No line
#     widthInt: Integer with width of graph in pixals? 
#         Defualt: 700
#     heightInt: Integer with the height of the graph in pixels?
#         Defualt: 600
#     rmFaucetXLabBool: integer with 1 or 0 to remove the faucet x labels from
#                       the graph.
#         Default: 0 (keep the labels)
#     scaleBool: Integer with 1 or 0. Decides if should scale graph at 0 or not
#         Default: 1 (scale graph). 0 means use ggplots default
#     statBeforeBool: integer with 1 or 0. If 1 plot the stat before adding 
#                     points
#         Default: 0
# Output:
#     png: with graph for each level in the levColStr
# Requires: pointGraph
################################################################################
makeViolinGraphLev = function (data, yColStr, xColStr, gridColStr, levColStr, 
                         nameStr, yLabStr = "", xLabStr = NA, 
                         colorColStr = "Organism", shapeColStr = "Polisher", 
                         yInterceptInt = NA, widthInt = 700, heightInt = 600, 
                         rmFacuetBool = 0, scaleBool = 1, statBeforeBool = 0)
{ # makeGraphLev
    tmpData = NA;
    levAryStr = sort(unique(data[[levColStr]]));
        # using data[[leveColStr]] to grab just the column of intrest

    if(length(yColStr) < length(nameStr))
    {stop("for makeGraphLev the number of y columns must match number of names");}

    if(length(yColStr) < length(yLabStr))
    {stop("The number of y columns must match number of labels");}


    if(length(yInterceptInt) > 1 && length(yInterceptInt) < length(yColStr))
    {stop("number of intercepts must be 1 or equal the number of y columns");}

    for(intLen in 1:length(levAryStr))
    { # loop and make plasmid graphs for all coverages

        if(length(yColStr) < 2)
        { # if just making one graph
            print(paste(nameStr, levAryStr[intLen]));
            graph = boxplotGraph(data[data[[levColStr]] == levAryStr[intLen],],
                          yColStr = yColStr,
                          xColStr = xColStr,
                          gridColStr = gridColStr,
                          colorColStr = colorColStr,
                          yLabStr = yLabStr,
                          xLabStr = xLabStr,
                          rmFacuetBool = rmFacuetBool, 
                          scaleBool = scaleBool, 
                          statBeforeBool = statBeforeBool);
            graph = graph + theme(legend.title = element_blank());
            saveGraph(paste(nameStr, "-", covAryStr[intLen], sep = ""));
        } else
        { # else making multiple graphs
            tmpData = data[data[[levColStr]] == levAryStr[intLen],];

            for(intY in 1:length(yColStr))
            { # loop though all y columns to make graphs with
                print(paste(nameStr[intY], levAryStr[intLen]));

                if(length(yInterceptInt) > 1)
                { # if user wanted multiple y intercepts
                    graph = boxplotGraph(tmpData,
                                      yColStr = yColStr[intY],
                                      xColStr = xColStr,
                                      gridColStr = gridColStr,
                                      colorColStr = colorColStr,
                                      yLabStr = yLabStr[intY],
                                      xLabStr = xLabStr,
                                      yInterceptInt = yInterceptInt[intY],
                                      rmFacuetBool = rmFacuetBool, 
                                      scaleBool = scaleBool, 
                                      statBeforeBool = statBeforeBool);
                } # if user wanted multiple y intercepts

                graph = graph + theme(legend.title = element_blank());
                saveGraph(paste(nameStr[intY], 
                                "-", 
                                covAryStr[intLen], 
                                sep = ""));
            } # loop though all y columns to make graphs with
        } # else making multiple graphs
    } # loop and make plasmid graphs for all coverages
} # makeGraphLev


################################################################################
# Name: percAxis
# Use: Adds a second y-axis with percent to a graph with q-scores
# Input: 
#     graph: ggplot graph object to add the second y-axis to
#     yLabStr: string with the first y-axis label (original is over written)
# Output:
#    ggplot graph
################################################################################
percAxis = function(graph, yLabStr = "") 
{ # percAxis function

    graph = graph + 
            scale_y_continuous(name = yLabStr, 
                               sec.axis = sec_axis(trans=~./10,
                                                   name = "Percent accuracy",
                                                   labels = (function(x) 
                                                   x = (1-1/10^(x)) * 100)));
    return(graph);
} # percAxis function


################################################################################
# Name: pointGraph
# Use: Makes a gpplot graph with my settings
# Input:
#     data: data frame with data to graph
#     yColStr: String with the column for the y-axis
#     xColStr: string with the column for the x-axis
#     gridColStr: Sting with the column to use as columns for the faucet graph
#         Default: NA (do not make a faucet graph)
#     yLabStr: String with the y-label to use for the y-axis
#         Default: Nothing
#     xLabStr: String with the x-axis label 
#         Default: NA (do not apply one, but use ggplots default)
#     colorColStr: String with the column to use for the color column
#         Default: Organism
#     shapeColStr: String with the column to use for the shapes
#         Default: Polisher
#     yInterceptInt: Integer with the intercept of a horizontal
#         Default: No line
#     rmFaucetXLabBool: integer with 1 or 0 to remove the faucet x labels from
#                       the graph.
#         Default: 0 (keep the labels)
#     scaleBool: Integer with 1 or 0. Decides if should scale graph at 0 or not
#         Default: 1 (scale graph). 0 means use ggplots default
#     statBeforeBool: integer with 1 or 0. If 1 plot the stat before adding 
#                     points
#         Default: 0
#     plotStatBool: Integer with 1 or 0. If one plot the median, else do not
#         Default: 1 (plot the median)
#     italicsBool: integer with 1 or 0. If 1 puts the legend in italics
#         Default: 0
#     jitXDbl: Double with the x-axis value to jitter by
#         Default: 0.25 (set up for non categorical x-axis)
#     jitYDbl: Double with the y-axis value to jitter by
#         Default: 0 
#     widthDbl: Double, how long to draw the stat corss bar 
#         Default 1
# Output: ggplot graph
# Library Requires: ggplot2, ggstatsplot, ggpubr
################################################################################
pointGraph = function(data, yColStr, xColStr, gridColStr = NA, yLabStr = "", 
                     xLabStr = NA, colorColStr = "Organism", 
                     shapeColStr = NA, yInterceptInt = NA,
                     rmFacuetBool = 0, scaleBool = 1, statBeforeBool = 0,
                     plotStatBool = 1, italicsBool = 0, jitXDbl = 0.25, 
                     jitYDbl = 0, widthDbl = 1)
{ # pointGraph function
    shapeAryInt = c(21, 22, 23, 24, 25);

    if(is.na(shapeColStr) || is.null(shapeColStr))
    { # if the user did not want a shape column
        graph = ggplot(data, aes(y=!!as.symbol(yColStr), 
                                 x = !!as.symbol(xColStr), 
                                 fill = !!as.symbol(colorColStr)));
    } else 
    { # else user wanted a shape column
        graph = ggplot(data, aes(y=!!as.symbol(yColStr), 
                                 x = !!as.symbol(xColStr), 
                                 fill = !!as.symbol(colorColStr),
                                 shape = !!as.symbol(shapeColStr)));
    } # else user wanted a shape column

    if(! (is.na(yInterceptInt) || is.null(yInterceptInt)))
    {graph = graph + geom_hline(aes(yintercept = yInterceptInt));}

    if(statBeforeBool == 1 && plotStatBool == 1)
    { # if plotting the stat values before the points
        if(is.na(shapeColStr) || is.null(shapeColStr))
        {graph = plotMedian(graph, widthDbl = widthDbl);} 
        else # else user wanted to colorize each median
        {graph = plotMedian(graph, shapeColStr, showLegend = TRUE, widthDbl = widthDbl);}
    } # if plotting the stat values before the points

    if(is.na(shapeColStr) || is.null(shapeColStr))
    { # if need to add a shape in
        graph = graph + 
                geom_point(cex = 4, 
                           # col = "BLACK",
                           shape = 21,
                           position = position_jitter(width = jitXDbl, 
                                                      height = jitYDbl),
                           alpha = 0.5);
    } else
    { # else no need for a shpae
        geom_point(cex = 4, 
                   # col = "BLACK",
                   position = position_jitter(width = jitXDbl, height=jitYDbl),
                   alpha = 0.5);
    } # else no need for a shape

    if(statBeforeBool == 0 && plotStatBool == 1)
    { # if plotting the stat values before the points
        if(is.na(shapeColStr) || is.null(shapeColStr))
        {graph = plotMedian(graph, widthDbl = widthDbl);} 
        else # else user wanted to colorize each median
        {graph = plotMedian(graph, shapeColStr, showLegend = TRUE, widthDbl = widthDbl);}
    } # if plotting the stat values before the points

    graph = graph +    
         scale_fill_brewer(type = "qual", palette = "Set2") +
         scale_color_brewer(type = "qual", palette = "Set2") +
#            scale_color_manual(friendly_pal(name = "muted_nine")) +
#            scale_fill_manual(friendly_pal(name = "muted_nine")) +
#            scale_color_viridis(discrete = TRUE,
#                                option = "D",
#                                direction = -1) +
#            scale_fill_viridis(discrete = TRUE,
#                                option = "D",
#                               direction = -1) +
            scale_shape_manual(values = shapeAryInt) + 
            ylab(yLabStr);

    # check if need to add faucets
    if(!(is.na(gridColStr) || is.null(gridColStr)))
    { # if the user wanted a faucet graph
        graph = graph + facet_grid(cols = vars(!!as.symbol(gridColStr)));

        if(rmFacuetBool > 0) # if user wanted to remove the faucet labels
        {graph = graph + theme(strip.text.x = element_blank());}
    } # if the user wanted a faucet graph

    # add x-axis label if user wanted one
    if(!(is.na(xLabStr) || is.null(xLabStr)))
    {graph = graph + xlab(xLabStr);}

    if(scaleBool > 0){graph = graph + expand_limits(y = 0);}

    graph = applyTheme(graph, 18); # apply my theme to the graph

    if(italicsBool == 1)
    {graph = graph + theme(legend.text = element_text(face = "italic"));}

    return(graph);
} # pointGraph function

################################################################################
# Name: boxplotGraph
# Use: Makes a gpplot graph with my settings
# Input:
#     data: data frame with data to graph
#     yColStr: String with the column for the y-axis
#     xColStr: string with the column for the x-axis
#     gridColStr: Sting with the column to use as columns for the faucet graph
#         Default: NA (do not make a faucet graph)
#     yLabStr: String with the y-label to use for the y-axis
#         Default: Nothing
#     xLabStr: String with the x-axis label 
#         Default: NA (do not apply one, but use ggplots default)
#     colorColStr: String with the column to use for the color column
#         Default: Organism
#     shapeColStr: String with the column to use for the shapes
#         Default: Polisher
#     yInterceptInt: Integer with the intercept of a horizontal
#         Default: No line
#     rmFaucetXLabBool: integer with 1 or 0 to remove the faucet x labels from
#                       the graph.
#         Default: 0 (keep the labels)
#     scaleBool: Integer with 1 or 0. Decides if should scale graph at 0 or not
#         Default: 1 (scale graph). 0 means use ggplots default
#     statBeforeBool: integer with 1 or 0. If 1 plot the stat before adding 
#                     points
#         Default: 0
#     plotStatBool: Integer with 1 or 0. If one plot the median, else do not
#         Default: 1 (plot the median)
#     italicsBool: integer with 1 or 0. If 1 puts the legend in italics
#         Default: 0
#     jitXDbl: Double with the x-axis value to jitter by
#         Default: 0.25 (set up for non categorical x-axis)
#     jitYDbl: Double with the y-axis value to jitter by
#         Default: 0 
# Output: ggplot graph
# Library Requires: ggplot2, ggstatsplot, ggpubr, viridis (color pallete)
################################################################################
boxplotGraph = function(data, yColStr, xColStr, gridColStr = NA, yLabStr = "", 
                     xLabStr = NA, colorColStr = "Organism", 
                     shapeColStr = NA, yInterceptInt = NA,
                     rmFacuetBool = 0, scaleBool = 1, statBeforeBool = 1,
                     plotStatBool = 1, italicsBool = 0, jitXDbl = 0.25, 
                     jitYDbl = 0)
{ # pointGraph function
    shapeAryInt = c(21, 22, 23, 24, 25);

    if(is.na(shapeColStr) || is.null(shapeColStr))
    { # if the user did not want a shape column
        graph = ggplot(data, aes(y=!!as.symbol(yColStr), 
                                 x = !!as.symbol(xColStr), 
                                 fill = !!as.symbol(colorColStr)));
    } else 
    { # else user wanted a shape column
        graph = ggplot(data, aes(y=!!as.symbol(yColStr), 
                                 x = !!as.symbol(xColStr), 
                                 fill = !!as.symbol(colorColStr),
                                 shape = !!as.symbol(shapeColStr)));
    } # else user wanted a shape column

    if(! (is.na(yInterceptInt) || is.null(yInterceptInt)))
    {graph = graph + geom_hline(aes(yintercept = yInterceptInt));}

    graph = graph +
            geom_boxplot(aes(x = !!as.symbol(xColStr)), position = position_dodge(1));

    graph = graph +    
#            scale_color_manual(friendly_pal(name = "muted_nine")) +
#            scale_fill_manual(friendly_pal(name = "muted_nine")) +
            scale_color_viridis(discrete = TRUE,
                                alpha = 0.5,
                                option = "D",
                                direction = -1) +
            scale_fill_viridis(discrete = TRUE,
                               alpha = 0.5,
                                option = "D",
                               direction = -1) +
            scale_shape_manual(values = shapeAryInt) + 
            ylab(yLabStr);

    # check if need to add faucets
    if(!(is.na(gridColStr) || is.null(gridColStr)))
    { # if the user wanted a faucet graph
        graph = graph + facet_grid(cols = vars(!!as.symbol(gridColStr)));

        if(rmFacuetBool > 0) # if user wanted to remove the faucet labels
        {graph = graph + theme(strip.text.x = element_blank());}
    } # if the user wanted a faucet graph

    # add x-axis label if user wanted one
    if(!(is.na(xLabStr) || is.null(xLabStr)))
    {graph = graph + xlab(xLabStr);}

    if(scaleBool > 0){graph = graph + expand_limits(y = 0);}

    graph = applyTheme(graph); # apply my theme to the graph

    if(italicsBool == 1)
    {graph = graph + theme(legend.text = element_text(face = "italic"));}

    return(graph);
} # pointGraph function


################################################################################
# Name: plotMedian
# Use: plots the median of each faucet using ggplotstats, stat_summary. The 
#      L
# Input:
#     graph: ggplot graph object to plot the median on
#         Required
#     data: Dataframe with data to graph and get median for, the x-axis column
#           name is in the graph
#     yColStr: Y axis column to get median for (string)
#     catAryStr: Catagories to get medians for (string array or string)
#     colorStr: String or color value with the color to apply to the median 
#         Default: BLACK
#     alphaDbl: Double from 0-1 with the alpha to color
#         Default: 1
#     widthDbl: Double holding the width of the bar markding the medain
#         Default: 1
#     sizeDbl: Height of crossbar (double)
#         Default: 0.5 (geom_crossbar default)
#     showLegend: Boolean to apply the median values to the legend
#         Default: FALSE
# Output: ggplot graph object with the median plotted
# Requires: ggplot2, and ggstatsplot
################################################################################
plotMedian = function(graph, 
                      data,
                      yColStr,
                      catAryStr,
                      colorStr = "BLACK",
                      alphaDbl = 1,
                      widthDbl = 1,
                      sizeDbl = 0.5,
                      showLegend=FALSE)
{ # plot median function

    # Get the medians for all points
    tmpData = getDataMed(data = data,
                         medColStr = yColStr,
                         catAryStr = catAryStr
    ); # get the medians

    # rename median column to y-axis (so ggplot does not complain)
    colnames(tmpData)[which(names(tmpData) == "medCol")] = yColStr;
    graph = graph + 
            geom_crossbar(data = tmpData,
                          aes_string(ymin = (yColStr), ymax = (yColStr)),
                          col = colorStr,
                          alpha = alphaDbl,
                          size = sizeDbl,
                          width = widthDbl, # x-axis size of cross bar
                          show.legend = showLegend # change legend?
    ); # Add the medians as crossbars

    return(graph);
} # plot median function

################################################################################
# Name: saveGraph
# Use: Wrapper for ggsave. So I can change graph saving settings quickly.
# Input:
#    nameStr: String with the graph name
#        Required
# Output: nameStr.tiff (tiff with the plotted graph).
# Requires: ggplot2 and a ggplot graph object in the buffer
################################################################################
saveGraph = function(nameStr)
{ # saveGraph function
    ggsave(paste(nameStr, ".svg", sep = ""), device = "svg", dpi = 300);
} # saveGraph function

