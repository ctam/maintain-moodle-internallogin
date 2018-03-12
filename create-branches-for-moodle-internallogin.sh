#!/bin/bash
set -e

for ver in {1..3}; do
    version=v3.${ver}.0
    branch=MOODLE_3${ver}_STABLE

    cd moodle
    git fetch --all
    git checkout $version
    cd ../moodle-internallogin/
    git fetch --all
    if [ `git branch | grep ${branch}` ]; then
        echo "$branch already exists, skipping."
    else
        # check in the current version to master
        git checkout master
        for f in *.{php,html}; do
            if [ "${f%.*}" != "*" ]; then
                rm $f
            fi
        done
        if [ -d tests ]; then rm -Rf tests; fi
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
