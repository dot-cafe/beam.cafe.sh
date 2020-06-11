#!/bin/bash
set -e

# Update git repo and build
cd ~/beam.cafe.backend
git fetch --all
git reset --hard origin/master

# Remove dist directory
rm -rf dist

# Build backend
npm install
npm run build

# Restart api
pm2 restart beam.cafe.backend
