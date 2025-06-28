#!/bin/bash

# Lumina Admin - Deployment Script
# This script deploys the built web project to Cloudflare Pages using Wrangler

# npm install -g wrangler
# wrangler login
#

./build.sh

echo "🚀 Deploying to Cloudflare Pages..."
wrangler pages deploy build/web --project-name lumina-admin 