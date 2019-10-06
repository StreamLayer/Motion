#!/bin/bash

ARTIFACT="Motion.framework.zip"
UPSTREAM="git@github.com:CosmicMind/Motion.git"

### Cleanup, build, archive
rm -rf ./Carthage/ ./DerivedData
carthage build --no-skip-current
zip -r $ARTIFACT ./Carthage/Build

### Generate release number
# Release number consist of the latest release version of the upstream repo
# suffixed with 'slr' suffix and amount of commits to be unique
COMMITS_NUMBER=$(git rev-list --count HEAD)
# 'hub' uses upstream remote by default, for some reason:
# https://hub.github.com/hub.1.html
git remote add upstream $UPSTREAM || true

RELEASE=$(hub release -L 1 | xargs -I % sh -c "echo %'-slr.'$COMMITS_NUMBER")

### Create release and upload
# Remove upstream to make 'hub' upload to 'origin' repo rather than default 'upstream'
git remote remove upstream
hub release create -a $ARTIFACT -m $RELEASE $RELEASE

# Delete artifact from local storage
rm $ARTIFACT

