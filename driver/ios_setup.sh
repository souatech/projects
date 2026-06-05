#!/bin/bash

echo "🚀 JOXMAKO iOS Setup Starting..."

# Stop on error
set -e

echo "🧹 Flutter clean..."
flutter clean

echo "📦 Flutter pub get..."
flutter pub get

echo "📱 Entering ios directory..."
cd ios

echo "🗑 Removing old Pods..."
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks

echo "🧼 Deintegrating CocoaPods..."
pod deintegrate

echo "🔄 Updating CocoaPods repo..."
pod repo update

echo "📥 Installing Pods..."
pod install

echo "⬅️ Returning to project root..."
cd ..

echo "📂 Opening Xcode workspace..."
open ios/Runner.xcworkspace

echo "✅ JOXMAKO iOS setup completed!"
