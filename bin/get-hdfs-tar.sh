#!/usr/bin/env bash
# Gets a tarball from HDFS and untars it on the fly into the given dir.

set -eu

if [[ "#2" -ne 2 ]]; then
  echo >&2 "Usage: $0 <hdfs tar path> <target dir>"
  exit 2
fi

# Parameters
HADOOP_TAR="$1"
TARGET_DIR="$2"

mkdir -p "$TARGET_DIR"

# Necessary for transfer progress bars
hash pv 2>/dev/null || apt-get -q install --no-install-recommends pv > /dev/null

# Get the total size for the progress bar
size=$(hadoop fs -ls "$HADOOP_TAR" | awk '{ print $5 }')

# Hint: add 'z' to the tar flags if you have a gzipped tar.gz input.
echo "Grabbing data from hadoop and untaring on the fly..."
(
  cd $TARGET_DIR
  hadoop fs -cat $HADOOP_TAR | pv -s "$size" | tar xf -
)



