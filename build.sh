#!/bin/bash

set -e
cd "$(dirname $0)"

[ vendor/mimetex.cgi -nt "$0" ] || \
	cc -DAA -DINPUTOK -DWHITE \
		vendor/mimetex/mimetex.c vendor/mimetex/gifsave.c -lm -o vendor/mimetex.cgi

mkdir -p _site
vendor/blosxom.pl -password=password

# Bundle all CSS files into one.
cp blosxom/style.css _site/style.css

# The infamous flash of invisible text is actually desired in this case as jsMath fonts' encoding differs from font encodings designed for general text.
for filename in src/assets/jsMath/fonts/*.ttf
do
	family="$(basename -s .ttf "$filename")"
	cat <<EOF >> _site/style.css
@font-face {
	font-family: $family;
	src: local($family), url(data:image/svg+xml;base64,$(base64 --wrap=0 "$filename"));
	font-display: block;
}
EOF
done

QUERY_STRING=114 vendor/mimetex.cgi | (awk -F ": " '
$1 == "Vertical-Align" {
	print "<img style=\"vertical-align: " $2 "px;\" src=\"data:image/gif;base64,"
}

!NF {
	
}
'
base64
)
