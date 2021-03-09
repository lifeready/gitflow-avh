#!/bin/bash

set -x -e

editor="nano"
file="log.txt"
commit_log="commits.txt"
commit_index=0

function wait_for_key() {
    read -p "Press enter to continue"
}

function commit() {
    local t=$1
    local label=$2
    local work_file="${3:-$file}"

    local entry="${commit_index}: ${t}: ${label}"

    echo $entry >> $work_file
    git add $work_file
    git commit $work_file -m "Updated ${work_file} at ${t} from ${label}"

    echo $entry >> $commit_log

    let "commit_index+=1" 
}

function resolve()
{
    sed -i '/^<<<<<<<.*$/d' log.txt
    sed -i '/^=======.*$/d' log.txt
    sed -i '/^>>>>>>>.*$/d' log.txt
    # nano $file
    git add $file
}

function resolve_and_commit() {
    resolve
    git commit -m "Resolved conflict."
}

function merge_and_resolve()
{
    local base=$1
    set +e
    git merge $base
    # git rebase $base
    set -e
    # wait_for_key
    resolve_and_commit
    # git rebase --continue
}


function initialise() {
    rm -rf .git
    git init
    cat <<EOF > .gitignore
test.sh
commits.txt
EOF
    git add .gitignore
    git commit -m "Initial commit"
    rm -f $file
    rm -f $commit_log
    git flow init --defaults

    # for branch in bugfix feature
    # do
    #     git config gitflow.${branch}.finish.rebase yes
    # done
}

## ==== ==== ==== ====
initialise

## ==== ==== ==== ====
t="t-0"

branch="develop"
git checkout $branch
git flow bugfix start "BF1"

## ==== ==== ==== ====
t="t-1"

branch="develop"
git checkout $branch
git flow feature start "F1"

branch="develop"
git checkout $branch
commit $t $branch

branch="bugfix/BF1"
git checkout $branch
git merge "develop"
commit $t $branch

branch="master"
git checkout $branch
git flow hotfix start "HF1"

## ==== ==== ==== ====
t="t-2"

branch="feature/F1"
git checkout $branch
git merge "develop"
commit $t $branch

branch="develop"
git checkout $branch
git flow feature start "F2"

branch="bugfix/BF1"
git checkout $branch
git flow bugfix finish

branch="hotfix/HF1"
git checkout $branch
commit $t $branch

## ==== ==== ==== ====
t="t-3"

branch="feature/F2"
git checkout $branch
git merge "develop"
commit $t $branch

branch="develop"
git checkout $branch
commit $t $branch

branch="hotfix/HF1"
git checkout $branch
set +e
git flow hotfix finish --tagname "1.0.1" --message "Work item $branch completed."
set -e
resolve_and_commit
git flow hotfix finish "HF1" --tagname "1.0.1" --message "Work item $branch completed."

## ==== ==== ==== ====
t="t-4"

branch="feature/F2"
git checkout $branch
merge_and_resolve "develop"
git flow feature finish

## ==== ==== ==== ====
t="t-5"

branch="develop"
git checkout $branch
git flow release start "R1"

## ==== ==== ==== ====
t="t-6"

branch="release/R1"
git checkout $branch
git flow bugfix start "BF2" $branch

## ==== ==== ==== ====
t="t-7"

branch="bugfix/BF2"
git checkout $branch
commit $t $branch

## <DF> Optional divergence of master prior to finishing release/R1
branch="master"
git checkout $branch
commit $t $branch "${branch}.txt"
## </DF>


## ==== ==== ==== ====
t="t-8"

branch="bugfix/BF2"
git checkout $branch
git flow bugfix finish

## ==== ==== ==== ====
t="t-9"

branch="release/R1"
git checkout $branch
## <DF> Required merge of master prior to finishing release
git merge "master"
## </DF>
git flow release finish --tagname "1.1.0" --message "Work item $branch completed."

## ==== ==== ==== ====
t="t-10"

branch="develop"
git checkout $branch
git flow feature start "F3"

## ==== ==== ==== ====
t="t-11"

branch="feature/F3"
git checkout $branch
git merge "develop"
commit $t $branch

## ==== ==== ==== ====
t="t-12"

branch="feature/F1"
git checkout $branch
merge_and_resolve "develop"
git flow feature finish

branch="feature/F3"
git checkout $branch
git flow feature finish

## ==== ==== ==== ====
t="t-13"

branch="develop"
git checkout $branch
git flow release start R2

## ==== ==== ==== ====
t="t-14"

branch="release/R2"
git checkout $branch
git flow release finish --tagname "1.2.0" --message "Work item $branch completed."

## ==== ==== ==== ====
t="t-15"

branch="develop"
git checkout $branch
commit $t $branch

## ==== ==== ==== ====
t="t-16"

branch="develop"
git checkout $branch
git flow release start R3

## ==== ==== ==== ====
t="t-17"

branch="release/R3"
git checkout $branch
git flow bugfix start "BF3" $branch

## ==== ==== ==== ====
t="t-18"

branch="bugfix/BF3"
git checkout $branch
commit $t $branch

branch="master"
git checkout $branch
git flow hotfix start "HF2"

## ==== ==== ==== ====
t="t-19"

branch="hotfix/HF2"
git checkout $branch
commit $t $branch

## ==== ==== ==== ====
t="t-20"

branch="hotfix/HF2"
git checkout $branch
set +e
git flow hotfix finish --tagname "1.2.1" --message "Work item $branch completed."
set -e
resolve_and_commit
git flow hotfix finish "HF2" --tagname "1.2.1" --message "Work item $branch completed."

## ==== ==== ==== ====
t="t-22"

branch="bugfix/BF3"
git checkout $branch
git flow bugfix finish

## ==== ==== ==== ====
t="t-23"

branch="release/R3"
git checkout $branch
merge_and_resolve "master"
set +e
git flow release finish --tagname "1.3.0" --message "Work item $branch completed."
set -e
resolve_and_commit
git flow release finish "R3" --tagname "1.3.0" --message "Work item $branch completed."