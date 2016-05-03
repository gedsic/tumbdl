#!/bin/bash
#
# tumbdl.sh - a tumblr image (and video) downloader
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
# my address: 1LsCBob5B9SWknoZfF6xpZWJ9GF4NuBLVD
#

articlePages=()
archivePages=()
imageLinks=()
videoLinks=()
url=$1
targetdir=$2
wgetOptions='-nv'
userAgent='--user-agent="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1"'
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
url=$(echo "$url" | sed 's/https\?:\/\///g')

# create target dir
mkdir "$targetdir"

# set nextPageDir to get the first archive page 
cookieFile="$(mktemp 2>/dev/null || mktemp -t 'mytmpdir')"
nextPageDir="/archive/"
firstArchivePage=1
quit=0

# iterate over archive pages, collect article urls and download images
while [[ $quit -ne 1 ]]; do
   indexName="$(mktemp 2>/dev/null || mktemp -t 'mytmpdir')"
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
         artfile="$(mktemp 2>/dev/null || mktemp -t 'mytmpdir')"
         wget "$article" -O "$artfile" --referer="$nextPageDir" --load-cookies "$cookieFile" "$wgetOptions" "$userAgent"
      
         # add article URL to list of downloaded articles
         echo "$article" >> "$articleList"

         # get image links
         while read -r; do
            imageLinks+=("$REPLY")
         done < <(egrep -o "https://[^ ]*tumblr_[^ ]*.(jpg|jpeg|gif|png)" "$artfile")

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

         done < <(echo ${imageLinks[@]} | egrep -o "https://[^ ]*tumblr_[^ ]*.(jpg|jpeg|gif|png)" | sed 's/_[0-9]*\.[a-zA-Z]*//g' | sed 's/https\?:\/\/.*\///g' | uniq)
         imageLinks=()

         # get video link
	 echo "Looking for video link"
         while read -r; do
            echo "***** VIDEOLINK ***** $REPLY"
            videoLinks+=("$REPLY")
         done < <(egrep -o "https://www.tumblr.com/video/.*/[0-9]*/[0-9]*/" "$artfile")

         while read -r; do
            # download video player page to determine video url
            pfileName="$(mktemp 2>/dev/null || mktemp -t 'mytmpdir')"
            wget "${videoLinks[@]}" -O "$pfileName" --load-cookies "$cookieFile" "$wgetOptions" "$userAgent"
            video=$(cat "$pfileName" | grep -o "https://www.tumblr.com/video_file/[0-9]*/tumblr_[A-Za-z0-9]*")
            videoName=$(cat "$artfile" | grep -o "<meta name=\"description\" content=\".*\" />" | grep -o "content=\".*\"" | sed -e 's/content=\"//g' -e 's/"//g')

            # check if video name is empty (happens from time to time)
            # use tumblr filename instead
            if [ -z "$videoName" ]; then
                videoName=$(echo "${video##*/}")
            fi
            # download video (if it doesn't exist)
            echo "tumbdl: Getting video (if it doesn't exist)..."
            echo "tumbdl: Video file name: $videoName"
            wget "$video" -O "$targetdir/$videoName" --referer="$artfile" --load-cookies "$cookieFile" --no-clobber "$wgetOptions" "$userAgent"
         done < <(echo ${videolinks[@]})
         videoLinks=()


      else
         echo "tumbdl: Article has been downloaded previously, quitting..."
         quit=0
      fi
   done < <(grep -o 'http://[^ ]*/post/[^" ]*' "$indexName")
   if [[ $quit -eq 0 ]]; then
      # get link to next archive page
      
      numberOfLines=$(grep -o '/archive/?before\_time=[0-9]*' "$indexName" | wc -l);
      if [[ $numberOfLines -gt 1 || firstArchivePage -eq 1 ]]; then
         nextPageDir=$(grep -o '/archive/?before\_time=[0-9]*' "$indexName" | head -n 1);
         firstArchivePage=0;
      else
         quit=1;
      fi 

      # if no next archive page exists, quit
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

