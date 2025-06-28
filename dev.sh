#!/bin/bash

# Lumina Admin - Development Script
# This script runs Flutter web for development

echo "🚀 Starting Lumina Admin Development Server..."
echo "📱 Running Flutter Web..."
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

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Run Flutter web
echo "🌐 Starting Flutter web server..."
echo "📍 The app will be available at: http://localhost:3000"
echo "🛑 Press Ctrl+C to stop the server"
echo ""

flutter run -d chrome --web-port 3000 