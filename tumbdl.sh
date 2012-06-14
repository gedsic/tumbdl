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
# Requirements: nothing fancy. Just bash (v.4), wget, grep, egrep, coreutils
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
userAgent='--user-agent="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:10.0.1) Gecko/20100101 Firefox/10.0.1"'
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

# set nextPageDir to get the first archive page 
cookieFile=$(tempfile)
nextPageDir="/archive/"
quit=0

# iterate over archive pages, collect article urls and download images
while [[ $quit -ne 1 ]]; do
   indexName=$(tempfile)
   echo "tumbdl: $nextPageDir"
   wget "$url$nextPageDir" -O "$indexName" --load-cookies "$cookieFile" "$wgetOptions" "$userAgent"
   while read -r; do
      article=("$REPLY")
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
         # get article page
         artfile=$(tempfile)
         wget "$article" -O "$artfile" --referer="$nextPageDir" --load-cookies "$cookieFile" "$wgetOptions" "$userAgent"
      
         # add article URL to list of downloaded articles
         echo "$article" >> "$articleList"

         # get image links
         while read -r; do
            imageLinks+=("$REPLY")
         done < <(egrep -o "http://[^ ]*tumblr_[^ ]*.(jpg|jpeg|gif|png)" "$artfile")

         # loop over different image filenames (without resolution part)
         # this is in case we have an image set on the article page
         # this loop is executed once if the article contains a single image
         while read -r; do

            # determine maximum available resolution of image:
            # cuts out the resolution parts of the filename, sorts them and
            # picks out the largest one
            maxRes=$(echo "${imageLinks[@]}" | sed 's/ /\n/g' | egrep -o "$REPLY\_[0-9]+" | sed "s/$REPLY\_//g" | sort -nr | head -n 1)

            # get image url with the max resolution from link list 
            image=$(echo "${imageLinks[@]}" | sed 's/ /\n/g' | egrep -o "http://[^ ]*$REPLY\_$maxRes.(jpg|jpeg|gif|png)" | head -n 1)

            # download image (if it doesn't exist)
            echo "tumbdl: Getting image (if it doesn't exist)..."
            wget "$image" -P "$targetdir" --referer="$artfile" --load-cookies "$cookieFile" --no-clobber "$wgetOptions" "$userAgent"

         done < <(echo ${imageLinks[@]} | egrep -o "http://[^ ]*tumblr_[^ ]*.(jpg|jpeg|gif|png)" | sed 's/_[0-9]*\.[a-zA-Z]*//g' | sed 's/http:\/\/.*\///g' | uniq)
         imageLinks=()
      else
         echo "tumbdl: Article has been downloaded previously, quitting..."
         quit=0
      fi
   done < <(grep -o 'http://[^ ]*/post/[^" ]*' "$indexName")
   if [[ $quit -eq 0 ]]; then
      # get link to next archive page
      nextPageDir=$(grep -o '/archive/?before\_time=[0-9]*' "$indexName")

      # if no next archive page exists, quit
      if [[ -z $nextPageDir ]]; then
         quit=1;
      fi
   fi
done


################################################################################
#
#   Copyright 2012 gedsic@karog.de
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

