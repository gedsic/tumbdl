tumbdl
======

Tumblr image downloader and archiver

A simple bash script that scans the archive of a tumblelog and gets the image
files from the post pages. It keeps track of the post pages that have been
downloaded, so that existing images are not downloaded again. This makes it easy
to archive a tumblelog on your computer and update it if new images were posted.

Requirements:
-------------
bash (Version?), wget, grep, egrep (most linux distros should have these)

Usage
-----

Checkout the code:

     git clone git://github.com/gedsic/tumbdl.git

Set script as executable:

     cd tumbdl
     chmod +x tumbdl.sh

Run script on your favorite tumblelog

     ./tumbdl prostbote.tumblr.com prostbote

Detailed usage of the script:
     
     tumbdl.sh [URL] [DIR]
     
     URL: URL of tumblelog
     DIR: directory to put images in
     
Donations
---------
If you use tumbdl and like it, you are welcome to donate bitcoins to
my address: 1CbBGDshk4dTBrz3ps9xfyH8hhQWguTaCX

L)icense
-------
Licensed under the [Apache License](http://en.wikipedia.org/wiki/Apache_License) 2.0, see code for more information

Authors
-------
* [@gedsic](http://github.com/gedsic)
