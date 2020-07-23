# Wilde

This is the code repository for the Wilde Trials application. This repository contains all of the code necessary to make the eXist application work; it does not, however, contain the data that allows eXist to display stuff. That's located in a separate repository.

After you've followed the instructions in the other repository—meaning that the assets are packed up in a `.xar` file and uploaded into eXist using the eXist Package Manager—then you can do the following to make the eXist app work:

1. Run `bower install` to get all of the necessary dependencies
1. Compile the SASS files into CSS files: `sass --update resources/sass:resources/css`. If you're planning to work on the SASS files, then you'll probably want to set a SASS listener so that it knows to auto-update the CSS files with every change: `sass --listen resources/sass:resources/css`.

Note: the listing pages (i.e. one of these pages: `path/to/exist/wilde/(city|date|language|list|newspaper|region|source).html`) don't actually exist locally; you'll need to append `-nocache` to the filename in order to see those pages.
