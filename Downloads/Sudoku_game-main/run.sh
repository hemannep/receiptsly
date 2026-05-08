#!/bin/bash
echo "Building APK..."
cd android && ./gradlew assembleDebug && cd ..
echo "Installing..."
adb install -r android/app/build/outputs/flutter-apk/app-debug.apk
echo "Launching..."
adb shell am start -n com.example.sudokugame/.MainActivity
