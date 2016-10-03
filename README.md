tumbdl
======

Tumblr image downloader and archiver

A simple bash script that scans the archive of a tumblelog and gets the image or video files from the post pages. It keeps track of the post pages that have been downloaded, so that existing images are not downloaded again. This makes it easy to archive a tumblelog on your computer and update it if new images were posted.

Requirements:
-------------
bash (version?), curl, PCRE for grep -P (normally you have this), youtube-dl (see https://rg3.github.io/youtube-dl/) for externally hosted videos

Usage
-----

Checkout the code:

     git clone git://github.com/gedsic/tumbdl.git

Set script as executable:

     cd tumbdl
     chmod +x tumbdl.sh

Run script on your favorite tumblelog

     ./tumbdl.sh prostbote.tumblr.com prostbote

Detailed usage of the script:
     
     tumbdl.sh [URL] [DIR]
     
     URL: URL of tumblelog
     DIR: directory to put images in
     
FAQ
---
### I downloaded all images from some tumblr page a week ago. Now it has new images. How do I update my downloaded files?

Simply run the script again, passing the URL of the page and the directory in which the old files are.

### I want to continue an interrupted download, but the script quits, saying that there is nothing new to download. What do?

Delete the articles.txt file in your target directory. This way, the script will scan all archive pages again. Don't worry, existing images will not be overwritten.

### The script doesn't download some of the videos

If the video is hosted on tumblr, the URL scheme for videos probably changed. Support for externally hosted videos is unreliable at the moment. I tried to support vine, vimeo, instagram, youtube and dailymotion. If you miss something or notice that something does not work, please file a bug report. Or better yet - investigate and fix the problem and submit a pull request!

### The script doesn't download some of the images

I don't run tumbdl on a regular basis, so I don't immediately notice if something in tumblr URL schemes changes. As with video problems, please file a bug report or work it out and submit a pull request. Thanks!

Donations
---------
If you use tumbdl and like it, you are welcome to donate bitcoins to my address: 1LsCBob5B9SWknoZfF6xpZWJ9GF4NuBLVD 

License
-------
Licensed under [GPLv3](http://www.gnu.org/licenses/), see code for more information

Contributors
-------
* [@gedsic](https://github.com/gedsic)
* [@shekkbuilder](https://github.com/shekkbuilder)
* [@Timosha](https://github.com/Timosha)
* [@Gantron1](https://github.com/Gantron1)
* [@andre3k1](https://github.com/andre3k1)
