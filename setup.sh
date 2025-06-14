#!/bin/bash
echo "🚀 Starting smart full-stack setup..."

BUILD_DIR="dist"
TARGET_BRANCH="gh-pages"

if [ -f "package.json" ]; then
  echo "📦 Node project detected. Installing dependencies..."
  npm install || { echo "❌ npm install failed."; exit 1; }

  if [ -f "vite.config.js" ] || grep -q vite package.json; then
    echo "⚡ Vite detected."
    if ! npx --no vite &>/dev/null; then
      echo "📥 Installing Vite..."
      npm install --save-dev vite
    fi
    if ! grep -q '"build"' package.json; then
      echo "🔧 Adding Vite build script to package.json..."
      npx npm-add-script -k "build" -v "vite build"
    fi
    [ ! -f vite.config.js ] && echo 'export default { root: ".", build: { outDir: "dist" } }' > vite.config.js
    echo "🏗️ Building with Vite..."
    npm run build || { echo "❌ Vite build failed."; exit 1; }

  elif grep -q parcel package.json; then
    echo "🎁 Parcel detected."
    if ! npx --no parcel &>/dev/null; then
      echo "📥 Installing Parcel..."
      npm install --save-dev parcel
    fi
    if ! grep -q '"build"' package.json; then
      echo "🔧 Adding Parcel build script to package.json..."
      npx npm-add-script -k "build" -v "parcel build index.html"
    fi
    echo "🏗️ Building with Parcel..."
    npm run build || { echo "❌ Parcel build failed."; exit 1; }

  else
    echo "⚠️ Unknown build tool. Please add a build script to package.json."
    exit 1
  fi

else
  echo "🧾 No package.json — assuming static site."
  BUILD_DIR="."
fi

if git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "🚀 Preparing deployment to GitHub Pages..."
  DEPLOY_DIR=$(mktemp -d)
  cp -r $BUILD_DIR/* $DEPLOY_DIR/
  git checkout --orphan $TARGET_BRANCH
  git rm -rf .
  cp -r $DEPLOY_DIR/* .
  rm -rf $DEPLOY_DIR
  touch .nojekyll
  git add .
  git commit -m "🚀 Deploy to GitHub Pages"
  git push origin $TARGET_BRANCH --force
  echo "✅ Deployed to https://bengothard.github.io/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git//')/"
else
  echo "⚠️ Not a Git repo. Please git init and add origin."
  echo "   git init && git remote add origin <repo-url>"
fi

echo "🎉 Setup complete!"
