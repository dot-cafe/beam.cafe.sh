#!/bin/bash
set -e

# Update git repo and build
cd ~/beam.cafe.backend
git fetch --all
git reset --hard origin/master
npm install
npm run build

# Move templates to dist
rsync -r html/ dist/html

# Restart api
pm2 restart beam.cafe.backend
