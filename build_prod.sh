#!/bin/bash
echo "Building Android App Bundle & iOS IPA with Obfuscation..."
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols
flutter build ipa --obfuscate --split-debug-info=build/ios/outputs/symbols
echo "Build complete."
