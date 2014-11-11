#!/bin/bash
set -e

# Check parameters
if [ $# > 1 ]; then
	echo "Too many parameters."
	echo "Usage: $0 [--help] [--commit]"
fi

if [ "$0" == "--help"]; then
	echo "Usage: $0 [--help] [--commit]"
fi

# Make sure we are in moodle-internallogin directory
if [ $(basename `pwd`) != moodle-internallogin ]; then
    echo "WARNING: Make sure you're in the right directory (i.e. moodle-internallogin) since this script will remove files."
    exit 0
fi

rm *.html *.php
cp -Rp ../moodle/login/* .

for f in *.{php,html}; do sed -i '' 's|/login/|/internallogin/|g' $f; done
if [ "$1" == "--commit" ]; then
	git commit -am"Replaced URLs that contain '/login/' with '/internallogin/' by running: for f in *.{php,html}; do sed -i '' 's|/login/|/internallogin/|g' \$f; done"
fi

for f in *.{php,html}; do sed -i '' "s|(!empty(\$CFG->alternateloginurl))|(false /* disable alternate login */ and !empty(\$CFG->alternateloginurl))|g" $f; done
for f in *.{php,html}; do sed -i '' "s|= get_login_url();|= str_replace('/login/', '/internallogin/', get_login_url());|g" $f; done
if [ "$1" == "--commit" ]; then
	git commit -am"Stopped alternateloginurl and corrected url returned by get_login_url()."
fi

