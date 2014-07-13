#!/bin/bash
set -e

for ver in {4..7}; do
    version=v2.${ver}.0
    branch=MOODLE_2${ver}_STABLE

    cd moodle
    git checkout $version
    cd ../moodle-internallogin/
    git checkout -b $branch
    cp -Rp ../moodle/login/* .
    git add .
    git commit -am"Initial original copy of login directory from Moodle $version."
    git push origin $branch
    git checkout master
    cd ..
done
