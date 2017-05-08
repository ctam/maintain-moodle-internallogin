#!/bin/bash
set -e

if [ $# != 2 ]; then
    echo "Usage: $(basename $0) <branch-name> <tag>"
    echo " e.g.: $(basename $0) MOODLE_24_STABLE v2.4.9"
    echo
    exit 0
fi

branch=$1
tag=$2

# Make sure we are at the same directory as the script
curdir=$(pwd)
cd $(dirname $0)

# checkout Moodle tag
cd moodle/
git checkout ${tag}
cd ..

# checkout moodle-internallogin
upgradebranch=Moodle-${tag}
cd moodle-internallogin/

if [ "$(git status -s)" != "" ]; then
    echo "git status is dirty!"
    git status
    echo
    exit 1
fi

git checkout ${branch}
lastoriginalcommit=$(git log -n1 --format=%h --grep 'original copy of login directory')
if [ "${lastoriginalcommit}" == "" ]; then
    echo "Cannot find last commit for original source of the login directory."
    exit 1
fi
git checkout -b ${upgradebranch} ${lastoriginalcommit}
for f in *.{php,html}; do
    if [ "${f%.*}" != "*" ]; then
        rm $f
    fi
done
if [ -d tests ]; then rm -Rf tests; fi
cp -Rp ../moodle/login/* .
git add .

# Do nothing if no new change
if [ "$(git status -s)" == "" ]; then
    git checkout ${branch}
    echo "No new change in ${tag}."
    git branch -D ${upgradebranch}
    exit 0
fi

git commit -am"Initial original copy of login directory from Moodle ${tag}."

# Start modifying the code for internal login
../modify-code.sh --commit

# Merge to branch
git checkout ${branch}
git pull
git merge -s recursive -X theirs --no-edit ${upgradebranch}
git push
git branch -D ${upgradebranch}

# Go back to the original directory
cd ${curdir}
