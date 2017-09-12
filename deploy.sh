#!/bin/bash

set -o errexit -o nounset

if [ -z "${TRAVIS_BRANCH:-}" ]; then
    echo "This script may only be run from Travis!"
    exit 1
fi

if [ "$TRAVIS_PULL_REQUEST" == false ]; then
    BRANCH=$TRAVIS_BRANCH
else
    BRANCH=$TRAVIS_PULL_REQUEST_BRANCH
fi

if [ "$BRANCH" != "master" ]; then
    echo "This commit was made against '$BRANCH' and not master! No deploy!"
    exit 0
fi

# Returns 1 if program is installed and 0 otherwise
program_installed() {
    local return_=1

    type $1 >/dev/null 2>&1 || { local return_=0; }

    echo "$return_"
}

# Ensure required programs are installed
if [ $(program_installed git) == 0 ]; then
    echo "Please install Git."
    exit 1
fi

REV=$(git rev-parse --short HEAD)
cd target/doc

# Hide documentation of unimportant dependencies
for crate in dtoa itoa num_traits quote serde_docs syn synom unicode_xid; do
    sed -i '/^searchIndex\["'$crate'"\]/s|^|//|' search-index.js
done

echo "Committing docs to gh-pages branch"
git init
git remote add upstream "https://$GH_TOKEN@github.com/serde-rs/docs"
git config user.name "Serde Docs"
git config user.email "docs@serde.rs"
git add -A .
git commit -qm "Documentation for ${TRAVIS_REPO_SLUG}@${REV}"

echo "Pushing gh-pages to GitHub"
git push -q upstream HEAD:refs/heads/gh-pages --force
