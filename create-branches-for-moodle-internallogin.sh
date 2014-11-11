#!/bin/bash
set -e

for ver in {4..8}; do
    version=v2.${ver}.0
    branch=MOODLE_2${ver}_STABLE

    cd moodle
    git checkout $version
    cd ../moodle-internallogin/
    if [ `git branch | grep $branch` ]; then
        echo "$branch already exists, skipping."
    else
        # check in the current version to master
        git checkout master
        cp -Rp ../moodle/login/* .
        git add .
        git commit -am"Initial original copy of login directory from Moodle $version."
        git push origin master

        git checkout -b $branch
        git push origin $branch
        git branch -u origin/$branch

        # apply internallogin changes
        ../modify-code.sh --commit
    fi
    cd ..
done
