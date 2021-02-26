#!/bin/bash

MIN_MOODLE_VERSION=31  # only work on MOODLE_XX_STABLE that is on or higher than MIN_MOODLE_VERSION

# Fetch/Refresh moodle repo
if [ -d moodle ]; then
    cd moodle
    git fetch --prune --all
    cd -
else
    if [ -e moodle ]; then
        echo "A file with the name `moodle` exists, "
        rm -i moodle
        if [ -e moodle ]; then
            exit 0
        fi
    fi
    git clone git://github.com/moodle/moodle.git moodle
fi

# Get a list of STABLE branch-names.
cd moodle
MOODLE_STABLE_BRANCHES=($(git branch -r |grep -E 'origin.*STABLE'))
cd -

# Fetch/Refresh moodle-internallogin repo
if [ -d moodle-internallogin ]; then
    cd moodle-internallogin
    git fetch --all --prune
    cd -
else
    if [ -e moodle-internallogin ]; then
        echo "A file with the name 'moodle-internallogin' exists, "
        rm -i moodle-internallogin
        if [ -e moodle-internallogin ]; then
            exit 0
        fi
    fi
    git clone https://github.com/ucsf-ckm/moodle-internallogin.git
fi


cd moodle-internallogin

# Make sure repo is not dirty
if [ "$(git status -s)" != "" ]; then
    echo "git status is dirty!"
    git status
    echo
    exit 1
fi

INTERNALLOGIN_BRANCH=($(git branch -r |grep -E 'origin.*STABLE'))
PUSH_PENDING_BRANCHES=()

for B in ${MOODLE_STABLE_BRANCHES[@]##*/}; do
    VER=${B#*_}; VER=${VER%_*}
    MAJORVER=${VER%?}
    MINORVER=${VER: -1:1}
    BASE_VER_TAG=v${MAJORVER}.${MINORVER}
    ZERO_VER_TAG=${BASE_VER_TAG}.0

    if (( $VER < $MIN_MOODLE_VERSION )); then
        echo "Skipping $B..."
        continue
    else
        echo "Working on $B..."
    fi

    if [ $(git branch -r |grep ${B}) ]; then
        git checkout ${B}
    else
        # Check out x.x.0 tag from Moodle repo
        cd ../moodle
        git checkout $ZERO_VER_TAG

        # Create a new stable branch in moodle-internallogin repo
        cd ../moodle-internallogin
        git checkout master

        # Remove all php and html files and test folder
        for f in *.{php,html}; do
            if [ "${f%.*}" != "*" ]; then
                rm $f
            fi
        done

        if [ -d tests ]; then rm -Rf tests; fi

        # Copy the login folder from the moodle repo
        cp -Rp ../moodle/login/* .

        # Check in files to master branch
        git add .
        git commit -am"Initial original copy of login directory from Moodle ${ZERO_VER_TAG}."

        # git push origin master
        PUSH_PENDING_BRANCHES+=(master)

        git checkout -b ${B}
        # git push origin $branch
        PUSH_PENDING_BRANCHES+=(${B})

        # git branch -u origin/$branch

        # apply internallogin changes
        ../modify-code.sh --commit
    fi

    # BUG: Always started from x.x.0.  Should check log to see if we had already made those changes in that version first.
    # Go through each tags for MOODLE STABLE branch and create new commit if not in log
    cd ../moodle
    TAGS=($(git tag -l ${BASE_VER_TAG}.? |sort; git tag -l ${BASE_VER_TAG}.?? |sort))

    for T in ${TAGS[@]}; do
        cd ../moodle
        git checkout ${T}

        cd ../moodle-internallogin/

        upgradebranch=Moodle-${T}
        lastoriginalcommit=$(git log -n1 --format=%h --grep 'original copy of login directory')
        if [ "${lastoriginalcommit}" == "" ]; then
            echo "Cannot find last commit for original source of the login directory."
            break
        fi

        # If tag is already integrated, skip
        #test
        # for i in {27..34}; do
        # B="MOODLE_${i}_STABLE"
        # git checkout $B
        # lastoriginalcommit=$(git log -n1 --format=%h --grep 'original copy of login directory')
        # VER=${B#*_}; VER=${VER%_*}
        # MAJORVER=${VER%?}
        # MINORVER=${VER: -1:1}
        # BASE_VER_TAG=v${MAJORVER}.${MINORVER}
        REV=$(git show -s --format=%s ${lastoriginalcommit}); REV=${REV##*${BASE_VER_TAG}.}; REV=${REV%%.*}; REV=${REV%%\'*}
        # echo "Extracted rev = $REV for $B"
        # done |grep 'Extracted'

        if (( ${T##*.} > ${REV} )); then

            git checkout -b ${upgradebranch} ${lastoriginalcommit}

            # Remove all php and html files and test folder
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
                git checkout ${B}
                echo "No new change in ${T}.  No new commit."
                git branch -D ${upgradebranch}
                continue
            fi

            git commit -am"Initial original copy of login directory from Moodle ${T}."

            # Start modifying the code for internal login
            ../modify-code.sh --commit

            # Merge to branch
            git checkout ${B}
            git pull
            git merge -s recursive -X theirs --no-edit ${upgradebranch}
            PUSH_PENDING_BRANCHES+=(${B})

            git branch -D ${upgradebranch}
        else
            echo "Skipping ${T} because REV is ${REV}."
        fi

    done

done

PUSH_PENDING_BRANCHES=($(echo ${PUSH_PENDING_BRANCHES[@]}|tr ' ' '\n'|sort -fu))

echo "Run these git push commands in 'moodle-internallogin' directory when ready."
for B in ${PUSH_PENDING_BRANCHES[@]}; do
    echo "git push -u origin ${B}"
done

cd -
