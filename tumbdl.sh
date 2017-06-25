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
# Requirements: curl, PCRE for grep -P (normally you have this)
#
# Should also work for tumblelogs that have their own domain.
#
# If you use and like this script, you are welcome to donate some bitcoins to
# my address: 1LsCBob5B9SWknoZfF6xpZWJ9GF4NuBLVD
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

url=$1
targetDir=$2

# global curl options
# to disable progress bar, replace with -s
# to enable verbose mode, add -v
curlOptions='--progress-bar'
userAgent='Mozilla/5.0 (Windows NT 6.1; WOW64; rv:47.0) Gecko/20100101 Firefox/47.0'

# check usage
if [ $# -ne 2 ]; then
  echo "Usage: tumbdl [URL] [DIR]"
  echo ""
  echo "URL: URL of tumblelog, e.g. prostbote.tumblr.com"
  echo "DIR: directory to put images in, e.g. prostbote"
  exit
fi

# sanitize input url
url=$(echo "$url" | sed 's/http[s]*:\/\///g;s/\/$//g')

# create target dir
mkdir "$targetDir"
touch "$targetDir/articles.txt"

# create cookie jar (not really needed atm)
cookieFile="$(mktemp 2>/dev/null || mktemp -t 'mytmpdir')"

# get first archive page
archiveLink="/archive/"

# loop over archive pages
endOfArchive=0
while [[ $endOfArchive -ne 1 ]]
do
  # get archive page
  archivePage=$(curl $curlOptions -c $cookieFile --referer "http://$url" -A "$userAgent" "$url$archiveLink")
  echo "Retrieving archive page $url$archiveLink..."  

  # extract links to posts
  monthPosts=$(echo "$archivePage" | grep -o -P "/post/[0-9]*.*?\"" | sed 's/"//g')
  
  # process all posts on this archive page
  for postURL in $(echo "$monthPosts")
  do
    # check if post page has already been processed before
    if grep -Fxq "$postURL" "$targetDir/articles.txt"
    then
      echo "Already got $url$postURL, skipping."
    else 
      # get the image links (can be multiple images in sets)
      echo "Retrieving post $url$postURL..."
      postPage=$(curl $curlOptions -b $cookieFile --referer "http://$url$archiveLink" -A "$userAgent" "$url$postURL")
      imageLinks=$(echo "$postPage" | grep -o -P "http[s]*://([0-9]*.)?media\.tumblr\.com/([A-Za-z0-9]*/)?tumblr_[A-Za-z0-9]*_[0-9]*\.[a-z]*" | sort | uniq)
      # remove resolution info from image filename
      baseImages=$(echo "$imageLinks" | grep -o "tumblr_.*$" | sed 's/_[0-9]*\.\w*//g' | uniq)
      # if we encounter any download errors, don't mark the post as archived
      curlError=0

      # determine the highest available resolution and download image
      if [ ! -z "$baseImages" ]
      then

        for image in $(echo "$baseImages")
        do
          # get the image name of image with highest resolution
          maxResImage=$(echo "$imageLinks" | grep -o "$image.*" | sort -n | head -n 1)
          # get full image url
          maxResImageURL=$(echo "$imageLinks" | grep "$maxResImage")
          # download image (if it doesn't exist)
          if [ -e "$targetDir/$maxResImage" ]
          then
            echo "Image exists, skipping."
          else
            echo "Downloading image $maxResImageURL..."
            curl $curlOptions -b $cookieFile --referer "http://$url$postURL" -A "$userAgent" -o "$targetDir/$maxResImage" "$maxResImageURL"
            if [ ! 0 -eq $? ]; then curlError=1; fi;
          fi
        done
      else
        # no images found, check for video links
        echo "No images found, checking for videos"
        
        # check for tumblr hosted videos
        videoPlayers=$(echo "$postPage" | grep -o -P "http[s]*://www.tumblr.com/video/.*/[0-9]*/[0-9]*/" | sort | uniq)
        for video in $(echo "$videoPlayers")
        do
          echo "Found tumblr-hosted video $video"
          # get video link and type
          videoSource=$(curl $curlOptions -b $cookieFile --referer "http://$url$postURL" -A "$userAgent" "$video" | grep -o -P "<source src=\"http[s]*://[^.]*.tumblr.com/video_file/.*?>")
          # get video url
          videoURL=$(echo "$videoSource" | grep -o -P "http[s]*://[^.]*.tumblr.com/video_file/[[:0-9A-Za-z]*/]*[0-9]*/tumblr_[A-Za-z0-9]*")
          # construct filename with extension from type string
          videoFile=$(echo "$videoSource" | grep -o -P "tumblr_.*?>" | sed -e 's/<source src=\"//g' -e 's/\" type=\"video\//./g' -e 's/\">//g' -e 's/\//\_/g')
          # download video (if it doesn't exist)
          if [ -e "$targetDir/$videoFile" ]
          then
            echo "Video exists, skipping."
          else
            echo "Downloading video $videoURL"
            curl $curlOptions -L -b $cookieFile --referer "http://$url$postURL" -A "$userAgent" -o "$targetDir/$videoFile" "$videoURL"
            if [ ! 0 -eq $? ]; then curlError=1; fi;
          fi
        done
        # check if youtube-dl is available
        if hash youtube-dl 2>/dev/null
        then
          # gather embedded video urls
          otherSource=""
          # check for instagram video
          otherSource=$(echo "$otherSource"; echo "$postPage" | grep -o -P "http[s]*://www.instagram.com/p/[A-Za-z0-9]*")
          # check fou youtube video
          otherSource=$(echo "$otherSource"; echo "$postPage" | grep -o -P "http[s]*://www.youtube.com/embed/.*?\?" | sed 's/\?//g')
          # check for vine
          otherSource=$(echo "$otherSource"; echo "$postPage" | grep -o -P "http[s]*://vine.co/v/.*?/")
          # check for vimeo
          otherSource=$(echo "$otherSource"; echo "$postPage" | grep -o -P "http[s]*://player.vimeo.com/video/[0-9]*")
          # check for dailymotion
          otherSource=$(echo "$otherSource"; echo "$postPage" | grep -o -P "http[s]*://www.dailymotion.com/embed/video/[A-Za-z0-9]*")
          # check for brightcove
          otherSource=$(echo "$otherSource"; echo "$postPage" | grep -o -P "http[s]*://players.brightcove.net/.*/index.html\?videoId=[0-9]*")
          # add expressions for other video sites here like this:
          #otherSource=$(echo "$otherSource"; echo "$postPage" | grep -o "http[s]*://www.example.com/embed/video/[A-Za-z0-9]*")
          
          # if video links were found, try youtube-dl
          if [ ! -z $otherSource ]
          then
            for otherVid in $(echo "$otherSource")
            do
              echo "Found embedded video $otherVid, attempting download via youtube-dl..."
              youtube-dl "$otherVid" -o "$targetDir/%(title)s_%(duration)s.%(ext)s" -ciw
              # if error occurs, don't mark post as archived
              if [ ! 0 -eq $? ]; then curlError=1; fi;
            done
          else
            echo "No videos found, moving on."
          fi
        else
          echo "youtube-dl not installed, not checking for externally hosted videos."
        fi
      fi
      
      # if no error occured, enter page as downloaded
      if [[ $curlError -eq 0 ]]
      then
        echo "$postURL" >> "$targetDir/articles.txt"
      else
        echo "Some error occured during downloading. No articles.txt entry created."
      fi

    fi
  done
  # get link to next archive page
  archiveLink=$(echo "$archivePage" | grep -o -P "id=\"next_page_link\" href=\".*?\"" | sed -e 's/id=\"next_page_link\" href=\"//g' -e 's/\"//g')
  # check if we are at the end of the archive (no link is returned)
  if [ -z "$archiveLink" ]
  then
    endOfArchive=1
    echo "Reached the last archive page. Done!"
  else
    echo "Next archive page: $url$archiveLink"
  fi
done

