#!/bin/bash
set -e

# Check parameters
if [[ $# > 1 ]]; then
	echo "Too many parameters."
	echo "Usage: $0 [--help] [--commit]"
        exit 1
fi

if [ "$0" == "--help" ]; then
	echo "Usage: $0 [--help] [--commit]"
fi

# Make sure we are in moodle-internallogin directory
if [ $(basename `pwd`) != moodle-internallogin ]; then
    echo "WARNING: Make sure you're in the right directory (i.e. moodle-internallogin) since this script will remove files."
    exit 0
fi

for f in *.{php,html}; do
    if [ "${f%.*}" != "*" ]; then
        rm $f
    fi
done
if [ -d tests ]; then rm -Rf tests; fi
cp -Rp ../moodle/login/* .

for f in *.{php,html}; do
    if [ "${f%.*}" != "*" ]; then
        sed -i '' 's|/login/|/internallogin/|g' $f
    fi
done
if [ "$1" == "--commit" ]; then
    # git commit -am"Replaced URLs that contain '/login/' with '/internallogin/' by running: for f in *.{php,html}; do sed -i '' 's|/login/|/internallogin/|g' \$f; done"
    # Make shorter comment.
    git commit -am"Replaced URLs that contain '/login/' with '/internallogin/'."
fi

for f in *.{php,html}; do
    if [ "${f%.*}" != "*" ]; then
        sed -i '' "s|(!empty(\$CFG->alternateloginurl))|(false /* disable alternate login */ and !empty(\$CFG->alternateloginurl))|g" $f
    fi
done
for f in *.{php,html}; do
    if [ "${f%.*}" != "*" ]; then
        sed -i '' "s|= get_login_url();|= str_replace('/login/', '/internallogin/', get_login_url());|g" $f
    fi
done
if [ "$1" == "--commit" ]; then
	git commit -am"Stopped alternateloginurl and corrected url returned by get_login_url()."
fi
