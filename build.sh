#!/bin/bash

cd "$(dirname $0)"

# Blosxom takes mtime as the post date.
# While plugins exist to let metadata take over, they are complex, because the hook is big.
# Since we manage history with Git, it's easier to just adhere to Blosxom's convention.
find src -name '*.md' -not -path 'src/post/*' -exec touch -t 197001010000 {} +
for filename in src/post/????-??-??.md
do
	touch -d $(basename -s .md "$filename") "$filename"
done

[ vendor/mimetex.cgi -nt "$0" ] || \
	cc -DAA -DINPUTOK -DWHITE \
		vendor/mimetex/mimetex.c vendor/mimetex/gifsave.c -lm -o vendor/mimetex.cgi

vendor/blosxom.pl -password=password -all=1

# Bundle all CSS files into one.

# The infamous flash of invisible text is actually desired in this case as jsMath fonts' encoding differs from font encodings designed for general text.
ls -1 src/assets/jsMath/fonts | awk -F. '{
	print "@font-face {"
	print "  font-family: " $1 ";"
	print "  src: local(" $1 "), url(assets/jsMath/fonts/" $0 ");"
	print "  font-display: block;"
	print "}"
}' >> _site/styles.css

QUERY_STRING=114 vendor/mimetex.cgi | (awk -F ": " '
$1 == "Vertical-Align" {
	print "<img style=\"vertical-align: " $2 "px;\" src=\"data:image/gif;base64,"
}

!NF {
	
}
'
base64
)
