#!/bin/bash
set -e

# See: https://gist.github.com/domenic/ec8b0fc8ab45f39403dd

SOURCE_BRANCH="master"
TARGET_BRANCH="gh-pages"
TARGET_FOLDER="build"

REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

function prepareDocs {
  make all
}

# We only deploy when master changes
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "Skipping deploy; just doing a build."
    prepareDocs
    exit 0
fi

echo "Delete folder, in case of bad artifacts left over"
rm -rf $TARGET_FOLDER

echo "Cloning Repo"
# Clone the existing gh-pages for this repo into the api doc folder
git clone $REPO $TARGET_FOLDER
cd $TARGET_FOLDER

echo "Checking out $TARGET_BRANCH"
git checkout $TARGET_BRANCH
ls
cd ..
ls

echo "Cleaning out repo from old artifacts"
# Clean out existing contents
rm -rf ${TARGET_FOLDER}/**/* || exit 0

# Run our compile script
echo "Preparing API Docs"
prepareDocs

# ----- TIME TO ACTUALLY DO WORK TBH ------
cd $TARGET_FOLDER
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# Commit the "changes", i.e. the new version.
# The delta will show diffs between new and old versions.
git add -A .
git commit -m "Deploy to GitHub Pages: ${SHA}"

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in ../deploy_key.enc -out ../deploy_key -d
chmod 600 ../deploy_key
eval `ssh-agent -s`
ssh-add ../deploy_key

# Now that we're all set up, we can push.
git push $SSH_REPO $TARGET_BRANCH
