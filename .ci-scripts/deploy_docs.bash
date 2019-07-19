#!/bin/bash
set -ex

echo "Installing MkDocs, Pony theme and PyYAML..."
pip install mkdocs-ponylang pyyaml

echo "Fixing docs..."
pushd ..
make docs-online
popd

echo "Uploading docs using MkDocs..."
git remote add gh-token "https://${GITHUB_TOKEN}@github.com/epiceric/pony-mqtt-docs"
git fetch gh-token
git reset gh-token/master
pushd ../mqtt-docs
mkdocs gh-deploy -v --clean --remote-name gh-token --remote-branch master
popd
