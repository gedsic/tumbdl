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
     
FAQ
---
### I downloaded all images from some tumblr page a week ago. Now it has new images. How do I update my downloaded files?

Simply run the script again, passing the URL of the page and the directory in which the old files are.

### I want to continue an interrupted download, but the script quits, saying that there is nothing new to download. What do?

Delete the articles.txt file in your target directory. This way, the script will scan all archive pages again. Don't worry, existing images will not be overwritten.

Donations
---------
If you use tumbdl and like it, you are welcome to donate bitcoins to
my address: 1LsCBob5B9SWknoZfF6xpZWJ9GF4NuBLVD 

License
-------
Licensed under the [Apache License](http://en.wikipedia.org/wiki/Apache_License) 2.0, see code for more information

Authors
-------
* [@gedsic](http://github.com/gedsic)
