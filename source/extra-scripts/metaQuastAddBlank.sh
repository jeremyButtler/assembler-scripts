
fileStr="$1";

awk -v numIdInt=12 -f "$(dirname "$0")/metaCheck.awk" < "$fileStr";

