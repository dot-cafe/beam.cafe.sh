#!/bin/bash
set -e

# Update git repo and build
cd ~/beam.cafe
git fetch origin --tags --force
git reset --hard origin/master
npm install
npm run build

# Clean serve directory and copy fresh frontend
cd ~
rm -rf beam.cafe.www/*
mv -v beam.cafe/dist/* beam.cafe.www/
