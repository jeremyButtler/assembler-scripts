#!/bin/bash

# hardcoded script 

tenX="/data/Zymo/Voltrax_20190924/subsample/coverage.10x";
twentyX="/data/Zymo/Voltrax_20190924/subsample/coverage.20x";
thirtyX="/data/Zymo/Voltrax_20190924/subsample/coverage.30x";
fiftyX="/data/Zymo/Voltrax_20190924/subsample/coverage.50x";
hundX="/data/Zymo/Voltrax_20190924/subsample/coverage.100x";
twoHundX="/data/Zymo/Voltrax_20190924/subsample/coverage.200x";

bash scripts/runAssemblers.sh -g 42m -a raven -d 10 -p voltrax -r "$tenX";
bash scripts/runAssemblers.sh -g 42m -a raven -d 20 -p voltrax -r "$twentyX";
bash scripts/runAssemblers.sh -g 42m -a raven -d 30 -p voltrax -r "$thirtyX";
bash scripts/runAssemblers.sh -g 42m -a raven -d 50 -p voltrax -r "$fiftyX";
bash scripts/runAssemblers.sh -g 42m -a raven -d 100 -p voltrax -r "$hundX";
bash scripts/runAssemblers.sh -g 42m -a raven -d 200 -p voltrax -r "$twoHundX";

#bash scripts/runAssemblers.sh -g 42m -a redbean -d 10 -p voltrax -r "$tenX";
#bash scripts/runAssemblers.sh -g 42m -a redbean -d 20 -p voltrax -r "$twentyX";
#bash scripts/runAssemblers.sh -g 42m -a redbean -d 30 -p voltrax -r "$thirtyX";
#bash scripts/runAssemblers.sh -g 42m -a redbean -d 50 -p voltrax -r "$fiftyX";
#bash scripts/runAssemblers.sh -g 42m -a redbean -d 100 -p voltrax -r "$hundX";
#bash scripts/runAssemblers.sh -g 42m -a redbean -d 200 -p voltrax -r "$twoHundX";
#
#bash scripts/runAssemblers.sh -g 42m -a flye -d 10 -p voltrax -r "$tenX";
#bash scripts/runAssemblers.sh -g 42m -a flye -d 20 -p voltrax -r "$twentyX";
#bash scripts/runAssemblers.sh -g 42m -a flye -d 30 -p voltrax -r "$thirtyX";
#bash scripts/runAssemblers.sh -g 42m -a flye -d 50 -p voltrax -r "$fiftyX";
#bash scripts/runAssemblers.sh -g 42m -a flye -d 100 -p voltrax -r "$hundX";
#bash scripts/runAssemblers.sh -g 42m -a flye -d 200 -p voltrax -r "$twoHundX";
#
#bash scripts/runAssemblers.sh -g 42m -a canu -d 10 -p voltrax -r "$tenX";
#bash scripts/runAssemblers.sh -g 42m -a canu -d 20 -p voltrax -r "$twentyX";
#bash scripts/runAssemblers.sh -g 42m -a canu -d 30 -p voltrax -r "$thirtyX";
#bash scripts/runAssemblers.sh -g 42m -a canu -d 50 -p voltrax -r "$fiftyX";
#bash scripts/runAssemblers.sh -g 42m -a canu -d 100 -p voltrax -r "$hundX";
#bash scripts/runAssemblers.sh -g 42m -a canu -d 200 -p voltrax -r "$twoHundX";
