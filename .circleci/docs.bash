#!/bin/bash

install-deps(){
  echo "Installing MkDocs, Pony theme and PyYAML..."
  sudo -H pip install mkdocs-ponylang pyyaml
}

build-docs(){
  echo "Building docs..."
  make docs-online
}

deploy-docs(){
  echo "Uploading docs using MkDocs..."
  git remote add gh-token "https://${GITHUB_TOKEN}@github.com/epiceric/pony-mqtt.github.io"
  git fetch gh-token
  git reset gh-token/master
  pushd mqtt-docs
  mkdocs gh-deploy -v --clean --remote-name gh-token --remote-branch master
  popd
}

install-deps
build-docs
deploy-docs
