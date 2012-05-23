#!/bin/bash
#
# tumbdl.sh - a tumblr image downloader
#
# Usage: tumbdl.sh [URL] [DIR]
#
# URL: URL of tumblelog
# DIR: directory to put images in
#
# Example: ./tumbdl.sh prostbote.tumblr.com prost
#
# Requirements: nothing fancy. Just bash (Version?), wget, grep, egrep.
#
# Should also work for tumblelogs that have their own domain.
#
# If you use and like this script, you are welcome to donate some bitcoins to
# my address: 1CbBGDshk4dTBrz3ps9xfyH8hhQWguTaCX
#

articlePages=()
archivePages=()
imageLinks=()
url=$1
targetdir=$2
wgetOptions='-nv'
articleList=$(echo "$targetdir/articles.txt")

# check usage
if [ $# -ne 2 ]; then
  echo "Usage: tumbdl [URL] [DIR]"
  echo ""
  echo "URL: URL of tumblelog, e.g. prostbote.tumblr.com"
  echo "DIR: directory to put images in, e.g. prostbote"
  exit
fi

# sanitize input url
url=$(echo "$url" | sed 's/http:\/\///g')

# create target dir
mkdir "$targetdir"

# get first page
indexName=$(tempfile)
cookieFile=$(tempfile)
echo "tumbdl: Getting the first archive page..."
wget "$url/archive/" -O "$indexName" --save-cookies "$cookieFile" --keep-session-cookies $wgetOptions

# get next archive page from "Next >" link
nextPageDir=$(cat "$indexName" | grep -o '/archive/?before\_time=[0-9]*'  | sed 's/http:\/\///g')   

# collect link to article pages (post pages)
while read -r; do
     articlePages+=("$REPLY")
done < <(grep -o 'http://[^ ]*/post/[^" ]*' "$indexName")

# scan next archive pages, collect more article urls
while [[ -n $nextPageDir ]]; do
   echo "tumbdl: Getting the next archive page:"
   while read -r; do
     articlePages+=("$REPLY")
   done < <(grep -o 'http://[^ ]*/post/[^" ]*' "$indexName")
   nextPageDir=$(grep -o '/archive/?before\_time=[0-9]*' "$indexName")   
   indexName=$(tempfile)
   echo "tumbdl: $nextPageDir"
   wget "$url$nextPageDir" -O "$indexName" --load-cookies "$cookieFile" $wgetOptions
done

# retrieve article pages, get image links
for article in "${articlePages[@]}"; do
   artfile=$(tempfile)
   echo "tumbdl: Getting article page:"
   echo "$article"

   # see if we already have an article list file
   if [[ -e $articleList ]]; then
     articleIsOld=$(grep -c "$article" "$articleList")
   else
     articleIsOld=0
   fi

   # test if article file has been downloaded previously
   if [[ $articleIsOld -eq 0 ]]; then
      wget "$article" -O "$artfile" --load-cookies "$cookieFile" $wgetOptions
      
      # add article URL to list of downloaded articles
      echo "$article" >> "$articleList"

      # get image links
      while read -r; do
      imageLinks+=("$REPLY")
      done < <(egrep -o "http://[^ ]*tumblr_[^ ]*.(jpg|jpeg|gif|png)" "$artfile")

      # download images (if they don't exist)
      echo "tumbdl: Getting images (if they don't exist)..."
      for image in "${imageLinks[@]}"; do
         wget "$image" -P "$targetdir" --referer="$artfile" --load-cookies "$cookieFile" --no-clobber $wgetOptions
      done
      imageLinks=()
   else
      echo "tumbdl: Article has been downloaded previously, skipping..."
   fi
done

################################################################################
#
# Copyright 2012 gedsic@karog.de
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
################################################################################

