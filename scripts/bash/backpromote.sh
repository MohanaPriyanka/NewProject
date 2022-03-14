#!/bin/sh
MASTER_BRANCH="main"
UAT_BRANCH="feature-uat"

# Check current working branch, ensure it is not the master branch
# If not in the correct (feature) branch, prompts user to enter feature branch name
getWorkingBranch() {
    currentBranch=$(git rev-parse --abbrev-ref HEAD)
    if [ $currentBranch = $MASTER_BRANCH ] || [ $currentBranch = $UAT_BRANCH ]
    then
        echo "$(tput setaf 2)Please checkout your working branch before attempting to use this tool" > /dev/tty
        echo "$(tput setaf 1)Enter the name of the branch you would like to checkout and merge origin/$MASTER_BRANCH into" > /dev/tty
        tput sgr0 > /dev/tty
        # shellcheck disable=SC2039
        read -p "   : " currentBranch
        set -e
        git checkout $currentBranch || echo "$(tput setaf 1)Invalid branch" && getWorkingBranch
        set +e
    fi
    CURRENT_BRANCH=$currentBranch
}

# Confirm user wants to perform git actions
confirm() {
    echo "$(tput setaf 2) This script will attempt to automatically merge (backpromote) remote commits into local from:
        origin/$MASTER_BRANCH >>> $CURRENT_BRANCH"
    echo "$(tput setaf 1) Continue? Y/N"
    tput sgr0
    # shellcheck disable=SC2039
    read -p "   : " CONTINUE
    CONTINUE=${CONTINUE:-"y"}
}

backpromote() {
    if [ $CONTINUE = "Y" ] || [ $CONTINUE = "y" ] || [ $CONTINUE = "Yes" ] || [ $CONTINUE = "yes" ]
    then
        git checkout $MASTER_BRANCH > /dev/tty
        git pull
        git checkout $CURRENT_BRANCH > /dev/tty
        temporarilyIgnoreMergingTestsFile
        git merge --no-edit $MASTER_BRANCH > /dev/tty
        rollbackGitConfig
    else
        echo "Aborting..."
    fi
}

temporarilyIgnoreMergingTestsFile() {
    echo tests.txt merge=tests_deploy_file >> .gitattributes
    echo .gitattributes >> .gitignore
    git config --global merge.tests_deploy_file.driver true
}

rollbackGitConfig() {
    git config --global --unset merge.tests_deploy_file.driver "true"
    rm .gitattributes >/dev/null
    git checkout HEAD .gitignore >/dev/null 2>/dev/null
}

getWorkingBranch
confirm
backpromote
echo "$(tput setaf 2)Complete."