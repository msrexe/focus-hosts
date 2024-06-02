#!/bin/bash

usage() {
  echo "Usage: sudo ./focus.sh --duration=30m or sudo ./focus.sh --duration=3h"
  exit 1
}

if [ "$#" -ne 1 ]; then
  usage
fi

case "$1" in
  --duration=*)
    DURATION="${1#*=}"
    ;;
  *)
    usage
    ;;
esac

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi
if [ ! -f "block-list.txt" ]; then
  echo "block-list.txt not found"
  # create an empty block-list.txt file and fill it with some default entries
  touch block-list.txt
  {
  echo "facebook.com"
  echo "instagram.com"
  echo "linkedin.com"
  echo "reddit.com"
  echo "twitter.com"
  } >> block-list.txt
  echo "block-list.txt created with default entries"
fi
if [ ! -f "/etc/hosts" ]; then
  echo "/etc/hosts not found"
  exit
fi

sed -i '' '/# Block-list start/,/# Block-list end/d' /etc/hosts

echo "# Block-list start" >> /etc/hosts
while IFS= read -r line; do
  echo "127.0.0.1 $line" >> /etc/hosts
  echo "127.0.0.1 www.$line" >> /etc/hosts
done < block-list.txt
echo "# Block-list end" >> /etc/hosts

echo "Focus session started for $DURATION."

case "$DURATION" in
  *m)
    SECONDS=$((${DURATION%m} * 60))
    ;;
  *h)
    SECONDS=$((${DURATION%h} * 3600))
    ;;
  *)
    usage
    ;;
esac

trap "sed -i '' '/# Block-list start/,/# Block-list end/d' /etc/hosts; echo '\nFocus session ended. /etc/hosts restored to original state.'; exit" SIGINT SIGTERM

sleep $SECONDS

sed -i '' '/# Block-list start/,/# Block-list end/d' /etc/hosts

echo "Focus session ended. /etc/hosts restored to original state."
