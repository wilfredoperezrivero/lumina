#!/bin/bash

# Lumina Admin - Deployment Script
# This script compiles Flutter web for production deployment

echo "🚀 Starting Lumina Admin Production Build..."
echo "📱 Compiling Flutter Web for Production..."
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    echo "Please install Flutter first: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check if we're in the correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root directory."
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Build for web production
echo "🏗️  Building Flutter web for production..."
echo "⚡ This may take a few minutes..."
echo ""

# Build the web project
flutter build web --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build completed successfully!"
    echo ""
    echo "📁 Build output location: build/web/"
    echo "📊 Build size:"
    du -sh build/web/
    echo ""
    echo "🌐 To serve the built files locally for testing:"
    echo "   cd build/web && python3 -m http.server 8000"
    echo "   Then visit: http://localhost:8000"
    echo ""
    echo "🚀 Ready for deployment!"
    echo "   Upload the contents of build/web/ to your web server"
else
    echo ""
    echo "❌ Build failed! Please check the error messages above."
    exit 1
fi 